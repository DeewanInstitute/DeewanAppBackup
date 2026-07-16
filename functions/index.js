const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const admin = require("firebase-admin");
const OpenAI = require("openai");

admin.initializeApp();

const openaiApiKey = defineSecret("OPENAI_API_KEY");

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

  entry.english = englishWord;
  entry.source = "openai";
  entry.model = "gpt-4o";
  entry.generatedAt = admin.firestore.FieldValue.serverTimestamp();

  await docRef.set(entry);

  return entry;
});
