/**
 * One-off script to seed the Firestore `quizzes` collection with sample
 * questions covering all 5 quiz types. Safe to re-run — each question has a
 * fixed doc ID, so re-running overwrites rather than duplicating.
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccountKey.json node seed_quizzes.js
 *
 * The service account key is downloaded from:
 *   Firebase Console → Project Settings (gear icon) → Service Accounts tab
 *   → "Generate new private key"
 * Keep that file out of git — it's a full admin credential for the project.
 */
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

const questions = {
  fill_blank_1: {
    type: "fill_blank",
    difficulty: "beginner",
    promptArabic: "أنا ___ الكتاب",
    promptEnglish: "I ___ the book",
    answer: "أقرأ",
  },
  listen_select_1: {
    type: "listen_select",
    difficulty: "beginner",
    arabic: "كتاب",
    options: ["(Kitaab) كتاب", "(Qalam) قلم", "(Baab) باب", "(Tawila) طاولة"],
    correctIndex: 0,
  },
  word_meaning_1: {
    type: "word_meaning",
    difficulty: "beginner",
    arabic: "كتاب",
    transliteration: "Kitaab",
    options: ["Book", "Pen", "Table", "Door"],
    correctIndex: 0,
  },
  translate_to_arabic_1: {
    type: "translate_to_arabic",
    difficulty: "intermediate",
    promptEnglish: "The book is on the table",
    answer: "الكتاب على الطاولة",
  },
  true_false_1: {
    type: "true_false",
    difficulty: "beginner",
    arabic: "بيت",
    english: "House",
    isCorrect: true,
  },
};

async function seed() {
  const batch = db.batch();
  for (const [id, data] of Object.entries(questions)) {
    batch.set(db.collection("quizzes").doc(id), data);
  }
  await batch.commit();
  console.log(`Seeded ${Object.keys(questions).length} quiz questions.`);
}

seed()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error("Seeding failed:", err);
    process.exit(1);
  });
