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

// past/present/imperative are the masculine forms (3ms, 3ms, 2ms); the
// *_feminine counterparts are 3fs, 3fs and 2fs.
const NULLABLE_FORM_SCHEMA = {...CONJUGATION_FORM_SCHEMA, type: ["object", "null"]};

const CONJUGATIONS_SCHEMA = {
  type: "object",
  properties: {
    past: CONJUGATION_FORM_SCHEMA,
    present: CONJUGATION_FORM_SCHEMA,
    imperative: CONJUGATION_FORM_SCHEMA,
    past_feminine: NULLABLE_FORM_SCHEMA,
    present_feminine: NULLABLE_FORM_SCHEMA,
    imperative_feminine: NULLABLE_FORM_SCHEMA,
  },
  required: ["past", "present", "imperative", "past_feminine", "present_feminine", "imperative_feminine"],
  additionalProperties: false,
};

// The feminine counterpart of a gendered pronoun (e.g. "you": أنتَ -> أنتِ), in
// both dialects. The word's own arabic/arabic_levantine fields are the masculine.
const FEMININE_FORM_SCHEMA = {
  type: ["object", "null"],
  properties: {
    arabic: {type: "string"},
    transliteration: {type: "string"},
    arabic_levantine: {type: "string"},
    transliteration_levantine: {type: "string"},
  },
  required: ["arabic", "transliteration", "arabic_levantine", "transliteration_levantine"],
  additionalProperties: false,
};

// Levantine sometimes uses a genuinely different verb/root for the same
// meaning (e.g. "sit" = Fusha جلس vs Levantine قعد) — nullable because not
// every root has a confidently-known Levantine equivalent. Levantine gets
// its own masdar/active_participle since those forms differ from Fusha too,
// not just the conjugations.
// Jordanian adds the continuous ("is writing") tense: عَمْ + the present form.
const LEVANTINE_CONJUGATIONS_SCHEMA = {
  ...CONJUGATIONS_SCHEMA,
  properties: {
    ...CONJUGATIONS_SCHEMA.properties,
    continuous: NULLABLE_FORM_SCHEMA,
    continuous_feminine: NULLABLE_FORM_SCHEMA,
  },
  required: [...CONJUGATIONS_SCHEMA.required, "continuous", "continuous_feminine"],
};

const LEVANTINE_ROOT_FAMILY_SCHEMA = {
  type: ["object", "null"],
  properties: {
    root: {type: "string"},
    different_root_than_fusha: {type: "boolean"},
    note: {type: ["string", "null"]},
    verb: MORPH_FORM_SCHEMA,
    conjugations: LEVANTINE_CONJUGATIONS_SCHEMA,
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
    feminine_form: FEMININE_FORM_SCHEMA,
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
    "feminine_form",
    "root_family",
  ],
  additionalProperties: false,
};

const SYSTEM_PROMPT =
  "You are a precise Arabic-English lexicographer building entries for an Arabic-learning app. " +
  "Given an English word or short phrase, produce a dictionary entry with Modern Standard Arabic (Fusha) " +
  "and colloquial Jordanian Arabic (Ammiyeh) forms. The colloquial fields must be ONLY the Jordanian " +
  "dialect specifically — not a blended or generic \"Levantine\", and not Palestinian, Syrian, or Lebanese " +
  "usage where it differs from Jordanian. Write EVERY Arabic string fully voweled with " +
  "harakat (tashkeel): the headwords in both dialects, example sentences, synonyms, antonyms, and every verb " +
  "form — fatha, damma, kasra, sukun, shadda and tanween where they are part of the word, so a learner can " +
  "read it aloud without guessing. Do not add case endings (i'rab) to the last letter of nouns in running " +
  "text. Provide exactly " +
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
  "GENDER FORMS. Arabic distinguishes masculine and feminine, so give both where they exist.\n" +
  "- Verbs: inside every 'conjugations' object, 'past', 'present' and 'imperative' are the MASCULINE forms " +
  "(3rd-person masculine past, 3rd-person masculine present, 2nd-person masculine imperative). Also fill " +
  "'past_feminine' (3rd-person feminine singular past, e.g. كَتَبَتْ), 'present_feminine' (3rd-person feminine " +
  "singular present, e.g. تَكْتُبُ) and 'imperative_feminine' (2nd-person feminine singular imperative, e.g. " +
  "اُكْتُبِي). Do this for both the Fusha and the Jordanian 'levantine' conjugations; the Jordanian present " +
  "feminine also starts with ب (e.g. بتكتب) while its past and imperative feminine forms do not. Use null only " +
  "when a feminine form genuinely does not exist.\n" +
  "- Pronouns (type \"pronoun\"): when the pronoun itself differs by gender (e.g. \"you\": أنتَ / أنتِ, Jordanian " +
  "إنتَ / إنتِ; \"your\": كَ / كِ), the main 'arabic'/'arabic_levantine' fields are the MASCULINE form and " +
  "'feminine_form' holds the feminine form in both dialects, with matching transliterations. The feminine " +
  "must be the same word as the masculine in the same dialect, differing only in the gender marking: the " +
  "Fusha feminine pairs with the Fusha masculine and the Jordanian feminine with the Jordanian masculine. Set " +
  "'feminine_form' to null for pronouns that do not change by gender (e.g. \"I\", \"we\") and for pronouns that " +
  "are already inherently one gender (\"he\", \"she\").\n" +
  "- Every other type: set 'feminine_form' to null.\n\n" +
  "Respond with only the JSON object, no commentary.";

// ── Verb review pass ──────────────────────────────────────────────────────────
// A second, stricter model pass over a generated root_family. Generation and
// checking are separate jobs: the generator is busy producing a whole entry,
// while the reviewer only has to verify forms one by one against a checklist.
const REVIEW_MODEL = "gpt-4o";
// Bump when REVIEW_PROMPT improves, so every verb is re-reviewed under the new rules.
const REVIEW_VERSION = 4;
// Bump when the harakat pass improves, so every word is re-voweled.
const HARAKAT_VERSION = 1;

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
  "6. The feminine forms are present and correct: 'past_feminine' is the 3rd-person feminine singular past " +
  "(كَتَبَتْ), 'present_feminine' the 3rd-person feminine singular present (تَكْتُبُ), 'imperative_feminine' " +
  "the 2nd-person feminine singular imperative (اُكْتُبِي — ends in ي, with the same hamzat-al-wasl vowel as " +
  "the masculine). Fill them in if they are missing (null) and a feminine form exists.\n" +
  "6b. Every Arabic form is fully voweled (harakat on every letter that needs one, shadda included).\n" +
  "7. Every 'transliteration' matches the vowels actually written in its Arabic, and every 'english' gloss " +
  "is accurate.\n\n" +
  "CHECKLIST — Jordanian (the 'levantine' object):\n" +
  "8. It must be genuinely Jordanian colloquial, not Fusha with the case endings dropped and not another " +
  "Levantine variety. Verify the root: if Jordanian uses a different verb for this meaning, " +
  "'different_root_than_fusha' is true with an explanatory 'note'.\n" +
  "9. 'conjugations.present.arabic' MUST start with ب. 'past' and 'imperative' must NOT; the Jordanian 'present_feminine' also starts with ب, while " +
  "'past_feminine' and 'imperative_feminine' do not. 'continuous' is عَمْ followed by the present form (عَمْ + " +
  "'present'), and 'continuous_feminine' is عَمْ + 'present_feminine'.\n" +
  "10. Verify each form is a real thing a Jordanian says. Pay particular attention to verbs whose colloquial " +
  "stem is irregular (أكل → ياكُل not يُوكُل; أخذ → ياخُذ; جا/جاب; hollow verbs like شاف/قال/نام).\n" +
  "11. 'masdar' and 'active_participle' are the forms Jordanians actually use; null them only if you are " +
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

// ── Jordanian verb forms ──────────────────────────────────────────────────────
// A dedicated call for the colloquial side of a verb: its conjugations, the
// continuous tense and the masdar are the part the one-shot entry generation
// gets wrong most often, so they get their own focused job.
const JORDANIAN_VERB_PROMPT =
  "You are an expert in Jordanian (Ammani) colloquial Arabic. Given an English verb and its Modern Standard " +
  "Arabic root family, produce the verb's Jordanian forms: not generic \"Levantine\" and not Palestinian, " +
  "Syrian or Lebanese where those differ.\n\n" +
  "Rules:\n" +
  "1. 'root': the root of the verb Jordanians actually use for this meaning. If it is a different verb from " +
  "Fusha (ذهب -> راح, جلس -> قعد, رأى -> شاف), set 'different_root_than_fusha' true and explain in 'note'; " +
  "otherwise false and 'note' null.\n" +
  "2. 'verb' is the past 3rd-person masculine singular (e.g. كَتَب).\n" +
  "3. 'conjugations': 'past' / 'past_feminine' are 3rd-person masculine / feminine singular (كَتَب / كَتَبِت). " +
  "'present' / 'present_feminine' are 3rd-person masculine / feminine singular and MUST start with the ب- " +
  "prefix (بِيكْتُب / بِتِكْتُب, بِشُوف / بِتْشُوف). 'imperative' / 'imperative_feminine' are 2nd-person " +
  "masculine / feminine singular (اُكْتُب / اُكْتُبِي) and must NOT start with ب.\n" +
  "4. 'continuous' / 'continuous_feminine' are the progressive (\"is writing\"): the particle عَمْ followed by " +
  "the matching present form, e.g. عَمْ بِيكْتُب / عَمْ بِتِكْتُب.\n" +
  "5. 'masdar' is the verbal noun Jordanians actually say, which may differ from the Fusha masdar " +
  "(شُوفِة, not رُؤْيَة). 'active_participle' is the form used in speech (شايِف, كاتِب). Use null only when you " +
  "are genuinely not confident — never invent one.\n" +
  "6. Every Arabic string fully voweled with harakat; every transliteration matches the vowels written; every " +
  "'english' gloss is accurate.\n" +
  "7. MASCULINE AND FEMININE MUST MATCH: each *_feminine form is the SAME verb as its masculine form, in " +
  "the same Jordanian dialect, differing only in the gender marking (past ـَت, present تـ with the same " +
  "stem and vowels, imperative ـي). Never mix a Fusha form with a colloquial one, and never use a different " +
  "stem or verb for the feminine. Where Jordanian drops a Fusha ending, drop it in both genders.\n" +
  "8. Set 'levantine' to null only if you are not confident of the Jordanian verb at all.\n\n" +
  "Respond with only the JSON object.";

const JORDANIAN_VERB_SCHEMA = {
  type: "object",
  properties: {levantine: LEVANTINE_ROOT_FAMILY_SCHEMA},
  required: ["levantine"],
  additionalProperties: false,
};

// Returns {levantine, ok}. Never throws; callers keep the existing forms on failure.
async function generateJordanianVerbForms(client, englishWord, rootFamily) {
  try {
    const completion = await client.chat.completions.create({
      model: REVIEW_MODEL,
      messages: [
        {role: "system", content: JORDANIAN_VERB_PROMPT},
        {
          role: "user",
          content: `English verb: "${englishWord}"\nFusha root family: ${JSON.stringify({
            root: rootFamily.root,
            verb: rootFamily.verb,
            masdar: rootFamily.masdar,
          })}`,
        },
      ],
      response_format: {
        type: "json_schema",
        json_schema: {name: "jordanian_verb_forms", schema: JORDANIAN_VERB_SCHEMA, strict: true},
      },
    });
    const result = JSON.parse(completion.choices[0].message.content);
    return {levantine: result.levantine || null, ok: !!result.levantine};
  } catch (e) {
    console.error(`Jordanian verb forms failed for "${englishWord}":`, e.message);
    return {levantine: null, ok: false};
  }
}

// ── Harakat ───────────────────────────────────────────────────────────────────
// Every Arabic string in an entry gets full vowel marks. Done as its own pass so
// entries stored before the rule existed can be brought up to date too.
const HARAKAT_SCHEMA = {
  type: "object",
  properties: {
    arabic: {type: "string"},
    arabic_levantine: {type: "string"},
    fusha_sentences: {type: "array", items: {type: "string"}},
    levantine_sentences: {type: "array", items: {type: "string"}},
    synonyms: {type: "array", items: {type: "string"}},
    antonyms: {type: "array", items: {type: "string"}},
    feminine_form: {
      type: ["object", "null"],
      properties: {arabic: {type: "string"}, arabic_levantine: {type: "string"}},
      required: ["arabic", "arabic_levantine"],
      additionalProperties: false,
    },
  },
  required: ["arabic", "arabic_levantine", "fusha_sentences", "levantine_sentences", "synonyms", "antonyms", "feminine_form"],
  additionalProperties: false,
};

const HARAKAT_PROMPT =
  "You add vowel marks (harakat/tashkeel) to Arabic text for a learner's dictionary. For every Arabic string " +
  "you are given, return the SAME text with complete, correct harakat: fatha, damma, kasra, sukun, shadda " +
  "and tanween where they belong to the word. Do NOT change, add, remove or reorder any letters or words, " +
  "and do not translate. Fusha text follows standard Modern Standard Arabic vowelling (without case endings " +
  "on nouns in running text); the 'levantine' strings are colloquial Jordanian and must be voweled the way " +
  "Jordanians pronounce them, not as Fusha. Keep the same number of items in every list, in the same order. " +
  "Respond with only the JSON object.";

const TASHKEEL = /[\u064B-\u0652\u0670\u0640]/g;
const stripMarks = (t) => String(t || "").replace(TASHKEEL, "");

// Takes the voweled text only if it is the original with marks added, so the
// model can never reword a stored entry through this pass.
function voweledOr(original, voweled) {
  return typeof voweled === "string" && stripMarks(voweled) === stripMarks(original) ? voweled : original;
}

function voweledList(original, voweled) {
  if (!Array.isArray(original)) return original;
  if (!Array.isArray(voweled) || voweled.length !== original.length) return original;
  return original.map((o, i) => voweledOr(o, voweled[i]));
}

// Returns {fields, ok}: the entry fields that changed once voweled.
async function addHarakat(client, entry) {
  try {
    const payload = {
      arabic: entry.arabic,
      arabic_levantine: entry.arabic_levantine,
      fusha_sentences: (entry.fusha_sentences || []).map((x) => x.arabic),
      levantine_sentences: (entry.levantine_sentences || []).map((x) => x.arabic),
      synonyms: entry.synonyms || [],
      antonyms: entry.antonyms || [],
      feminine_form: entry.feminine_form ?
        {arabic: entry.feminine_form.arabic, arabic_levantine: entry.feminine_form.arabic_levantine} : null,
    };
    const completion = await client.chat.completions.create({
      model: REVIEW_MODEL,
      messages: [
        {role: "system", content: HARAKAT_PROMPT},
        {role: "user", content: JSON.stringify(payload)},
      ],
      response_format: {
        type: "json_schema",
        json_schema: {name: "harakat", schema: HARAKAT_SCHEMA, strict: true},
      },
    });
    const r = JSON.parse(completion.choices[0].message.content);

    const withArabic = (sentences, voweled) => {
      if (!Array.isArray(sentences)) return sentences;
      const marked = voweledList(sentences.map((x) => x.arabic), voweled);
      return sentences.map((x, i) => ({...x, arabic: marked[i]}));
    };

    const fields = {
      arabic: voweledOr(entry.arabic, r.arabic),
      arabic_levantine: voweledOr(entry.arabic_levantine, r.arabic_levantine),
      fusha_sentences: withArabic(entry.fusha_sentences, r.fusha_sentences),
      levantine_sentences: withArabic(entry.levantine_sentences, r.levantine_sentences),
      synonyms: voweledList(entry.synonyms, r.synonyms),
      antonyms: voweledList(entry.antonyms, r.antonyms),
    };
    if (entry.feminine_form && r.feminine_form) {
      fields.feminine_form = {
        ...entry.feminine_form,
        arabic: voweledOr(entry.feminine_form.arabic, r.feminine_form.arabic),
        arabic_levantine: voweledOr(entry.feminine_form.arabic_levantine, r.feminine_form.arabic_levantine),
      };
    }
    return {fields, ok: true};
  } catch (e) {
    console.error(`Harakat pass failed for "${entry.english}":`, e.message);
    return {fields: {}, ok: false};
  }
}

// ── Masculine / feminine consistency ──────────────────────────────────────────
// The masculine and feminine forms of a verb must be the same verb in the same
// dialect, differing only in the gender marking. The model is asked for this;
// these checks make sure, and the reviewer is re-run on whatever fails.
const norm = (t) => stripMarks(t).replace(/\s+/g, " ").trim();

function formViolations(rootFamily) {
  const problems = [];
  const check = (label, c, jordanian) => {
    if (!c) return;
    const t = (f) => (f && f.arabic ? norm(f.arabic) : null);
    const [past, pastF, pres, presF, imp, impF] = [
      t(c.past), t(c.past_feminine), t(c.present), t(c.present_feminine), t(c.imperative), t(c.imperative_feminine),
    ];
    const pairs = [["past", past, pastF], ["present", pres, presF], ["imperative", imp, impF]];
    for (const [name, m, f] of pairs) {
      if (m && f && m === f) problems.push(`${label}: '${name}' and '${name}_feminine' are identical`);
      if (m && !f) problems.push(`${label}: '${name}_feminine' is missing`);
    }
    if (pastF && !pastF.endsWith("ت")) problems.push(`${label}: 'past_feminine' (${pastF}) must end in ت`);
    if (impF && !impF.endsWith("ي")) problems.push(`${label}: 'imperative_feminine' (${impF}) must end in ي`);
    if (jordanian) {
      if (pres && !pres.startsWith("ب")) problems.push(`${label}: 'present' (${pres}) must start with ب`);
      if (presF && !presF.startsWith("ب")) problems.push(`${label}: 'present_feminine' (${presF}) must start with ب`);
    } else {
      if (pres && !pres.startsWith("ي")) problems.push(`${label}: 'present' (${pres}) must start with ي`);
      if (presF && !presF.startsWith("ت")) problems.push(`${label}: 'present_feminine' (${presF}) must start with ت`);
    }
  };
  check("Fusha", rootFamily.conjugations, false);
  if (rootFamily.levantine) check("Jordanian", rootFamily.levantine.conjugations, true);
  return problems;
}

// The continuous tense is always عَمْ + the present form, so it is built from the
// present forms rather than trusted from the model; it can never drift from them.
function withContinuous(rootFamily) {
  const lev = rootFamily && rootFamily.levantine;
  if (!lev || !lev.conjugations) return rootFamily;
  const c = lev.conjugations;
  const build = (present) => (present && present.arabic ?
    {arabic: `عَمْ ${present.arabic}`, transliteration: `'am ${present.transliteration}`} : null);
  return {
    ...rootFamily,
    levantine: {
      ...lev,
      conjugations: {...c, continuous: build(c.present), continuous_feminine: build(c.present_feminine)},
    },
  };
}

// The headword shown on a verb's card is its present 3rd-person masculine, so
// it is taken from the conjugation table: the card's masculine word and the
// feminine one beside it then always come from the same table.
function withTableHeadwords(entry) {
  const rf = entry.root_family;
  if (!rf) return entry;
  const out = {...entry};
  const present = rf.conjugations && rf.conjugations.present;
  if (present && present.arabic) {
    out.arabic = present.arabic;
    if (present.transliteration) out.transliteration = present.transliteration;
  }
  const lev = rf.levantine && rf.levantine.conjugations && rf.levantine.conjugations.present;
  if (lev && lev.arabic) {
    out.arabic_levantine = lev.arabic;
    if (lev.transliteration) out.transliteration_levantine = lev.transliteration;
  }
  return out;
}

// Returns {rootFamily, changes, ok}. Never throws: if the review call fails, the
// original generated entry is kept (ok=false) rather than losing the lookup, and
// callers must not mark the entry as reviewed.
async function reviewRootFamily(client, englishWord, rootFamily) {
  const original = rootFamily;
  // The dedicated Jordanian pass replaces the entry's colloquial forms; the
  // reviewer below then checks the whole result, Fusha and Jordanian together.
  const jordanian = await generateJordanianVerbForms(client, englishWord, rootFamily);
  if (jordanian.ok) rootFamily = {...rootFamily, levantine: jordanian.levantine};

  const review = async (rf, problems) => {
    const completion = await client.chat.completions.create({
      model: REVIEW_MODEL,
      messages: [
        {role: "system", content: REVIEW_PROMPT + SYSTEM_PROMPT},
        {
          role: "user",
          content: `English verb: "${englishWord}"\n\nroot_family to review:\n${JSON.stringify(rf)}` +
            (problems.length ?
              `\n\nThese specific problems were found by an automatic check and MUST be fixed — the ` +
              `masculine and feminine forms must be the same verb in the same dialect:\n- ${problems.join("\n- ")}` :
              ""),
        },
      ],
      response_format: {
        type: "json_schema",
        json_schema: {name: "root_family_review", schema: REVIEW_SCHEMA, strict: true},
      },
    });
    return JSON.parse(completion.choices[0].message.content);
  };

  try {
    let result = await review(rootFamily, formViolations(rootFamily));
    if (!result.root_family) return {rootFamily: original, changes: [], ok: false};
    const changes = result.changes || [];

    // One more pass on whatever the checks still object to.
    const remaining = formViolations(result.root_family);
    if (remaining.length > 0) {
      const second = await review(result.root_family, remaining);
      if (second.root_family) {
        result = second;
        changes.push(...(second.changes || []));
      }
    }
    const leftover = formViolations(result.root_family);
    if (leftover.length > 0) changes.push(`unresolved: ${leftover.join("; ")}`);
    return {rootFamily: withContinuous(result.root_family), changes, ok: true};
  } catch (e) {
    console.error(`Verb review failed for "${englishWord}":`, e.message);
    return {rootFamily: original, changes: [], ok: false};
  }
}

const FEMININE_REVIEW_SCHEMA = {
  type: "object",
  properties: {feminine_form: FEMININE_FORM_SCHEMA},
  required: ["feminine_form"],
  additionalProperties: false,
};

// Returns {feminineForm, ok}. For an existing pronoun entry: its feminine
// counterpart in both dialects, or null if the pronoun doesn't change by gender.
async function fillFeminineForm(client, entry) {
  try {
    const completion = await client.chat.completions.create({
      model: REVIEW_MODEL,
      messages: [
        {
          role: "system",
          content: "You are a meticulous Arabic lexicographer. Given a dictionary entry for an English " +
            "pronoun, return its FEMININE counterpart in Modern Standard Arabic and in colloquial Jordanian " +
            "Arabic, with transliterations. The entry's own arabic/arabic_levantine are the masculine form. " +
            "Examples: \"you\" -> أنتِ / Jordanian إنتِ; \"your\" -> كِ. Return null when the pronoun does not " +
            "change by gender (\"I\", \"we\") or is already inherently one gender (\"he\", \"she\"). The feminine form must be the SAME " +
            "word as the masculine one in the same dialect, differing only in the gender marking — a Fusha " +
            "feminine pairs with the Fusha masculine, and the Jordanian feminine pairs with the Jordanian " +
            "masculine (إنتَ / إنتِ, never أنتَ / إنتِ). Fully vowel every Arabic string with harakat. Respond " +
            "with only the JSON object.",
        },
        {
          role: "user",
          content: `English: "${entry.english}"\nArabic: ${entry.arabic} (${entry.transliteration})\n` +
            `Jordanian: ${entry.arabic_levantine} (${entry.transliteration_levantine})`,
        },
      ],
      response_format: {
        type: "json_schema",
        json_schema: {name: "feminine_form", schema: FEMININE_REVIEW_SCHEMA, strict: true},
      },
    });
    const result = JSON.parse(completion.choices[0].message.content);
    return {feminineForm: result.feminine_form === undefined ? null : result.feminine_form, ok: true};
  } catch (e) {
    console.error(`Feminine form lookup failed for "${entry.english}":`, e.message);
    return {feminineForm: null, ok: false};
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

  const voweled = await addHarakat(client, entry);
  if (voweled.ok) {
    Object.assign(entry, voweled.fields);
    entry.harakatVersion = HARAKAT_VERSION;
  }

  entry = withTableHeadwords(entry);

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

// Admin-only: brings words already in the dictionary up to date. Verbs get the
// review pass (which also adds their feminine forms) and pronouns get their
// feminine form. Processes a limited batch per call (to stay inside the function
// timeout); call it repeatedly until `remaining` is 0.
exports.reviewVerbs = onCall({secrets: [openaiApiKey], cors: true, timeoutSeconds: 540}, async (request) => {
  assertAdmin(request);

  const BATCH_SIZE = 20;
  const CONCURRENCY = 4;

  const snapshot = await admin.firestore().collection("dictionary").get();
  const stepsFor = (data) => ({
    harakat: data.harakatVersion !== HARAKAT_VERSION,
    verb: !!data.root_family && data.verbReviewVersion !== REVIEW_VERSION,
    feminine: !data.root_family && data.type === "pronoun" && data.feminine_form === undefined,
  });
  const pending = snapshot.docs.filter((d) => Object.values(stepsFor(d.data())).some(Boolean));
  const batch = pending.slice(0, BATCH_SIZE);

  const client = new OpenAI({apiKey: openaiApiKey.value()});
  const results = [];
  for (let i = 0; i < batch.length; i += CONCURRENCY) {
    const chunk = batch.slice(i, i + CONCURRENCY);
    const chunkResults = await Promise.all(chunk.map(async (doc) => {
      const data = doc.data();
      const steps = stepsFor(data);
      const update = {};
      const changes = [];
      let failed = false;

      if (steps.harakat) {
        const voweled = await addHarakat(client, data);
        if (voweled.ok) {
          Object.assign(update, voweled.fields, {harakatVersion: HARAKAT_VERSION});
          Object.assign(data, voweled.fields);
          changes.push("added harakat");
        } else {
          failed = true;
        }
      }
      if (steps.verb) {
        const reviewed = await reviewRootFamily(client, data.english, data.root_family);
        if (reviewed.ok) {
          Object.assign(update, {
            root_family: reviewed.rootFamily,
            verbReviewVersion: REVIEW_VERSION,
            verbReviewChanges: reviewed.changes,
            verbReviewedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          changes.push(...reviewed.changes);
        } else {
          failed = true;
        }
      }
      if (steps.feminine) {
        const filled = await fillFeminineForm(client, data);
        if (filled.ok) {
          update.feminine_form = filled.feminineForm;
          if (filled.feminineForm) changes.push("added feminine form");
        } else {
          failed = true;
        }
      }

      // Keep the card's masculine headword identical to the conjugation table's.
      if (steps.verb || steps.harakat) {
        const synced = withTableHeadwords({...data, ...update});
        for (const key of ["arabic", "transliteration", "arabic_levantine", "transliteration_levantine"]) {
          if (synced[key] !== data[key]) update[key] = synced[key];
        }
      }

      if (Object.keys(update).length > 0) await doc.ref.update(update);
      return {english: data.english, failed, changes};
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
