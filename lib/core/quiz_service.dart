import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
///   (English hint), [answer] (expected Arabic word).
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

  final String? promptArabic;
  final String? promptEnglish;
  final String? answer;

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
    this.promptArabic,
    this.promptEnglish,
    this.answer,
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
      promptArabic: data['promptArabic'] as String?,
      promptEnglish: data['promptEnglish'] as String?,
      answer: data['answer'] as String?,
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

  const QuizProgress({
    required this.sessionsCompleted,
    required this.questionsAnswered,
    required this.correctAnswers,
  });

  static const empty = QuizProgress(sessionsCompleted: 0, questionsAnswered: 0, correctAnswers: 0);

  double get accuracy => questionsAnswered == 0 ? 0 : correctAnswers / questionsAnswered;
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

  static Future<List<QuizQuestion>> loadSession({int limit = 10}) async {
    final snapshot = await FirebaseFirestore.instance.collection('quizzes').get();
    final all = snapshot.docs.map((d) => QuizQuestion.fromDoc(d.id, d.data())).toList();
    all.shuffle();
    return all.take(limit).toList();
  }

  static bool checkOption(QuizQuestion question, int selectedIndex) {
    return selectedIndex == question.correctIndex;
  }

  static bool checkTrueFalse(QuizQuestion question, bool selected) {
    return selected == question.isCorrect;
  }

  static bool checkText(QuizQuestion question, String input) {
    return _normalize(input) == _normalize(question.answer ?? '');
  }

  static String _normalize(String s) {
    return s
        .trim()
        .replaceAll(RegExp(r'[ً-ْ]'), '') // strip Arabic diacritics
        .replaceAll(RegExp(r'\s+'), ' ');
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
