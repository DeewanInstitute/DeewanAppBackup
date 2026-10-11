import 'package:deewan_institute_app/core/app_bottom_nav.dart';
import 'package:deewan_institute_app/core/app_colors.dart';
import 'package:deewan_institute_app/core/app_drawer.dart';
import 'package:deewan_institute_app/core/app_loading.dart';
import 'package:deewan_institute_app/core/app_text_styles.dart';
import 'package:deewan_institute_app/core/app_top_nav.dart';
import 'package:deewan_institute_app/core/quiz_service.dart';
import 'package:deewan_institute_app/flashcards/review_incorrect_page.dart';
import 'package:deewan_institute_app/quiz/quiz_session.dart';
import 'package:deewan_institute_app/word_search/word_search_page.dart';
import 'package:flutter/material.dart';

/// The 10 quizzes of one level. They open in order: a quiz unlocks once the
/// one before it is finished (scored 80% or more).
class QuizListPage extends StatefulWidget {
  final String levelId;
  const QuizListPage({super.key, required this.levelId});

  @override
  State<QuizListPage> createState() => _QuizListPageState();
}

class _QuizListPageState extends State<QuizListPage> {
  QuizLevel? _level;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadFailed = false);
    try {
      final levels = await QuizService.loadLevels();
      final level = levels.firstWhere((l) => l.id == widget.levelId);
      if (mounted) setState(() => _level = level);
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  Color get _color => switch (widget.levelId) {
        'intermediate' => AppColors.orange,
        'advanced' => AppColors.ink,
        _ => AppColors.green,
      };

  Future<void> _openQuiz(QuizLevel level, int number) async {
    if (!level.isQuizUnlocked(number)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Finish Quiz ${number - 1} first to unlock Quiz $number.')),
      );
      return;
    }
    await Navigator.push(context, MaterialPageRoute(builder: (_) => QuizSession(level: level, quizNumber: number)));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final level = _level;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      drawer: const AppDrawer(),
      bottomNavigationBar: AppBottomNav(
        currentIndex: -1,
        onTap: (i) {
          if (i == 0) Navigator.popUntil(context, (route) => route.isFirst);
          if (i == 1) AppLoading.navigate(context, const WordSearchPage());
          if (i == 2) Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewIncorrectPage()));
        },
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppTopNav(),
              const SizedBox(height: 24),
              Text(
                '${widget.levelId[0].toUpperCase()}${widget.levelId.substring(1)} quizzes',
                style: AppTextStyles.headingOne,
              ),
              const SizedBox(height: 6),
              const Text(
                'Each quiz has 5 questions. Score at least 80% to finish it.',
                style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.muted),
              ),
              const SizedBox(height: 24),
              if (_loadFailed)
                Center(
                  child: OutlinedButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text("Couldn't load the quizzes. Retry"),
                  ),
                )
              else if (level == null)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(child: CircularProgressIndicator(color: AppColors.green)),
                )
              else ...[
                _ProgressHeader(level: level, color: _color),
                const SizedBox(height: 20),
                for (var n = 1; n <= level.total; n++) ...[
                  _QuizTile(
                    number: n,
                    color: _color,
                    finished: level.finishedQuizzes.contains(n),
                    unlocked: level.isQuizUnlocked(n),
                    current: level.nextQuiz == n,
                    onTap: () => _openQuiz(level, n),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final QuizLevel level;
  final Color color;
  const _ProgressHeader({required this.level, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${level.finished} / ${level.total} quizzes finished',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: level.fraction,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizTile extends StatelessWidget {
  final int number;
  final Color color;
  final bool finished;
  final bool unlocked;
  final bool current;
  final VoidCallback onTap;
  const _QuizTile({
    required this.number,
    required this.color,
    required this.finished,
    required this.unlocked,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = finished ? 'Finished · tap to replay' : (current ? 'Up next' : (unlocked ? 'Open' : 'Locked'));
    final accent = unlocked ? color : AppColors.muted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: current ? color : AppColors.primaryBorder, width: current ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withOpacity(0.12)),
              alignment: Alignment.center,
              child: finished
                  ? Icon(Icons.check_rounded, color: accent, size: 22)
                  : unlocked
                      ? Text('$number', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: accent, fontSize: 16))
                      : Icon(Icons.lock_rounded, color: accent, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quiz $number',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: unlocked ? AppColors.ink : AppColors.muted),
                  ),
                  const SizedBox(height: 2),
                  Text(status, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.muted)),
                ],
              ),
            ),
            if (unlocked) Icon(Icons.arrow_forward_rounded, color: accent, size: 20),
          ],
        ),
      ),
    );
  }
}
