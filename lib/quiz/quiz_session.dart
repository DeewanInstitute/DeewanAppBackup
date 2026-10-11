import 'package:deewan_institute_app/core/app_bottom_nav.dart';
import 'package:deewan_institute_app/core/app_colors.dart';
import 'package:deewan_institute_app/core/app_drawer.dart';
import 'package:deewan_institute_app/core/app_loading.dart';
import 'package:deewan_institute_app/core/app_top_nav.dart';
import 'package:deewan_institute_app/core/quiz_service.dart';
import 'package:deewan_institute_app/core/speaker_button.dart';
import 'package:deewan_institute_app/flashcards/review_incorrect_page.dart';
import 'package:deewan_institute_app/word_search/word_search_page.dart';
import 'package:flutter/material.dart';

class QuizSession extends StatefulWidget {
  final QuizLevel level;
  final int quizNumber;

  /// When set, continues an unfinished quiz from where it was left off instead
  /// of starting it again from question 1.
  final QuizResume? resume;
  const QuizSession({super.key, required this.level, required this.quizNumber, this.resume});

  @override
  State<QuizSession> createState() => _QuizSessionState();
}

enum _OptionState { neutral, correct, wrong }

class _QuizSessionState extends State<QuizSession> {
  List<QuizQuestion> _questions = [];
  bool _isLoading = true;
  bool _loadFailed = false;
  bool _isFinished = false;

  int _currentIndex = 0;
  int _correctCount = 0;
  bool _answered = false;
  int? _selectedOption;
  bool? _selectedTrueFalse;
  final _textController = TextEditingController();

  QuizLevel? _levelAfter;
  QuizLevel? _nextLevel;
  bool _passed = false;

  // The saved position only applies to the first load; "practice again" starts fresh.
  bool _useResume = true;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    try {
      var questions = <QuizQuestion>[];
      var startIndex = 0;
      var startCorrect = 0;

      final resume = _useResume ? widget.resume : null;
      if (resume != null) {
        final saved = await QuizService.loadQuestionsByIds(resume.questionIds);
        // If questions were removed since, the saved position no longer lines up.
        if (saved.length == resume.questionIds.length && resume.currentIndex < saved.length) {
          questions = saved;
          startIndex = resume.currentIndex;
          startCorrect = resume.correctCount;
        }
      }
      if (questions.isEmpty) {
        questions = await QuizService.loadQuiz(widget.level.id, widget.quizNumber);
      }
      _useResume = false;

      if (!mounted) return;
      setState(() {
        _questions = questions;
        _currentIndex = startIndex;
        _correctCount = startCorrect;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadFailed = true;
      });
    }
  }

  QuizQuestion get _question => _questions[_currentIndex];

  void _selectOption(int index) {
    if (_answered) return;
    final isCorrect = QuizService.checkOption(_question, index);
    setState(() {
      _selectedOption = index;
      _answered = true;
      if (isCorrect) _correctCount++;
    });
    _showFeedback(isCorrect);
  }

  void _selectTrueFalse(bool value) {
    if (_answered) return;
    final isCorrect = QuizService.checkTrueFalse(_question, value);
    setState(() {
      _selectedTrueFalse = value;
      _answered = true;
      if (isCorrect) _correctCount++;
    });
    _showFeedback(isCorrect);
  }

  void _checkText() {
    if (_answered) return;
    final input = _textController.text.trim();
    if (input.isEmpty) return;
    final isCorrect = QuizService.checkText(_question, input);
    setState(() {
      _answered = true;
      if (isCorrect) _correctCount++;
    });
    _showFeedback(isCorrect);
  }

  /// Remembers the position (pointing at the next unanswered question) so the
  /// quiz shows up in History if the student leaves now. The last question is
  /// skipped: finishing clears the saved state instead.
  void _saveResume() {
    if (_currentIndex + 1 >= _questions.length) return;
    QuizService.saveResume(
      levelId: widget.level.id,
      quizNumber: widget.quizNumber,
      questionIds: [for (final q in _questions) q.id],
      currentIndex: _currentIndex + 1,
      correctCount: _correctCount,
    ).catchError((Object e) => debugPrint('Saving quiz resume failed: $e'));
  }

  Future<void> _showFeedback(bool isCorrect) async {
    _saveResume();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => _QuizFeedbackSheet(isCorrect: isCorrect, correctAnswer: isCorrect ? null : _correctAnswerLabel()),
    );
    _nextQuestion();
  }

  String? _correctAnswerLabel() {
    final q = _question;
    switch (q.type) {
      case QuizType.fillBlank:
      case QuizType.translateToArabic:
        return q.answer;
      case QuizType.wordMeaning:
      case QuizType.listenSelect:
        final i = q.correctIndex;
        return (i != null && i < q.options.length) ? q.options[i] : null;
      case QuizType.trueFalse:
        return q.isCorrect == true ? 'True' : 'False';
    }
  }

  void _nextQuestion() {
    if (!mounted) return;
    if (_currentIndex + 1 >= _questions.length) {
      _finishSession();
      return;
    }
    setState(() {
      _currentIndex++;
      _answered = false;
      _selectedOption = null;
      _selectedTrueFalse = null;
      _textController.clear();
    });
  }

  Future<void> _finishSession() async {
    final passed = QuizService.passesQuiz(correct: _correctCount, total: _questions.length);
    setState(() {
      _isFinished = true;
      _passed = passed;
    });
    QuizService.recordSessionResult(correct: _correctCount, total: _questions.length);
    QuizService.clearResume().catchError((_) {});

    try {
      if (passed) await QuizService.markQuizFinished(widget.level.id, widget.quizNumber);
      final levels = await QuizService.loadLevels();
      if (!mounted) return;
      final index = QuizService.levelIds.indexOf(widget.level.id);
      setState(() {
        _levelAfter = levels[index];
        _nextLevel = index + 1 < levels.length ? levels[index + 1] : null;
      });
    } catch (_) {
      // The finish screen still works without the level summary.
    }
  }

  void _openQuiz(QuizLevel level, int quizNumber) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => QuizSession(level: level, quizNumber: quizNumber)),
    );
  }

  void _restart() {
    setState(() {
      _currentIndex = 0;
      _correctCount = 0;
      _answered = false;
      _selectedOption = null;
      _selectedTrueFalse = null;
      _isFinished = false;
      _passed = false;
      _levelAfter = null;
      _nextLevel = null;
      _textController.clear();
    });
    _loadQuestions();
  }

  void _goHome() => Navigator.popUntil(context, (route) => route.isFirst);

  void _openSearch() => AppLoading.navigate(context, const WordSearchPage());

  void _openReviewIncorrect() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewIncorrectPage()));
  }

  _OptionState _stateFor(int index) {
    if (!_answered) return _OptionState.neutral;
    if (index == _question.correctIndex) return _OptionState.correct;
    if (index == _selectedOption) return _OptionState.wrong;
    return _OptionState.neutral;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      drawer: const AppDrawer(),
      bottomNavigationBar: AppBottomNav(
        currentIndex: -1,
        onTap: (i) {
          if (i == 0) _goHome();
          if (i == 1) _openSearch();
          if (i == 2) _openReviewIncorrect();
        },
      ),
      body: SafeArea(
        bottom: false,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.green));
    }
    if (_loadFailed) {
      return _QuizLoadErrorWidget(onRetry: _loadQuestions);
    }
    if (_questions.isEmpty) {
      return _QuizEmptyWidget(onRetry: _loadQuestions);
    }
    if (_isFinished) {
      return _buildFinishScreen();
    }
    return _buildQuestion();
  }

  Widget _buildQuestion() {
    final total = _questions.length;
    final progress = (_currentIndex + 1) / total;
    final pct = (progress * 100).round();
    final q = _question;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppTopNav(),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${_currentIndex + 1} of $total',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
                ),
                Text(
                  '$pct%',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.green, ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.primaryBorder,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green),
                minHeight: 6,
              ),
            ),
            if (q.difficulty != null && q.difficulty!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: AppColors.green.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  '${q.difficulty!.toUpperCase()} · QUIZ ${widget.quizNumber}',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.green, letterSpacing: 0.5),
                ),
              ),
            ],
            const SizedBox(height: 20),
            _buildQuestionCard(q),
            const SizedBox(height: 20),
            _buildAnswerArea(q),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(QuizQuestion q) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: switch (q.type) {
        QuizType.fillBlank => _buildFillBlankCard(q),
        QuizType.listenSelect => _buildListenSelectCard(q),
        QuizType.wordMeaning => _buildWordMeaningCard(q),
        QuizType.translateToArabic => _buildTranslateCard(q),
        QuizType.trueFalse => _buildTrueFalseCard(q),
      },
    );
  }

  Widget _buildFillBlankCard(QuizQuestion q) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Complete the sentence',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.muted),
        ),
        const SizedBox(height: 20),
        Text(
          q.promptArabic ?? '',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.end,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
        const SizedBox(height: 12),
        Text(
          q.promptEnglish ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontStyle: FontStyle.italic, color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _buildListenSelectCard(QuizQuestion q) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SpeakerButton(text: q.arabic ?? '', size: 72, iconSize: 32),
        const SizedBox(height: 16),
        const Text(
          'Listen and select the correct word',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.orange),
        ),
      ],
    );
  }

  Widget _buildWordMeaningCard(QuizQuestion q) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'What does this word mean?',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.muted),
        ),
        const SizedBox(height: 20),
        Text(
          q.arabic ?? '',
          textAlign: TextAlign.end,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 34, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
        if (q.transliteration != null) ...[
          const SizedBox(height: 8),
          Text(
            q.transliteration!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontStyle: FontStyle.italic, color: AppColors.muted),
          ),
        ],
      ],
    );
  }

  Widget _buildTranslateCard(QuizQuestion q) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Translate into Arabic',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.muted),
        ),
        const SizedBox(height: 20),
        Text(
          q.promptEnglish ?? '',
          textAlign: TextAlign.right,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
      ],
    );
  }

  Widget _buildTrueFalseCard(QuizQuestion q) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Is this translation correct?',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.muted),
        ),
        const SizedBox(height: 20),
        Text(
          q.arabic ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: AppColors.green.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
          child: const Text('=', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.green)),
        ),
        const SizedBox(height: 10),
        Text(
          q.english ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
      ],
    );
  }

  Widget _buildAnswerArea(QuizQuestion q) {
    switch (q.type) {
      case QuizType.fillBlank:
        return _buildTextAnswer(hint: 'Type Arabic word here...', buttonLabel: 'Check Answer', maxLength: null);
      case QuizType.translateToArabic:
        return _buildTextAnswer(hint: '...', buttonLabel: 'Check', maxLength: 100);
      case QuizType.listenSelect:
      case QuizType.wordMeaning:
        return Column(
          children: List.generate(q.options.length, (i) {
            return _OptionRow(
              letter: String.fromCharCode(65 + i),
              label: q.options[i],
              state: _stateFor(i),
              onTap: _answered ? null : () => _selectOption(i),
            );
          }),
        );
      case QuizType.trueFalse:
        return Row(
          children: [
            Expanded(
              child: _TrueFalseButton(
                label: 'True',
                icon: Icons.check_rounded,
                color: AppColors.green,
                dimmed: _answered && _selectedTrueFalse != true,
                onTap: _answered ? null : () => _selectTrueFalse(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TrueFalseButton(
                label: 'False',
                icon: Icons.close_rounded,
                color: AppColors.coral,
                dimmed: _answered && _selectedTrueFalse != false,
                onTap: _answered ? null : () => _selectTrueFalse(false),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildTextAnswer({required String hint, required String buttonLabel, int? maxLength}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: TextField(
            controller: _textController,
            enabled: !_answered,
            maxLength: maxLength,
            maxLines: 1,
            textAlign: TextAlign.end,
            textAlignVertical: TextAlignVertical.center,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 15, color: AppColors.ink),
            decoration: InputDecoration(
              hintText: hint,
              hintTextDirection: TextDirection.rtl,
              hintStyle: const TextStyle(fontFamily: 'Inter', color: AppColors.muted, fontSize: 14),
              border: InputBorder.none,
              isCollapsed: false,
              contentPadding: EdgeInsets.zero,
            ),
            buildCounter: maxLength == null
                ? null
                : (context, {required currentLength, required isFocused, maxLength}) => Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      '$currentLength / $maxLength characters',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.muted),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _answered ? null : _checkText,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
            elevation: 0,
            textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700),
          ),
          child: Text(buttonLabel),
        ),
      ],
    );
  }

  Widget _buildFinishScreen() {
    final total = _questions.length;
    final pct = total == 0 ? 0 : ((_correctCount / total) * 100).round();
    final incorrectCount = total - _correctCount;
    final needed = (total * QuizService.passMark).ceil();

    final level = _levelAfter;
    final next = _nextLevel;
    final levelComplete = _passed && (level?.isComplete ?? false);
    final nextLevelUnlocked = levelComplete && next != null && next.unlocked;
    final nextQuizInLevel = (_passed && level != null && !level.isComplete) ? level.nextQuiz : null;

    // What the primary button does next.
    final String primaryLabel;
    final VoidCallback primaryAction;
    if (!_passed) {
      primaryLabel = 'Retry Quiz ${widget.quizNumber}';
      primaryAction = _restart;
    } else if (nextQuizInLevel != null) {
      primaryLabel = 'Start Quiz $nextQuizInLevel';
      primaryAction = () => _openQuiz(level!, nextQuizInLevel);
    } else if (nextLevelUnlocked) {
      primaryLabel = 'Start ${next.label}';
      primaryAction = () => _openQuiz(next, 1);
    } else {
      primaryLabel = 'Play Again';
      primaryAction = _restart;
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppTopNav(),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      levelComplete
                          ? '${widget.level.label} Complete!'
                          : _passed
                              ? 'Quiz ${widget.quizNumber} Complete!'
                              : 'Almost there!',
                      style: const TextStyle(fontFamily: 'Prociono', fontSize: 30, color: AppColors.ink),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _passed
                          ? 'You scored $_correctCount of $total.'
                          : 'You scored $_correctCount of $total. Get at least $needed right to finish this quiz.',
                      style: const TextStyle(fontSize: 14, color: AppColors.muted, fontFamily: 'Inter'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 6))],
                      ),
                      child: Row(
                        children: [
                          Expanded(child: _QuizStatColumn(icon: Icons.check_rounded, color: AppColors.green, value: '$_correctCount', label: 'Correct')),
                          const SizedBox(height: 40, child: VerticalDivider(color: AppColors.primaryBorder)),
                          Expanded(child: _QuizStatColumn(icon: Icons.close_rounded, color: AppColors.coral, value: '$incorrectCount', label: 'Incorrect')),
                          const SizedBox(height: 40, child: VerticalDivider(color: AppColors.primaryBorder)),
                          Expanded(child: _QuizStatColumn(icon: Icons.show_chart_rounded, color: AppColors.orange, value: '$pct%', label: 'Score')),
                        ],
                      ),
                    ),
                    if (level != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 6))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${level.label} progress',
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                                ),
                                Text(
                                  '${level.finished} / ${level.total} quizzes',
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.green),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: level.fraction,
                                minHeight: 8,
                                backgroundColor: AppColors.primaryBorder,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green),
                              ),
                            ),
                            if (nextLevelUnlocked) ...[
                              const SizedBox(height: 14),
                              Text(
                                '🎉 ${next.label} is now unlocked!',
                                style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.green),
                              ),
                            ] else if (levelComplete && next == null) ...[
                              const SizedBox(height: 14),
                              const Text(
                                "🏆 You've completed every level!",
                                style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.green),
                              ),
                            ] else if (!levelComplete) ...[
                              const SizedBox(height: 14),
                              Text(
                                'Finish ${level.total - level.finished} more quiz${level.total - level.finished == 1 ? '' : 'zes'} to ${next == null ? 'complete this level' : 'unlock ${next.label}'}.',
                                style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.muted, height: 1.4),
                              ),
                            ],
                            if (!QuizService.isSignedIn) ...[
                              const SizedBox(height: 10),
                              const Text(
                                'Log in to save your progress.',
                                style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.coral),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: primaryAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                          elevation: 0,
                          textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        child: Text(primaryLabel),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppColors.green),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                        ),
                        child: const Text(
                          'Back to Quizzes',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.green),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Option Row ────────────────────────────────────────────────────────────────

class _OptionRow extends StatelessWidget {
  final String letter;
  final String label;
  final _OptionState state;
  final VoidCallback? onTap;
  const _OptionRow({required this.letter, required this.label, required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color accent = switch (state) {
      _OptionState.correct => AppColors.green,
      _OptionState.wrong => AppColors.coral,
      _OptionState.neutral => AppColors.orange,
    };
    final Color tint = switch (state) {
      _OptionState.correct => AppColors.green.withOpacity(0.08),
      _OptionState.wrong => AppColors.coral.withOpacity(0.08),
      _OptionState.neutral => Colors.white,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: tint,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: state == _OptionState.neutral ? AppColors.primaryBorder : accent, width: state == _OptionState.neutral ? 1 : 2),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: accent, width: 1.5)),
                  alignment: Alignment.center,
                  child: Text(letter, style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: accent, fontSize: 13)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 15, color: AppColors.ink, fontWeight: FontWeight.w600)),
                ),
                if (state == _OptionState.correct) const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 20),
                if (state == _OptionState.wrong) const Icon(Icons.cancel_rounded, color: AppColors.coral, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── True/False Button ─────────────────────────────────────────────────────────

class _TrueFalseButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool dimmed;
  final VoidCallback? onTap;
  const _TrueFalseButton({required this.label, required this.icon, required this.color, required this.dimmed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: dimmed ? color.withOpacity(0.4) : color,
      borderRadius: BorderRadius.circular(50),
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(width: 6),
              Icon(icon, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Feedback Sheet ─────────────────────────────────────────────────────────────

class _QuizFeedbackSheet extends StatelessWidget {
  final bool isCorrect;
  final String? correctAnswer;
  const _QuizFeedbackSheet({required this.isCorrect, this.correctAnswer});

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? AppColors.green : AppColors.coral;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.primaryBorder, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                child: Icon(isCorrect ? Icons.check_rounded : Icons.close_rounded, color: Colors.white, size: 30),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isCorrect ? 'Correct!' : 'Not quite!',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Prociono', fontSize: 26, color: color),
            ),
            if (!isCorrect && correctAnswer != null && correctAnswer!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.coral.withOpacity(0.06), borderRadius: BorderRadius.circular(14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CORRECT ANSWER:',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.coral, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      correctAnswer!,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  elevation: 0,
                  textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700),
                ),
                child: const Text('Next Question'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat Column ────────────────────────────────────────────────────────────────

class _QuizStatColumn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  const _QuizStatColumn({required this.icon, required this.color, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.12)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.muted)),
      ],
    );
  }
}

// ── Load Error / Empty ─────────────────────────────────────────────────────────

class _QuizLoadErrorWidget extends StatelessWidget {
  final VoidCallback onRetry;
  const _QuizLoadErrorWidget({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppTopNav(),
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_rounded, color: AppColors.coral, size: 36),
                    const SizedBox(height: 12),
                    const Text(
                      "Couldn't load the quiz",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Inter', color: AppColors.ink),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Check your connection and try again.',
                      style: TextStyle(fontSize: 13, color: AppColors.muted, fontFamily: 'Inter', height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Retry'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.green,
                        side: const BorderSide(color: AppColors.green),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizEmptyWidget extends StatelessWidget {
  final VoidCallback onRetry;
  const _QuizEmptyWidget({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppTopNav(),
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('📝', style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 12),
                    const Text(
                      'No quiz questions yet',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Inter', color: AppColors.ink),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Check back soon.',
                      style: TextStyle(fontSize: 13, color: AppColors.muted, fontFamily: 'Inter', height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Retry'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.green,
                        side: const BorderSide(color: AppColors.green),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
