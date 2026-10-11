import 'package:deewan_institute_app/core/app_bottom_nav.dart';
import 'package:deewan_institute_app/core/app_colors.dart';
import 'package:deewan_institute_app/core/app_drawer.dart';
import 'package:deewan_institute_app/core/app_loading.dart';
import 'package:deewan_institute_app/core/app_text_styles.dart';
import 'package:deewan_institute_app/core/app_top_nav.dart';
import 'package:deewan_institute_app/core/quiz_service.dart';
import 'package:deewan_institute_app/flashcards/review_incorrect_page.dart';
import 'package:deewan_institute_app/quiz/quiz_list_page.dart';
import 'package:deewan_institute_app/word_search/word_search_page.dart';
import 'package:flutter/material.dart';

/// Level picker: beginner → intermediate → advanced. Finishing all 10 quizzes
/// in a level unlocks the next one.
class QuizLevelsPage extends StatefulWidget {
  const QuizLevelsPage({super.key});

  @override
  State<QuizLevelsPage> createState() => _QuizLevelsPageState();
}

class _QuizLevelsPageState extends State<QuizLevelsPage> {
  List<QuizLevel>? _levels;
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
      if (mounted) setState(() => _levels = levels);
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  Future<void> _openLevel(QuizLevel level) async {
    if (!level.unlocked) {
      final previous = _levels![QuizService.levelIds.indexOf(level.id) - 1];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Finish all 10 ${previous.label} quizzes to unlock ${level.label}.')),
      );
      return;
    }
    await Navigator.push(context, MaterialPageRoute(builder: (_) => QuizListPage(levelId: level.id)));
    _load();
  }

  static const _levelStyle = {
    'beginner': (color: AppColors.green, icon: Icons.auto_awesome_rounded),
    'intermediate': (color: AppColors.orange, icon: Icons.bolt_rounded),
    'advanced': (color: AppColors.ink, icon: Icons.local_fire_department_rounded),
  };

  @override
  Widget build(BuildContext context) {
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
              const Text('Quiz', style: AppTextStyles.headingOne),
              const SizedBox(height: 6),
              const Text(
                'Finish all 10 quizzes in a level to unlock the next one.',
                style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.muted),
              ),
              if (!QuizService.isSignedIn) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Text(
                    'Log in to save your progress and unlock the next levels.',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.ink, height: 1.4),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (_loadFailed)
                _LoadError(onRetry: _load)
              else if (_levels == null)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(child: CircularProgressIndicator(color: AppColors.green)),
                )
              else
                for (final level in _levels!) ...[
                  _LevelCard(
                    level: level,
                    color: _levelStyle[level.id]!.color,
                    icon: _levelStyle[level.id]!.icon,
                    previousLabel: level.id == QuizService.levelIds.first
                        ? null
                        : _levels![QuizService.levelIds.indexOf(level.id) - 1].label,
                    onTap: () => _openLevel(level),
                  ),
                  const SizedBox(height: 16),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final QuizLevel level;
  final Color color;
  final IconData icon;
  final String? previousLabel;
  final VoidCallback onTap;
  const _LevelCard({
    required this.level,
    required this.color,
    required this.icon,
    required this.previousLabel,
    required this.onTap,
  });

  String get _actionLabel {
    if (!level.unlocked) return 'Locked';
    if (level.isComplete) return 'Practice again';
    return level.finished > 0 ? 'Continue' : 'Start';
  }

  @override
  Widget build(BuildContext context) {
    final locked = !level.unlocked;
    final background = locked ? AppColors.muted.withOpacity(0.35) : color;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(24),
          boxShadow: locked ? null : [BoxShadow(color: color.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level.label,
                        style: const TextStyle(fontFamily: 'Prociono', fontSize: 24, color: Colors.white, height: 1),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        locked && previousLabel != null
                            ? 'Finish all $previousLabel quizzes to unlock'
                            : '${level.finished} / ${level.total} quizzes finished',
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                  child: Icon(
                    locked ? Icons.lock_rounded : (level.isComplete ? Icons.check_rounded : icon),
                    color: locked ? AppColors.muted : color,
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: level.fraction,
                minHeight: 8,
                backgroundColor: Colors.white.withOpacity(0.25),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                color: locked ? Colors.white.withOpacity(0.5) : Colors.white,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                _actionLabel,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: locked ? AppColors.muted : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  final VoidCallback onRetry;
  const _LoadError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.coral, size: 36),
          const SizedBox(height: 12),
          const Text(
            "Couldn't load the quiz levels",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Inter', color: AppColors.ink),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Check your connection and try again.',
            style: TextStyle(fontSize: 13, color: AppColors.muted, fontFamily: 'Inter'),
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
            ),
          ),
        ],
      ),
    );
  }
}
