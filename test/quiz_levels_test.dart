import 'package:deewan_institute_app/core/quiz_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// 10 quizzes x 5 questions in each of the three levels.
List<QuizQuestion> fullBank() => [
      for (final level in QuizService.levelIds)
        for (var quiz = 1; quiz <= 10; quiz++)
          for (var order = 1; order <= 5; order++)
            QuizQuestion(
              id: '${level}_${quiz}_$order',
              type: QuizType.trueFalse,
              difficulty: level,
              quiz: quiz,
              order: order,
            ),
    ];

/// Finished quiz ids for the first [count] quizzes of [level].
Set<String> finished(String level, int count) => {for (var n = 1; n <= count; n++) QuizService.quizIdOf(level, n)};

void main() {
  group('computeLevels', () {
    test('a new student can only open beginner, with 10 quizzes in each level', () {
      final levels = QuizService.computeLevels(fullBank(), {});
      expect(levels.map((l) => l.unlocked), [true, false, false]);
      expect(levels.map((l) => l.finished), [0, 0, 0]);
      expect(levels.map((l) => l.total), [10, 10, 10]);
    });

    test('9 of 10 beginner quizzes does NOT unlock intermediate', () {
      final levels = QuizService.computeLevels(fullBank(), finished('beginner', 9));
      expect(levels[0].finished, 9);
      expect(levels[0].isComplete, isFalse);
      expect(levels[1].unlocked, isFalse);
    });

    test('all 10 beginner quizzes unlocks intermediate, not advanced', () {
      final levels = QuizService.computeLevels(fullBank(), finished('beginner', 10));
      expect(levels[0].isComplete, isTrue);
      expect(levels.map((l) => l.unlocked), [true, true, false]);
    });

    test('finishing intermediate unlocks advanced', () {
      final levels = QuizService.computeLevels(fullBank(), {...finished('beginner', 10), ...finished('intermediate', 10)});
      expect(levels.map((l) => l.unlocked), [true, true, true]);
      expect(levels[2].isComplete, isFalse);
    });

    test('intermediate quizzes do not count while beginner is unfinished', () {
      final levels = QuizService.computeLevels(fullBank(), {...finished('beginner', 4), ...finished('intermediate', 10)});
      expect(levels.map((l) => l.unlocked), [true, false, false]);
    });

    test('progress fraction per level', () {
      final levels = QuizService.computeLevels(fullBank(), finished('beginner', 6));
      expect(levels[0].fraction, closeTo(0.6, 1e-9));
      expect(levels[1].fraction, 0);
    });

    test('a level with no quizzes stays locked and blocks later levels', () {
      final noIntermediate = fullBank().where((x) => x.difficulty != 'intermediate').toList();
      final levels = QuizService.computeLevels(noIntermediate, finished('beginner', 10));
      expect(levels.map((l) => l.unlocked), [true, false, false]);
    });

    test('ids that are not real quizzes are ignored', () {
      final levels = QuizService.computeLevels(fullBank(), {'beginner_99', ...finished('beginner', 3)});
      expect(levels[0].finished, 3);
    });
  });

  group('quiz order inside a level', () {
    test('only quiz 1 is open to start with', () {
      final beginner = QuizService.computeLevels(fullBank(), {})[0];
      expect(beginner.nextQuiz, 1);
      expect(beginner.isQuizUnlocked(1), isTrue);
      expect(beginner.isQuizUnlocked(2), isFalse);
    });

    test('finishing a quiz opens the next one, and finished ones stay replayable', () {
      final beginner = QuizService.computeLevels(fullBank(), finished('beginner', 3))[0];
      expect(beginner.nextQuiz, 4);
      expect([for (var n = 1; n <= 6; n++) beginner.isQuizUnlocked(n)], [true, true, true, true, false, false]);
    });

    test('a finished level has every quiz open for replay', () {
      final beginner = QuizService.computeLevels(fullBank(), finished('beginner', 10))[0];
      expect(beginner.nextQuiz, 11);
      expect(beginner.isQuizUnlocked(10), isTrue);
    });

    test('quizzes of a locked level are never open', () {
      final intermediate = QuizService.computeLevels(fullBank(), {})[1];
      expect(intermediate.isQuizUnlocked(1), isFalse);
    });
  });

  group('finishing a quiz', () {
    test('needs 80%: 4 of 5 finishes it, 3 of 5 does not', () {
      expect(QuizService.passesQuiz(correct: 5, total: 5), isTrue);
      expect(QuizService.passesQuiz(correct: 4, total: 5), isTrue);
      expect(QuizService.passesQuiz(correct: 3, total: 5), isFalse);
      expect(QuizService.passesQuiz(correct: 0, total: 5), isFalse);
    });

    test('an empty quiz never counts', () {
      expect(QuizService.passesQuiz(correct: 0, total: 0), isFalse);
    });
  });

  group('questionsForQuiz', () {
    test('returns the 5 questions of that quiz in order', () {
      final shuffled = fullBank()..shuffle();
      final quiz = QuizService.questionsForQuiz(shuffled, 'intermediate', 3);
      expect(quiz.map((x) => x.id), [for (var o = 1; o <= 5; o++) 'intermediate_3_$o']);
    });

    test('unknown quiz is empty', () {
      expect(QuizService.questionsForQuiz(fullBank(), 'beginner', 11), isEmpty);
    });
  });

  group('resume', () {
    final bank = fullBank().where((x) => x.difficulty == 'beginner' && x.quiz == 1).toList();

    test('restores questions in the saved order, not bank order', () {
      final ordered = QuizService.orderByIds(bank, ['beginner_1_4', 'beginner_1_1', 'beginner_1_5', 'beginner_1_2', 'beginner_1_3']);
      expect(ordered.map((x) => x.order), [4, 1, 5, 2, 3]);
    });

    test('drops questions that no longer exist, so the caller can detect the mismatch', () {
      final ids = ['beginner_1_2', 'gone', 'beginner_1_3'];
      final ordered = QuizService.orderByIds(bank, ids);
      expect(ordered.map((x) => x.order), [2, 3]);
      expect(ordered.length == ids.length, isFalse);
    });

    test('QuizResume exposes total and a readable level label', () {
      const resume = QuizResume(
        levelId: 'intermediate',
        quizNumber: 4,
        questionIds: ['a', 'b', 'c', 'd', 'e'],
        currentIndex: 2,
        correctCount: 2,
      );
      expect(resume.total, 5);
      expect(resume.levelLabel, 'Intermediate');
    });
  });
}
