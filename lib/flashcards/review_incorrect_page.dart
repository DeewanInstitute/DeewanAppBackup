import 'package:deewan_institute_app/core/app_bottom_nav.dart';
import 'package:deewan_institute_app/core/app_colors.dart';
import 'package:deewan_institute_app/core/app_drawer.dart';
import 'package:deewan_institute_app/core/app_loading.dart';
import 'package:deewan_institute_app/core/app_text_styles.dart';
import 'package:deewan_institute_app/core/app_top_nav.dart';
import 'package:deewan_institute_app/core/flashcard_service.dart';
import 'package:deewan_institute_app/flashcards/flashcard_session.dart';
import 'package:deewan_institute_app/word_search/word_search_page.dart';
import 'package:flutter/material.dart';

class ReviewIncorrectPage extends StatefulWidget {
  const ReviewIncorrectPage({super.key});

  @override
  State<ReviewIncorrectPage> createState() => _ReviewIncorrectPageState();
}

class _ReviewIncorrectPageState extends State<ReviewIncorrectPage> {
  List<Map<String, dynamic>>? _cards;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cards = await FlashcardService.getIncorrectCards();
    if (mounted) setState(() => _cards = cards);
  }

  Future<void> _remove(String wordKey) async {
    setState(() => _cards = _cards!.where((c) => FlashcardService.wordKeyOf(c) != wordKey).toList());
    await FlashcardService.removeIncorrect(wordKey);
  }

  void _practice(Map<String, dynamic> word) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlashcardSession(words: [word], difficulty: 'Review', color: AppColors.coral, isReviewMode: true),
      ),
    ).then((_) => _load());
  }

  void _startReview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlashcardSession(words: _cards!, difficulty: 'Review', color: AppColors.coral, isReviewMode: true),
      ),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final cards = _cards;
    return Scaffold(
      backgroundColor: AppColors.cream,
      extendBody: true,
      drawer: const AppDrawer(),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 2,
        onTap: (i) {
          if (i == 2) return;
          if (i == 0) {
            Navigator.popUntil(context, (route) => route.isFirst);
            return;
          }
          if (i == 1) {
            AppLoading.navigate(context, const WordSearchPage());
            return;
          }
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
              const Text('Review Incorrect', style: AppTextStyles.headingOne),
              const SizedBox(height: 6),
              Text(
                cards == null ? 'Loading…' : '${cards.length} cards to review',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.coral, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              if (cards == null)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(child: CircularProgressIndicator(color: AppColors.green)),
                )
              else if (cards.isEmpty)
                const _EmptyState()
              else ...[
                for (final card in cards) ...[
                  _IncorrectCard(
                    word: card,
                    onRemove: () => _remove(FlashcardService.wordKeyOf(card)),
                    onPractice: () => _practice(card),
                  ),
                  const SizedBox(height: 14),
                ],
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _startReview,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                    label: const Text('Start Review'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                      textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _IncorrectCard extends StatelessWidget {
  final Map<String, dynamic> word;
  final VoidCallback onRemove;
  final VoidCallback onPractice;
  const _IncorrectCard({required this.word, required this.onRemove, required this.onPractice});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  word['arabic'] as String? ?? '',
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, fontFamily: 'Inter', color: AppColors.ink),
                ),
                if (word['transliteration'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    word['transliteration'] as String,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.orange, fontFamily: 'Inter'),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  word['english'] as String? ?? '',
                  style: const TextStyle(fontSize: 14, color: AppColors.muted, fontFamily: 'Inter'),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.coral.withOpacity(0.1)),
                  child: const Icon(Icons.close_rounded, color: AppColors.coral, size: 16),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: onPractice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700),
                  elevation: 0,
                ),
                child: const Text('Practice'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.green),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 16),
          const Text(
            "You're all caught up!",
            style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          const SizedBox(height: 6),
          const Text(
            'No cards need review right now.',
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
