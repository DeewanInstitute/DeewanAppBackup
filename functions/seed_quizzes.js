/**
 * Seeds the Firestore `quizzes` collection with 150 questions: 3 levels
 * (beginner / intermediate / advanced) x 10 quizzes x 5 questions. The content
 * lives in quiz_bank.js; every quiz has one question of each of the five types.
 * Doc IDs are fixed (e.g. beginner_03_2 = beginner, quiz 3, question 2), so
 * re-running overwrites rather than duplicating, and anything else is removed.
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccountKey.json node seed_quizzes.js
 * (or, from the app: Settings -> "Load quiz questions", which calls the
 * seedQuizzes Cloud Function.) Keep service account keys out of git.
 */
const admin = require("firebase-admin");
const {bank} = require("./quiz_bank.js");

const questions = {};
for (const [difficulty, quizzes] of Object.entries(bank)) {
  quizzes.forEach((items, qi) => {
    items.forEach((item, i) => {
      const quiz = qi + 1;
      const id = `${difficulty}_${String(quiz).padStart(2, "0")}_${i + 1}`;
      questions[id] = {...item, difficulty, quiz, order: i + 1};
    });
  });
}

module.exports = {questions};

async function seed() {
  admin.initializeApp();
  const db = admin.firestore();
  const collection = db.collection("quizzes");

  // Remove anything that isn't one of these questions, so every level is exactly 10.
  const existing = await collection.get();
  const batch = db.batch();
  let removed = 0;
  for (const doc of existing.docs) {
    if (!(doc.id in questions)) {
      batch.delete(doc.ref);
      removed++;
    }
  }
  for (const [id, data] of Object.entries(questions)) {
    batch.set(collection.doc(id), data);
  }
  await batch.commit();
  console.log(`Seeded ${Object.keys(questions).length} quiz questions, removed ${removed} extra.`);
}

if (require.main === module) {
  seed()
    .then(() => process.exit(0))
    .catch((err) => {
      console.error("Seeding failed:", err);
      process.exit(1);
    });
}
