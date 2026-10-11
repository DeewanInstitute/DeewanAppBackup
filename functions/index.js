const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret, defineString} = require("firebase-functions/params");
const admin = require("firebase-admin");
const OpenAI = require("openai");
const nodemailer = require("nodemailer");
const crypto = require("crypto");
const {questions: seedQuizQuestions} = require("./seed_quizzes.js");

admin.initializeApp();

const openaiApiKey = defineSecret("OPENAI_API_KEY");
const gmailUser = defineSecret("GMAIL_USER");
const gmailAppPassword = defineSecret("GMAIL_APP_PASSWORD");
const elevenLabsApiKey = defineSecret("ELEVENLABS_API_KEY");
// Comma-separated Firebase Auth UIDs allowed to run admin maintenance tasks
// (find yours under Firebase Console -> Authentication -> Users -> User UID).
const adminUids = defineString("ADMIN_UIDS");
// ElevenLabs voice ID (not a secret) of a Levantine-accented voice from the Voice Library.
const elevenLabsLevantineVoice = defineString("ELEVENLABS_VOICE_LEVANTINE");

const SENTENCE_SCHEMA = {
  type: "object",
  properties: {
    arabic: {type: "string"},
    transliteration: {type: "string"},
    english: {type: "string"},
  },
  required: ["arabic", "transliteration", "english"],
  additionalProperties: false,
};

// { arabic, transliteration } only — used for conjugation forms (no gloss needed).
const CONJUGATION_FORM_SCHEMA = {
  type: "object",
  properties: {
    arabic: {type: "string"},
    transliteration: {type: "string"},
  },
  required: ["arabic", "transliteration"],
  additionalProperties: false,
};

// { arabic, transliteration, english } — used for verb/masdar/participle/nominal-form entries.
const MORPH_FORM_SCHEMA = {
  type: "object",
  properties: {
    arabic: {type: "string"},
    transliteration: {type: "string"},
    english: {type: "string"},
  },
  required: ["arabic", "transliteration", "english"],
  additionalProperties: false,
};

const CONJUGATIONS_SCHEMA = {
  type: "object",
  properties: {
    past: CONJUGATION_FORM_SCHEMA,
    present: CONJUGATION_FORM_SCHEMA,
    imperative: CONJUGATION_FORM_SCHEMA,
  },
  required: ["past", "present", "imperative"],
  additionalProperties: false,
};

// Levantine sometimes uses a genuinely different verb/root for the same
// meaning (e.g. "sit" = Fusha جلس vs Levantine قعد) — nullable because not
// every root has a confidently-known Levantine equivalent. Levantine gets
// its own masdar/active_participle since those forms differ from Fusha too,
// not just the conjugations.
const LEVANTINE_ROOT_FAMILY_SCHEMA = {
  type: ["object", "null"],
  properties: {
    root: {type: "string"},
    different_root_than_fusha: {type: "boolean"},
    note: {type: ["string", "null"]},
    verb: MORPH_FORM_SCHEMA,
    conjugations: CONJUGATIONS_SCHEMA,
    masdar: {...MORPH_FORM_SCHEMA, type: ["object", "null"]},
    active_participle: {...MORPH_FORM_SCHEMA, type: ["object", "null"]},
  },
  required: ["root", "different_root_than_fusha", "note", "verb", "conjugations", "masdar", "active_participle"],
  additionalProperties: false,
};

// Only populated when `type` is "verb" — root, conjugations, masdar,
// participles. Nullable sub-fields (passive_participle, nominal_forms,
// levantine) must be explicitly null rather than guessed when uncertain or
// not applicable (e.g. no natural passive participle for an intransitive verb).
const ROOT_FAMILY_SCHEMA = {
  type: ["object", "null"],
  properties: {
    root: {type: "string"},
    verb: MORPH_FORM_SCHEMA,
    conjugations: CONJUGATIONS_SCHEMA,
    masdar: MORPH_FORM_SCHEMA,
    active_participle: MORPH_FORM_SCHEMA,
    passive_participle: {...MORPH_FORM_SCHEMA, type: ["object", "null"]},
    nominal_forms: {type: ["array", "null"], items: MORPH_FORM_SCHEMA},
    irregular_imperative: {type: "boolean"},
    levantine: LEVANTINE_ROOT_FAMILY_SCHEMA,
  },
  required: [
    "root",
    "verb",
    "conjugations",
    "masdar",
    "active_participle",
    "passive_participle",
    "nominal_forms",
    "irregular_imperative",
    "levantine",
  ],
  additionalProperties: false,
};

const WORD_SCHEMA = {
  type: "object",
  properties: {
    english: {type: "string"},
    arabic: {type: "string"},
    arabic_levantine: {type: "string"},
    transliteration: {type: "string"},
    transliteration_levantine: {type: "string"},
    type: {type: "string"},
    synonyms: {type: "array", items: {type: "string"}},
    antonyms: {type: "array", items: {type: "string"}},
    fusha_sentences: {type: "array", items: SENTENCE_SCHEMA, minItems: 2, maxItems: 2},
    levantine_sentences: {type: "array", items: SENTENCE_SCHEMA, minItems: 2, maxItems: 2},
    root_family: ROOT_FAMILY_SCHEMA,
  },
  required: [
    "english",
    "arabic",
    "arabic_levantine",
    "transliteration",
    "transliteration_levantine",
    "type",
    "synonyms",
    "antonyms",
    "fusha_sentences",
    "levantine_sentences",
    "root_family",
  ],
  additionalProperties: false,
};

const SYSTEM_PROMPT =
  "You are a precise Arabic-English lexicographer building entries for an Arabic-learning app. " +
  "Given an English word or short phrase, produce a dictionary entry with Modern Standard Arabic (Fusha) " +
  "and colloquial Jordanian Arabic (Ammiyeh) forms. The colloquial fields must be ONLY the Jordanian " +
  "dialect specifically — not a blended or generic \"Levantine\", and not Palestinian, Syrian, or Lebanese " +
  "usage where it differs from Jordanian. Use minimal diacritics on headwords, matching typical " +
  "learner-dictionary style (only mark vowels where genuinely needed to avoid ambiguity). Provide exactly " +
  "2 example sentences per dialect, natural and commonly used. Synonyms and antonyms should be single " +
  "Arabic words or short phrases in Fusha. The 'type' field should be a short lowercase part-of-speech " +
  "label such as 'noun', 'verb', 'adjective', or 'greeting'. If the word is a verb, give the Fusha " +
  "'arabic' field as the present-tense third-person masculine singular form (e.g. يكتب for 'write'), " +
  "matching how verbs are cited elsewhere in this dictionary.\n\n" +
  "ROOT FAMILY (verbs only): if and only if 'type' is \"verb\", also fill in 'root_family' with the " +
  "triliteral (or quadriliteral) root, the citation-form verb (Fusha, past 3rd-person-masc-singular, " +
  "fully voweled e.g. كَتَبَ), full conjugations (past/present/imperative, each fully voweled), the masdar " +
  "(verbal noun), active participle (اسم الفاعل), and passive participle (اسم المفعول). Be conservative: " +
  "set 'passive_participle' to null if the verb is intransitive and has no natural passive participle in " +
  "everyday use (e.g. 'to sit', 'to go'), rather than inventing one. Set 'nominal_forms' to null unless you " +
  "are genuinely confident about 1-3 common nouns sharing the same root (e.g. كتب/kataba -> كتاب 'book', " +
  "مكتب 'desk/office', مكتبة 'library'). Set 'irregular_imperative' to true for verbs with a well-known " +
  "irregular imperative (e.g. أكل/akala -> imperative كُلْ 'kul', not the regular pattern; أخذ/akhadha -> خُذْ 'khudh'). " +
  "For 'levantine' inside root_family: this MUST be the Jordanian conjugation specifically, following " +
  "every rule below.\n\n" +
  "JORDANIAN DIFFERENT-ROOT RULE: Jordanian colloquial sometimes uses a completely different verb/root " +
  "for the same meaning, not just a different pronunciation of the same root. Examples: Fusha ذهب/dhahaba " +
  "('to go') -> Jordanian راح/raah (root ر و ح, NOT ذ ه ب). Fusha جلس/jalasa ('to sit') -> Jordanian " +
  "قعد/qa'ad (root ق ع د, NOT ج ل س). Fusha رأى/ra'aa ('to see') -> Jordanian شاف/shaaf (root ش و ف, NOT " +
  "ر أ ي). When this happens, set 'different_root_than_fusha' to true and explain it in 'note'. When the " +
  "Jordanian verb shares the Fusha root (just a colloquial pronunciation/conjugation difference), set " +
  "'different_root_than_fusha' to false and 'note' to null.\n\n" +
  "JORDANIAN PRESENT-TENSE ب- RULE (HARD REQUIREMENT — check this before responding): " +
  "'levantine.conjugations.present.arabic' MUST start with the letter ب. This is not optional. Jordanians " +
  "do not say the bare present stem on its own for a simple indicative statement — they always prefix ب-. " +
  "Correct present-tense examples (all start with ب): بشوف/bshoof ('he sees', root شوف), " +
  "بيكتب/byiktib ('he writes', root كتب), بروح/biruh ('he goes', root روح), بقعد/bi'ud ('he sits', root " +
  "قعد), بعرف/ba'rif ('he knows', root عرف). INCORRECT (missing ب-, do not output these): يشوف, يكتب, " +
  "يروح, يقعد, يعرف. Before you finalize your answer, check the first character of " +
  "'levantine.conjugations.present.arabic' — if it is not ب, rewrite it so that it is. This ب- rule applies " +
  "only to 'present'; 'past' and 'imperative' stay as the plain colloquial forms without ب-.\n\n" +
  "Jordanian colloquial also gets its own 'masdar' (verbal noun) and 'active_participle' inside " +
  "'levantine', since these commonly differ from the Fusha forms in everyday speech (e.g. for 'to see': " +
  "Jordanian masdar شوفة/shoofeh, active participle شايف/shayef — distinct from the Fusha رؤية/ru'ya and " +
  "رائي/raa'in). Set these to null only if you are genuinely not confident, and set the whole 'levantine' " +
  "object to null only if you are not confident about the Jordanian root family at all — never guess.\n\n" +
  "SPELLING CARE FOR HOLLOW/WEAK/HAMZATED VERBS: verbs like 'to see' (رأى) are hollow, hamzated, and " +
  "weak-final all at once, and are among the most commonly misspelled Arabic verbs — including by fluent " +
  "speakers — so be exact. Fully worked reference example for 'to see':\n" +
  "  - Fusha headword ('arabic', present tense): يرى (yaraa) — the hamza is DROPPED in the present tense, " +
  "there is no أ in this form.\n" +
  "  - root_family.root: ر أ ي\n" +
  "  - root_family.verb (Fusha, past tense, fully voweled): رَأَى (ra'aa) — hamza on alif (أ) in the " +
  "middle, ending in alif maqsura (ى), NOT ي. Do not confuse this verb with the unrelated noun رَأْي " +
  "(ra'y, meaning 'opinion') — they look similar but are different words with a different final letter " +
  "and different vowel pattern.\n" +
  "  - conjugations.present: يَرَى (yaraa, hamza dropped, ends in ى not ي)\n" +
  "  - conjugations.imperative: رَ (ra) — yes, a single letter; this is a genuine, well-documented " +
  "irregularity, not an error. Set 'irregular_imperative' to true.\n" +
  "  - masdar: رُؤْيَة (ru'ya)\n" +
  "  - active_participle: رَائٍ (raa'in)\n" +
  "  - passive_participle: مَرْئِيّ (mar'iyy)\n" +
  "  - levantine.root: ش و ف (different root than Fusha — see the JORDANIAN DIFFERENT-ROOT RULE above)\n" +
  "  - levantine.conjugations.present: بشوف (bshoof, starts with ب per the rule above)\n" +
  "Apply this same level of care (correct hamza seat, alif maqsura ى vs yaa ي, checking for confusable " +
  "near-identical words) to every hollow, weak-final, or hamzated verb, not just this one example.\n\n" +
  "For non-verbs, set 'root_family' to null entirely.\n\n" +
  "Respond with only the JSON object, no commentary.";

// ── Verb review pass ──────────────────────────────────────────────────────────
// A second, stricter model pass over a generated root_family. Generation and
// checking are separate jobs: the generator is busy producing a whole entry,
// while the reviewer only has to verify forms one by one against a checklist.
const REVIEW_MODEL = "gpt-4o";
// Bump when REVIEW_PROMPT improves, so every verb is re-reviewed under the new rules.
const REVIEW_VERSION = 1;

const REVIEW_PROMPT =
  "You are a meticulous Arabic morphology reviewer. You will be given a 'root_family' JSON object that " +
  "another model generated for an English verb. Verify EVERY form in it, one by one, and return the full " +
  "object with any mistakes corrected. Change only what is actually wrong — do not rewrite correct forms " +
  "or restyle them. List each correction you make in 'changes' as a short plain sentence (e.g. \"Levantine " +
  "present was يُوكُل; corrected to بياكُل\"). If nothing was wrong, return the object unchanged and an " +
  "empty 'changes' array.\n\n" +
  "CHECKLIST — Fusha:\n" +
  "1. 'root' contains exactly the root letters of the verb, in order.\n" +
  "2. 'verb' is the past 3rd-person masculine singular, fully voweled and correctly spelled.\n" +
  "3. 'conjugations.past'/'present'/'imperative' are the 3ms past, 3ms present (indicative), and 2ms " +
  "imperative of THIS verb, fully voweled. The present stem vowel (يَفْعُلُ / يَفْعِلُ / يَفْعَلُ) must be the " +
  "real lexical one for this verb, not a guess from the pattern. The imperative must use the correct " +
  "hamzat al-wasl vowel (اُكْتُبْ vs اِذْهَبْ), and the irregular imperatives (كُلْ, خُذْ, مُرْ …) must be " +
  "marked via 'irregular_imperative'.\n" +
  "4. 'masdar' is the standard, most common verbal noun for this verb (not an obscure variant).\n" +
  "5. 'active_participle' follows فَاعِل with correct hamza/yaa handling for hollow, defective, and " +
  "hamzated verbs (e.g. قَائِل, رَامٍ, آكِل). 'passive_participle' is مَفْعُول-pattern or null when the verb " +
  "has no natural one.\n" +
  "6. Every 'transliteration' matches the vowels actually written in its Arabic, and every 'english' gloss " +
  "is accurate.\n\n" +
  "CHECKLIST — Jordanian (the 'levantine' object):\n" +
  "7. It must be genuinely Jordanian colloquial, not Fusha with the case endings dropped and not another " +
  "Levantine variety. Verify the root: if Jordanian uses a different verb for this meaning, " +
  "'different_root_than_fusha' is true with an explanatory 'note'.\n" +
  "8. 'conjugations.present.arabic' MUST start with ب. 'past' and 'imperative' must NOT.\n" +
  "9. Verify each form is a real thing a Jordanian says. Pay particular attention to verbs whose colloquial " +
  "stem is irregular (أكل → ياكُل not يُوكُل; أخذ → ياخُذ; جا/جاب; hollow verbs like شاف/قال/نام).\n" +
  "10. 'masdar' and 'active_participle' are the forms Jordanians actually use; null them only if you are " +
  "not confident, never invent one.\n\n" +
  "If you are not confident a form is correct and cannot fix it, prefer the safer option the generation " +
  "rules allow (null where nullable) over keeping a doubtful form.\n\n" +
  "These are the rules the generating model was given. The entry must satisfy all of them:\n\n";

const REVIEW_SCHEMA = {
  type: "object",
  properties: {
    root_family: ROOT_FAMILY_SCHEMA,
    changes: {type: "array", items: {type: "string"}},
  },
  required: ["root_family", "changes"],
  additionalProperties: false,
};

// Returns {rootFamily, changes, ok}. Never throws: if the review call fails, the
// original generated entry is kept (ok=false) rather than losing the lookup, and
// callers must not mark the entry as reviewed.
async function reviewRootFamily(client, englishWord, rootFamily) {
  try {
    const completion = await client.chat.completions.create({
      model: REVIEW_MODEL,
      messages: [
        {role: "system", content: REVIEW_PROMPT + SYSTEM_PROMPT},
        {role: "user", content: `English verb: "${englishWord}"\n\nroot_family to review:\n${JSON.stringify(rootFamily)}`},
      ],
      response_format: {
        type: "json_schema",
        json_schema: {name: "root_family_review", schema: REVIEW_SCHEMA, strict: true},
      },
    });
    const result = JSON.parse(completion.choices[0].message.content);
    if (!result.root_family) return {rootFamily, changes: [], ok: false};
    return {rootFamily: result.root_family, changes: result.changes || [], ok: true};
  } catch (e) {
    console.error(`Verb review failed for "${englishWord}":`, e.message);
    return {rootFamily, changes: [], ok: false};
  }
}

function wordKeyOf(english) {
  return english.toLowerCase().trim().replace(/\s+/g, "_");
}

exports.lookupWord = onCall({secrets: [openaiApiKey], cors: true}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be signed in to look up new words.");
  }

  const englishWord = (request.data && request.data.word ? String(request.data.word) : "").trim().toLowerCase();
  if (!englishWord || englishWord.length > 60) {
    throw new HttpsError("invalid-argument", "Please provide a single valid English word or short phrase.");
  }

  const db = admin.firestore();
  const docRef = db.collection("dictionary").doc(wordKeyOf(englishWord));

  // Someone may have already looked this up — avoid a duplicate paid API call.
  const existing = await docRef.get();
  if (existing.exists) {
    return existing.data();
  }

  const client = new OpenAI({apiKey: openaiApiKey.value()});

  let completion;
  try {
    completion = await client.chat.completions.create({
      model: "gpt-4o",
      messages: [
        {role: "system", content: SYSTEM_PROMPT},
        {role: "user", content: `English word: "${englishWord}"`},
      ],
      response_format: {
        type: "json_schema",
        json_schema: {name: "dictionary_entry", schema: WORD_SCHEMA, strict: true},
      },
    });
  } catch (e) {
    throw new HttpsError("internal", `OpenAI request failed: ${e.message}`);
  }

  let entry;
  try {
    entry = JSON.parse(completion.choices[0].message.content);
  } catch (e) {
    throw new HttpsError("internal", "Received an unexpected response format from the model.");
  }

  if (entry.root_family) {
    const reviewed = await reviewRootFamily(client, englishWord, entry.root_family);
    entry.root_family = reviewed.rootFamily;
    if (reviewed.ok) {
      entry.verbReviewVersion = REVIEW_VERSION;
      entry.verbReviewChanges = reviewed.changes;
    }
  }

  entry.english = englishWord;
  entry.source = "openai";
  entry.model = "gpt-4o";
  entry.generatedAt = admin.firestore.FieldValue.serverTimestamp();

  await docRef.set(entry);

  return entry;
});

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function escapeHtml(str) {
  return str
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
}

function buildContactEmail({name, email, message, submittedAt}) {
  const text = `New Contact Form Submission — LinguArabi\n\n` +
    `Name: ${name}\n` +
    `Email: ${email}\n` +
    `Submitted: ${submittedAt}\n\n` +
    `Message:\n${message}\n`;

  const safeName = escapeHtml(name);
  const safeEmail = escapeHtml(email);
  const safeMessage = escapeHtml(message);

  const html = `
    <div style="font-family: Arial, Helvetica, sans-serif; max-width: 560px; margin: 0 auto; color: #1F1E28;">
      <div style="background-color: #5DCBA9; padding: 24px; border-radius: 12px 12px 0 0; text-align: center;">
        <h1 style="color: #ffffff; margin: 0; font-size: 22px;">LinguArabi</h1>
        <p style="color: #ffffff; margin: 4px 0 0; font-size: 13px; opacity: 0.9;">New Contact Form Submission</p>
      </div>
      <div style="background-color: #ffffff; border: 1px solid #E0D5C5; border-top: none; border-radius: 0 0 12px 12px; padding: 24px;">
        <table style="width: 100%; border-collapse: collapse; margin-bottom: 20px;">
          <tr>
            <td style="padding: 6px 0; color: #8F8C88; font-size: 13px; width: 90px;">From</td>
            <td style="padding: 6px 0; font-size: 14px; font-weight: 600;">${safeName}</td>
          </tr>
          <tr>
            <td style="padding: 6px 0; color: #8F8C88; font-size: 13px;">Email</td>
            <td style="padding: 6px 0; font-size: 14px; font-weight: 600;">
              <a href="mailto:${safeEmail}" style="color: #5DCBA9; text-decoration: none;">${safeEmail}</a>
            </td>
          </tr>
          <tr>
            <td style="padding: 6px 0; color: #8F8C88; font-size: 13px;">Submitted</td>
            <td style="padding: 6px 0; font-size: 14px;">${submittedAt}</td>
          </tr>
        </table>
        <div style="border-top: 1px solid #E0D5C5; padding-top: 16px;">
          <p style="color: #8F8C88; font-size: 12px; text-transform: uppercase; letter-spacing: 0.5px; margin: 0 0 8px;">Message</p>
          <p style="font-size: 14px; line-height: 1.6; white-space: pre-wrap; margin: 0;">${safeMessage}</p>
        </div>
      </div>
      <p style="text-align: center; color: #8F8C88; font-size: 11px; margin-top: 16px;">
        Sent from the LinguArabi Contact Us page &middot; Reply directly to respond to ${safeName}.
      </p>
    </div>
  `;

  return {text, html};
}

exports.sendContactMessage = onCall({secrets: [gmailUser, gmailAppPassword], cors: true}, async (request) => {
  const name = (request.data && request.data.name ? String(request.data.name) : "").trim();
  const email = (request.data && request.data.email ? String(request.data.email) : "").trim();
  const message = (request.data && request.data.message ? String(request.data.message) : "").trim();

  if (!name || name.length > 100) {
    throw new HttpsError("invalid-argument", "Please provide your name.");
  }
  if (!email || !EMAIL_PATTERN.test(email) || email.length > 200) {
    throw new HttpsError("invalid-argument", "Please provide a valid email address.");
  }
  if (!message || message.length > 2000) {
    throw new HttpsError("invalid-argument", "Please provide a message (up to 2000 characters).");
  }

  const transporter = nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: gmailUser.value(),
      pass: gmailAppPassword.value(),
    },
  });

  const submittedAt = new Date().toLocaleString("en-US", {dateStyle: "medium", timeStyle: "short", timeZone: "UTC"});
  const {text, html} = buildContactEmail({name, email, message, submittedAt: `${submittedAt} UTC`});

  try {
    await transporter.sendMail({
      from: `"LinguArabi Contact Form" <${gmailUser.value()}>`,
      to: [gmailUser.value(), "app@deewaninstitute.com"],
      replyTo: email,
      subject: `LinguArabi Support Request from ${name}`,
      text,
      html,
    });
  } catch (e) {
    throw new HttpsError("internal", `Failed to send email: ${e.message}`);
  }

  return {success: true};
});

// Fusha is spoken by OpenAI TTS; Levantine by an ElevenLabs voice, because
// choosing a genuinely Levantine voice beats describing an accent in a prompt.
const SPEECH_MODEL = "gpt-4o-mini-tts";
const SPEECH_VOICE = "coral";
// Newest first. The first one that ElevenLabs reports as text-to-speech capable
// for this account is used; the last entry is the guaranteed fallback.
const ELEVENLABS_MODELS = ["eleven_v4", "eleven_multilingual_v2"];
const ELEVENLABS_FALLBACK_MODEL = "eleven_multilingual_v2";
// Bump this whenever the instructions or voice settings change, so previously
// cached clips are regenerated instead of served stale.
const SPEECH_VERSION = "v1";

const FUSHA_INSTRUCTIONS = "Speak in Modern Standard Arabic (Fusha) with clear, careful pronunciation, " +
  "at a slightly slow, even pace suited to a language learner. Pronounce every short vowel as written.";

function speechBucket() {
  const name = (admin.app().options && admin.app().options.storageBucket) ||
    `${process.env.GCLOUD_PROJECT}.firebasestorage.app`;
  return admin.storage().bucket(name);
}

function storageDownloadUrl(bucketName, path, token) {
  return `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/${encodeURIComponent(path)}` +
    `?alt=media&token=${token}`;
}

async function synthesizeWithOpenAI(text) {
  const client = new OpenAI({apiKey: openaiApiKey.value()});
  const response = await client.audio.speech.create({
    model: SPEECH_MODEL,
    voice: SPEECH_VOICE,
    input: text,
    instructions: FUSHA_INSTRUCTIONS,
    response_format: "mp3",
  });
  return Buffer.from(await response.arrayBuffer());
}

let elevenLabsModelPromise = null;

// Asks ElevenLabs which models can do text-to-speech (as their docs recommend)
// instead of assuming a model name works. Cached per function instance; a
// failed lookup isn't cached so it can be retried on the next request.
async function resolveElevenLabsModel() {
  if (!elevenLabsModelPromise) {
    elevenLabsModelPromise = (async () => {
      const response = await fetch("https://api.elevenlabs.io/v1/models", {
        headers: {"xi-api-key": elevenLabsApiKey.value()},
      });
      if (!response.ok) throw new Error(`models lookup ${response.status}`);
      const models = await response.json();
      const usable = new Set(models.filter((m) => m.can_do_text_to_speech).map((m) => m.model_id));
      const chosen = ELEVENLABS_MODELS.find((id) => usable.has(id)) || ELEVENLABS_FALLBACK_MODEL;
      console.log(`ElevenLabs model selected: ${chosen}`);
      return chosen;
    })().catch((e) => {
      console.error("ElevenLabs model lookup failed, using fallback:", e.message);
      elevenLabsModelPromise = null;
      return ELEVENLABS_FALLBACK_MODEL;
    });
  }
  return elevenLabsModelPromise;
}

async function synthesizeWithElevenLabs(text, voiceId, model) {
  const body = {text, model_id: model};
  // Fixed voice settings are only known-good for Multilingual v2; newer models
  // use the voice's own stored settings rather than risk a rejected request.
  if (model === ELEVENLABS_FALLBACK_MODEL) {
    body.voice_settings = {stability: 0.6, similarity_boost: 0.8};
  }
  const response = await fetch(
      `https://api.elevenlabs.io/v1/text-to-speech/${encodeURIComponent(voiceId)}?output_format=mp3_44100_128`,
      {
        method: "POST",
        headers: {
          "xi-api-key": elevenLabsApiKey.value(),
          "Content-Type": "application/json",
          "Accept": "audio/mpeg",
        },
        body: JSON.stringify(body),
      },
  );
  if (!response.ok) {
    const detail = await response.text().catch(() => "");
    const error = new Error(`ElevenLabs ${response.status} (${model}): ${detail.slice(0, 200)}`);
    // Bad request / unknown model / unprocessable settings are worth retrying on
    // the older model; auth, quota and rate-limit errors would fail there too.
    error.retryable = [400, 404, 422].includes(response.status);
    throw error;
  }
  return Buffer.from(await response.arrayBuffer());
}

async function synthesizeLevantine(text, voiceId, model) {
  try {
    return await synthesizeWithElevenLabs(text, voiceId, model);
  } catch (e) {
    if (model !== ELEVENLABS_FALLBACK_MODEL && e.retryable) {
      console.warn(`${e.message} — retrying with ${ELEVENLABS_FALLBACK_MODEL}`);
      return synthesizeWithElevenLabs(text, voiceId, ELEVENLABS_FALLBACK_MODEL);
    }
    throw e;
  }
}

exports.generateSpeech = onCall(
    {secrets: [openaiApiKey, elevenLabsApiKey], cors: true, timeoutSeconds: 60},
    async (request) => {
      if (!request.auth) {
        throw new HttpsError("unauthenticated", "You must be signed in to hear pronunciations.");
      }

      const text = (request.data && request.data.text ? String(request.data.text) : "").trim();
      const dialect = request.data && request.data.dialect === "levantine" ? "levantine" : "fusha";
      if (!text || text.length > 400) {
        throw new HttpsError("invalid-argument", "Please provide text up to 400 characters.");
      }

      let voiceKey;
      let voiceId = null;
      let elevenLabsModel = null;
      if (dialect === "levantine") {
        voiceId = elevenLabsLevantineVoice.value();
        if (!voiceId) {
          throw new HttpsError("failed-precondition", "No Levantine voice is configured yet.");
        }
        elevenLabsModel = await resolveElevenLabsModel();
        voiceKey = `elevenlabs|${elevenLabsModel}|${voiceId}`;
      } else {
        voiceKey = `openai|${SPEECH_MODEL}|${SPEECH_VOICE}`;
      }

      // Same text + dialect + voice always maps to the same file, so each word
      // or sentence is only ever generated (and paid for) once.
      const hash = crypto.createHash("sha256")
          .update(`${SPEECH_VERSION}|${voiceKey}|${dialect}|${text}`)
          .digest("hex")
          .slice(0, 40);
      const path = `audio/${dialect}/${hash}.mp3`;
      const bucket = speechBucket();
      const file = bucket.file(path);

      try {
        const [exists] = await file.exists();
        if (exists) {
          const [meta] = await file.getMetadata();
          const cachedToken = meta.metadata && meta.metadata.firebaseStorageDownloadTokens;
          if (cachedToken) return {url: storageDownloadUrl(bucket.name, path, cachedToken)};
        }
      } catch (e) {
        throw new HttpsError("internal", `Could not reach audio storage — is Firebase Storage enabled? (${e.message})`);
      }

      let audio;
      try {
        audio = dialect === "levantine" ?
          await synthesizeLevantine(text, voiceId, elevenLabsModel) :
          await synthesizeWithOpenAI(text);
      } catch (e) {
        throw new HttpsError("internal", `Speech generation failed: ${e.message}`);
      }

      // A download token lets the app stream the file without opening up the
      // bucket's public access or storage rules.
      const token = crypto.randomUUID();
      try {
        await file.save(audio, {
          resumable: false,
          metadata: {
            contentType: "audio/mpeg",
            cacheControl: "public, max-age=31536000",
            metadata: {firebaseStorageDownloadTokens: token},
          },
        });
      } catch (e) {
        throw new HttpsError("internal", `Could not store audio: ${e.message}`);
      }

      return {url: storageDownloadUrl(bucket.name, path, token)};
    },
);

function assertAdmin(request) {
  const allowed = adminUids.value().split(",").map((u) => u.trim()).filter(Boolean);
  if (!request.auth || !allowed.includes(request.auth.uid)) {
    throw new HttpsError("permission-denied", "Only admins can run this.");
  }
}

// Admin-only: runs the review pass over verbs already in the dictionary.
// Processes a limited batch per call (to stay inside the function timeout);
// call it repeatedly until `remaining` is 0.
exports.reviewVerbs = onCall({secrets: [openaiApiKey], cors: true, timeoutSeconds: 540}, async (request) => {
  assertAdmin(request);

  const BATCH_SIZE = 20;
  const CONCURRENCY = 4;

  const snapshot = await admin.firestore().collection("dictionary").where("root_family", "!=", null).get();
  const pending = snapshot.docs.filter((d) => d.data().verbReviewVersion !== REVIEW_VERSION);
  const batch = pending.slice(0, BATCH_SIZE);

  const client = new OpenAI({apiKey: openaiApiKey.value()});
  const results = [];
  for (let i = 0; i < batch.length; i += CONCURRENCY) {
    const chunk = batch.slice(i, i + CONCURRENCY);
    const chunkResults = await Promise.all(chunk.map(async (doc) => {
      const data = doc.data();
      const reviewed = await reviewRootFamily(client, data.english, data.root_family);
      if (!reviewed.ok) return {english: data.english, failed: true, changes: []};
      await doc.ref.update({
        root_family: reviewed.rootFamily,
        verbReviewVersion: REVIEW_VERSION,
        verbReviewChanges: reviewed.changes,
        verbReviewedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return {english: data.english, failed: false, changes: reviewed.changes};
    }));
    results.push(...chunkResults);
  }

  const failed = results.filter((r) => r.failed).length;
  return {
    reviewed: results.length - failed,
    failed,
    remaining: pending.length - results.length + failed,
    results,
  };
});

// Admin-only: makes the `quizzes` collection exactly the bundled questions
// (functions/seed_quizzes.js) — loads/overwrites those and removes any others,
// so stray or duplicate questions can't push a level past its 10. No
// service-account key needed. Safe to run repeatedly.
exports.seedQuizzes = onCall({cors: true}, async (request) => {
  assertAdmin(request);

  const db = admin.firestore();
  const collection = db.collection("quizzes");
  const wanted = new Set(Object.keys(seedQuizQuestions));

  const existing = await collection.get();
  const extras = existing.docs.filter((d) => !wanted.has(d.id));

  const writes = [
    ...extras.map((d) => (batch) => batch.delete(d.ref)),
    ...Object.entries(seedQuizQuestions).map(([id, data]) => (batch) => batch.set(collection.doc(id), data)),
  ];
  for (let i = 0; i < writes.length; i += 400) {
    const batch = db.batch();
    writes.slice(i, i + 400).forEach((apply) => apply(batch));
    await batch.commit();
  }
  return {count: wanted.size, removed: extras.length};
});
