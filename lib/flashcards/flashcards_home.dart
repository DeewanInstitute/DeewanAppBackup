import 'dart:convert';
import 'package:deewan_institute_app/core/app_bottom_nav.dart';
import 'package:deewan_institute_app/core/app_colors.dart';
import 'package:deewan_institute_app/core/app_drawer.dart';
import 'package:deewan_institute_app/core/app_loading.dart';
import 'package:deewan_institute_app/core/app_top_nav.dart';
import 'package:deewan_institute_app/core/dashed_border.dart';
import 'package:deewan_institute_app/core/flashcard_service.dart';
import 'package:deewan_institute_app/flashcards/create_custom_card_sheet.dart';
import 'package:deewan_institute_app/flashcards/flashcard_session.dart';
import 'package:deewan_institute_app/flashcards/review_incorrect_page.dart';
import 'package:deewan_institute_app/word_search/word_search_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_text_styles.dart';

class FlashcardsHome extends StatefulWidget {
  const FlashcardsHome({super.key});

  @override
  State<FlashcardsHome> createState() => _FlashcardsHomeState();
}

class _FlashcardsHomeState extends State<FlashcardsHome> {
  List<Map<String, dynamic>> _allWords = [];
  int _customCount = 0;

  @override
  void initState() {
    super.initState();
    _loadWords();
    _loadCustomCount();
  }

  Future<void> _loadWords() async {
    final raw = await rootBundle.loadString('assets/data/arabic_dictionary.json');
    final list = jsonDecode(raw) as List;
    if (mounted) setState(() => _allWords = list.cast<Map<String, dynamic>>());
  }

  Future<void> _loadCustomCount() async {
    final count = await FlashcardService.deckCount(FlashcardDecks.custom.id);
    if (mounted) setState(() => _customCount = count);
  }

  Future<void> _createCustomCard() async {
    final created = await showCreateCustomCardSheet(context);
    if (created) _loadCustomCount();
  }

  Future<void> _studyCustomDeck() async {
    final words = await FlashcardService.getDeckWords(FlashcardDecks.custom.id);
    if (!mounted || words.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FlashcardSession(words: words, difficulty: 'Custom', color: AppColors.coral)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      extendBody: true,
      drawer: const AppDrawer(),
      bottomNavigationBar: AppBottomNav(
        currentIndex: -1,
        onTap: (i) {
          if (i == 0) {
            Navigator.popUntil(context, (route) => route.isFirst);
            return;
          }
          if (i == 1) {
            AppLoading.navigate(context, const WordSearchPage());
            return;
          }
          if (i == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewIncorrectPage()));
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
              const Text(
                'Flashcards',
                style: AppTextStyles.headingOne,
              ),
              const SizedBox(height: 6),
              const Text('Choose your level', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.muted)),
              const SizedBox(height: 24),
              if (_allWords.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(child: CircularProgressIndicator(color: AppColors.green)),
                )
              else ...[
                _DeckCard(
                  title: 'Beginner',
                  count: 8,
                  color: AppColors.green,
                  icon: Icons.auto_awesome_rounded,
                  onStart: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FlashcardSession(words: _allWords.sublist(0, 8), difficulty: 'Beginner', color: AppColors.green),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _DeckCard(
                  title: 'Intermediate',
                  count: 11,
                  color: AppColors.orange,
                  icon: Icons.bolt_rounded,
                  onStart: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FlashcardSession(words: _allWords.sublist(8, 19), difficulty: 'Intermediate', color: AppColors.orange),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _DeckCard(
                  title: 'Advanced',
                  count: 11,
                  color: AppColors.ink,
                  icon: Icons.local_fire_department_rounded,
                  onStart: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FlashcardSession(words: _allWords.sublist(19, 30), difficulty: 'Advanced', color: AppColors.ink),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _CustomDeckCard(
                  count: _customCount,
                  onCreate: _createCustomCard,
                  onStart: _customCount > 0 ? _studyCustomDeck : null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Deck Card ─────────────────────────────────────────────────────────────────

class _DeckCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;
  final VoidCallback onStart;
  const _DeckCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))],
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
                      title,
                      style: const TextStyle(fontFamily: 'Prociono', fontSize: 24, color: Colors.white, height: 1),
                    ),
                    const SizedBox(height: 4),
                    Text('$count cards', style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white70)),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                child: Icon(icon, color: color, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 44),
          SizedBox(
            width: 100,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: color,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700),
                elevation: 0,
              ),
              onPressed: onStart,
              child: const Text('Start'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom Deck Card ──────────────────────────────────────────────────────────

class _CustomDeckCard extends StatelessWidget {
  final int count;
  final VoidCallback onCreate;
  final VoidCallback? onStart;
  const _CustomDeckCard({required this.count, required this.onCreate, this.onStart});

  @override
  Widget build(BuildContext context) {
    return DashedBorderContainer(
      color: AppColors.orange,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.orange.withOpacity(0.05), borderRadius: BorderRadius.circular(24)),
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
                      const Text(
                        'Custom Cards',
                        style: TextStyle(fontFamily: 'Prociono', fontSize: 22, color: AppColors.ink, height: 1),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        count > 0 ? '$count cards' : 'Create your own cards',
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onCreate,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.orange),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.coral,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                      textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700),
                      elevation: 0,
                    ),
                    onPressed: onCreate,
                    child: const Text('Create'),
                  ),
                ),
                if (onStart != null) ...[
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 100,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: const BorderSide(color: AppColors.orange),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                        textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      onPressed: onStart,
                      child: const Text('Start'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
