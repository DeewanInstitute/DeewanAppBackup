import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

enum QuizType { fillBlank, listenSelect, wordMeaning, translateToArabic, trueFalse }

QuizType quizTypeFromString(String value) {
  switch (value) {
    case 'fill_blank':
      return QuizType.fillBlank;
    case 'listen_select':
      return QuizType.listenSelect;
    case 'word_meaning':
      return QuizType.wordMeaning;
    case 'translate_to_arabic':
      return QuizType.translateToArabic;
    case 'true_false':
      return QuizType.trueFalse;
    default:
      throw ArgumentError('Unknown quiz type: $value');
  }
}

String quizTypeToString(QuizType type) {
  switch (type) {
    case QuizType.fillBlank:
      return 'fill_blank';
    case QuizType.listenSelect:
      return 'listen_select';
    case QuizType.wordMeaning:
      return 'word_meaning';
    case QuizType.translateToArabic:
      return 'translate_to_arabic';
    case QuizType.trueFalse:
      return 'true_false';
  }
}

/// A single quiz question read from the Firestore `quizzes` collection.
/// Every question shares one document shape; only the fields relevant to
/// [type] are populated:
///
/// - fillBlank: [promptArabic] (sentence with a `___` blank), [promptEnglish]
///   (English hint), [answer] (expected Arabic word) and optional [acceptedAnswers].
/// - translateToArabic: [promptEnglish] (sentence to translate), [answer]
///   (expected Arabic sentence).
/// - wordMeaning: [arabic] + [transliteration], [options] (English
///   meanings), [correctIndex].
/// - listenSelect: [arabic] (the word to pronounce, not shown on screen),
///   [options] (transliteration + Arabic labels), [correctIndex].
/// - trueFalse: [arabic] + [english] (the pairing shown), [isCorrect]
///   (whether that pairing is actually a correct translation).
class QuizQuestion {
  final String id;
  final QuizType type;
  final String? difficulty;

  /// Which quiz of its level this question belongs to (1-10), and its position
  /// within that quiz (1-5).
  final int? quiz;
  final int? order;

  final String? promptArabic;
  final String? promptEnglish;
  final String? answer;
  // Other correct answers for free-text questions (synonyms, gender variants…).
  final List<String> acceptedAnswers;

  final String? arabic;
  final String? transliteration;
  final List<String> options;
  final int? correctIndex;

  final String? english;
  final bool? isCorrect;

  const QuizQuestion({
    required this.id,
    required this.type,
    this.difficulty,
    this.quiz,
    this.order,
    this.promptArabic,
    this.promptEnglish,
    this.answer,
    this.acceptedAnswers = const [],
    this.arabic,
    this.transliteration,
    this.options = const [],
    this.correctIndex,
    this.english,
    this.isCorrect,
  });

  factory QuizQuestion.fromDoc(String id, Map<String, dynamic> data) {
    return QuizQuestion(
      id: id,
      type: quizTypeFromString(data['type'] as String),
      difficulty: data['difficulty'] as String?,
      quiz: (data['quiz'] as num?)?.toInt(),
      order: (data['order'] as num?)?.toInt(),
      promptArabic: data['promptArabic'] as String?,
      promptEnglish: data['promptEnglish'] as String?,
      answer: data['answer'] as String?,
      acceptedAnswers: (data['acceptedAnswers'] as List?)?.cast<String>() ?? const [],
      arabic: data['arabic'] as String?,
      transliteration: data['transliteration'] as String?,
      options: (data['options'] as List?)?.cast<String>() ?? const [],
      correctIndex: data['correctIndex'] as int?,
      english: data['english'] as String?,
      isCorrect: data['isCorrect'] as bool?,
    );
  }
}

/// A student's cumulative quiz performance across all sessions they've
/// completed, persisted at users/{uid}/quizProgress/summary.
class QuizProgress {
  final int sessionsCompleted;
  final int questionsAnswered;
  final int correctAnswers;

  /// Quizzes the student has finished (scored at least [QuizService.passMark]),
  /// as ids like `beginner_03`. Level progress and unlocking come from this.
  final Set<String> finishedQuizIds;

  const QuizProgress({
    required this.sessionsCompleted,
    required this.questionsAnswered,
    required this.correctAnswers,
    this.finishedQuizIds = const {},
  });

  static const empty = QuizProgress(sessionsCompleted: 0, questionsAnswered: 0, correctAnswers: 0);

  double get accuracy => questionsAnswered == 0 ? 0 : correctAnswers / questionsAnswered;
}

/// One difficulty tier of the quiz (beginner → intermediate → advanced) with
/// the signed-in student's progress through its quizzes.
class QuizLevel {
  final String id;

  /// How many quizzes the level has (10), and which of them are finished.
  final int total;
  final Set<int> finishedQuizzes;
  final bool unlocked;

  const QuizLevel({required this.id, required this.total, required this.finishedQuizzes, required this.unlocked});

  String get label => id.isEmpty ? id : id[0].toUpperCase() + id.substring(1);

  int get finished => finishedQuizzes.length;

  bool get isComplete => total > 0 && finished >= total;

  double get fraction => total == 0 ? 0 : (finished / total).clamp(0.0, 1.0);

  /// The lowest quiz number not finished yet; `total + 1` once the level is done.
  int get nextQuiz {
    for (var n = 1; n <= total; n++) {
      if (!finishedQuizzes.contains(n)) return n;
    }
    return total + 1;
  }

  /// Quizzes are taken in order: a quiz opens once the one before it is finished.
  /// Finished quizzes can always be replayed.
  bool isQuizUnlocked(int number) => unlocked && number <= nextQuiz;
}

/// An unfinished quiz, saved so the student can pick it back up from History:
/// which quiz, the exact question order, and how far they got.
class QuizResume {
  final String levelId;
  final int quizNumber;
  final List<String> questionIds;
  final int currentIndex;
  final int correctCount;

  const QuizResume({
    required this.levelId,
    required this.quizNumber,
    required this.questionIds,
    required this.currentIndex,
    required this.correctCount,
  });

  int get total => questionIds.length;

  String get levelLabel => levelId.isEmpty ? levelId : levelId[0].toUpperCase() + levelId.substring(1);
}

/// Reads quiz questions from the Firestore `quizzes` collection (read-only
/// for clients — see firestore rules), checks answers client-side, and
/// tracks cumulative progress per signed-in user.
class QuizService {
  QuizService._();

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static bool get isSignedIn => _uid != null;

  static DocumentReference<Map<String, dynamic>>? get _progressDoc {
    final uid = _uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(uid).collection('quizProgress').doc('summary');
  }

  /// Difficulty tiers in unlock order.
  static const levelIds = ['beginner', 'intermediate', 'advanced'];

  static List<QuizQuestion>? _questionCache;

  static Future<List<QuizQuestion>> _allQuestions() async {
    final cached = _questionCache;
    if (cached != null) return cached;
    final snapshot = await FirebaseFirestore.instance.collection('quizzes').get();
    return _questionCache = snapshot.docs.map((d) => QuizQuestion.fromDoc(d.id, d.data())).toList();
  }

  /// A quiz is finished by scoring at least this share of its questions (4 of 5).
  static const passMark = 0.8;

  static bool passesQuiz({required int correct, required int total}) => total > 0 && correct / total >= passMark;

  static String quizIdOf(String levelId, int quizNumber) => '${levelId}_${quizNumber.toString().padLeft(2, '0')}';

  /// All three levels with the student's progress. Signed-out users see their
  /// progress as empty, so only the first beginner quiz is open.
  static Future<List<QuizLevel>> loadLevels() async {
    final questions = await _allQuestions();
    final progress = await loadProgress();
    return computeLevels(questions, progress.finishedQuizIds);
  }

  /// A level has one quiz per distinct quiz number among its questions. It
  /// unlocks once every quiz in the level before it is finished; beginner is
  /// always open (if it has any quizzes).
  @visibleForTesting
  static List<QuizLevel> computeLevels(List<QuizQuestion> questions, Set<String> finishedQuizIds) {
    final levels = <QuizLevel>[];
    var previousComplete = true;
    for (final id in levelIds) {
      final quizNumbers = {
        for (final q in questions)
          if (q.difficulty == id && q.quiz != null) q.quiz!,
      };
      final finished = {for (final n in quizNumbers) if (finishedQuizIds.contains(quizIdOf(id, n))) n};
      final unlocked = previousComplete && quizNumbers.isNotEmpty;
      levels.add(QuizLevel(id: id, total: quizNumbers.length, finishedQuizzes: finished, unlocked: unlocked));
      // A locked level can't count as finished, whatever progress is stored for it,
      // so later levels never open out of order.
      previousComplete = unlocked && finished.length >= quizNumbers.length;
    }
    return levels;
  }

  /// The questions of one quiz, in their fixed order.
  static Future<List<QuizQuestion>> loadQuiz(String levelId, int quizNumber) async {
    return questionsForQuiz(await _allQuestions(), levelId, quizNumber);
  }

  @visibleForTesting
  static List<QuizQuestion> questionsForQuiz(List<QuizQuestion> all, String levelId, int quizNumber) {
    return all.where((q) => q.difficulty == levelId && q.quiz == quizNumber).toList()
      ..sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
  }

  static DocumentReference<Map<String, dynamic>>? get _resumeDoc {
    final uid = _uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(uid).collection('quizProgress').doc('inProgress');
  }

  /// Saves where the student is in an unfinished quiz. No-ops when signed out.
  static Future<void> saveResume({
    required String levelId,
    required int quizNumber,
    required List<String> questionIds,
    required int currentIndex,
    required int correctCount,
  }) async {
    final doc = _resumeDoc;
    if (doc == null) return;
    await doc.set({
      'levelId': levelId,
      'quizNumber': quizNumber,
      'questionIds': questionIds,
      'currentIndex': currentIndex,
      'correctCount': correctCount,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// The unfinished quiz to offer in History, or null if there isn't one.
  static Future<QuizResume?> loadResume() async {
    final doc = _resumeDoc;
    if (doc == null) return null;
    final snapshot = await doc.get();
    final data = snapshot.data();
    if (data == null) return null;

    final ids = (data['questionIds'] as List?)?.cast<String>() ?? const <String>[];
    final index = (data['currentIndex'] as num?)?.toInt() ?? 0;
    final levelId = data['levelId'] as String?;
    final quizNumber = (data['quizNumber'] as num?)?.toInt();
    // A save from before quizzes existed has no quiz number and can't be resumed.
    if (levelId == null || quizNumber == null || ids.isEmpty || index >= ids.length) return null;
    return QuizResume(
      levelId: levelId,
      quizNumber: quizNumber,
      questionIds: ids,
      currentIndex: index,
      correctCount: (data['correctCount'] as num?)?.toInt() ?? 0,
    );
  }

  static Future<void> clearResume() async {
    final doc = _resumeDoc;
    if (doc == null) return;
    await doc.delete();
  }

  /// The saved questions, in their saved order. Returns fewer than asked if some
  /// were deleted since (callers should then start fresh instead of resuming).
  static Future<List<QuizQuestion>> loadQuestionsByIds(List<String> ids) async {
    return orderByIds(await _allQuestions(), ids);
  }

  @visibleForTesting
  static List<QuizQuestion> orderByIds(List<QuizQuestion> questions, List<String> ids) {
    final byId = {for (final q in questions) q.id: q};
    return [for (final id in ids) if (byId[id] != null) byId[id]!];
  }

  /// Records that the quiz was finished. Saved before the finish screen reads
  /// the levels back. No-ops when signed out.
  static Future<void> markQuizFinished(String levelId, int quizNumber) async {
    final doc = _progressDoc;
    if (doc == null) return;
    await doc.set({
      'finishedQuizIds': FieldValue.arrayUnion([quizIdOf(levelId, quizNumber)]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static bool checkOption(QuizQuestion question, int selectedIndex) {
    return selectedIndex == question.correctIndex;
  }

  static bool checkTrueFalse(QuizQuestion question, bool selected) {
    return selected == question.isCorrect;
  }

  static bool checkText(QuizQuestion question, String input) {
    final normalized = _normalize(input);
    if (normalized.isEmpty) return false;
    final accepted = [question.answer, ...question.acceptedAnswers].whereType<String>();
    return accepted.any((a) => _normalize(a) == normalized);
  }

  /// Makes typed Arabic comparable: drops vowel marks and tatweel, treats the
  /// alef-with-hamza forms as a plain alef and ى as ي (the usual mobile-keyboard
  /// variations), and ignores punctuation and extra spaces.
  static String _normalize(String s) {
    return s
        .replaceAll(RegExp(r'[\u064B-\u0652\u0640]'), '')
        .replaceAll(RegExp(r'[\u0622\u0623\u0625\u0671]'), '\u0627')
        .replaceAll('\u0649', '\u064A')
        .replaceAll(RegExp(r'[.,\u060C\u061F?!\u061B]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Admin-only: asks the server to (re)load the bundled quiz questions into
  /// Firestore, and removes any other questions so every level is exactly its 10 quizzes of 5 questions.
  static Future<({int count, int removed})> seedFromServer() async {
    final result = await FirebaseFunctions.instance.httpsCallable('seedQuizzes').call();
    _questionCache = null;
    final data = result.data as Map;
    return (count: data['count'] as int, removed: (data['removed'] as num?)?.toInt() ?? 0);
  }

  /// Fetches the signed-in user's cumulative quiz progress. Returns
  /// [QuizProgress.empty] if signed out or no session has been recorded yet.
  static Future<QuizProgress> loadProgress() async {
    final doc = _progressDoc;
    if (doc == null) return QuizProgress.empty;
    final snapshot = await doc.get();
    if (!snapshot.exists) return QuizProgress.empty;
    final data = snapshot.data()!;
    return QuizProgress(
      sessionsCompleted: (data['sessionsCompleted'] as num?)?.toInt() ?? 0,
      questionsAnswered: (data['questionsAnswered'] as num?)?.toInt() ?? 0,
      correctAnswers: (data['correctAnswers'] as num?)?.toInt() ?? 0,
      finishedQuizIds: ((data['finishedQuizIds'] as List?)?.cast<String>() ?? const <String>[]).toSet(),
    );
  }

  /// Adds the results of a just-finished session to the user's running
  /// totals. No-ops silently if signed out, consistent with the rest of the
  /// app's "don't interrupt the flow for a background write" pattern.
  static Future<void> recordSessionResult({required int correct, required int total}) async {
    final doc = _progressDoc;
    if (doc == null || total == 0) return;
    await doc.set({
      'sessionsCompleted': FieldValue.increment(1),
      'questionsAnswered': FieldValue.increment(total),
      'correctAnswers': FieldValue.increment(correct),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
