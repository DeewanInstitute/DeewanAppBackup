import 'dart:convert';
import 'package:deewan_institute_app/core/app_bottom_nav.dart';
import 'package:deewan_institute_app/core/app_colors.dart';
import 'package:deewan_institute_app/core/app_loading.dart';
import 'package:deewan_institute_app/flashcards/flashcard_session.dart';
import 'package:deewan_institute_app/podcasts/podcast_home.dart';
import 'package:deewan_institute_app/word_search/word_search_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FlashcardsHome extends StatefulWidget {
  const FlashcardsHome({super.key});

  @override
  State<FlashcardsHome> createState() => _FlashcardsHomeState();
}

class _FlashcardsHomeState extends State<FlashcardsHome> {
  List<Map<String, dynamic>> _allWords = [];

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    final raw = await rootBundle.loadString('assets/data/arabic_dictionary.json');
    final list = jsonDecode(raw) as List;
    if (mounted) setState(() => _allWords = list.cast<Map<String, dynamic>>());
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F2),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 2,
        onTap: (i) {
          if (i == 2) return;
          if (i == 0) { Navigator.pop(context); return; }
          if (i == 1) { AppLoading.navigate(context, const WordSearchPage()); return; }
          if (i == 3) { AppLoading.navigate(context, const PodcastHome()); return; }
        },
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(topPad),
            const SizedBox(height: 24),
            if (_allWords.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              )
            else ...[
              _DeckCard(
                difficulty: 'Easy',
                description: 'Greetings & everyday words',
                count: 8,
                color: const Color(0xFF4ECBA8),
                icon: Icons.sentiment_satisfied_alt_rounded,
                words: _allWords.sublist(0, 8),
              ),
              const SizedBox(height: 16),
              _DeckCard(
                difficulty: 'Medium',
                description: 'Emotions, family & work',
                count: 11,
                color: const Color(0xFFFF9E4F),
                icon: Icons.sentiment_neutral_rounded,
                words: _allWords.sublist(8, 19),
              ),
              const SizedBox(height: 16),
              _DeckCard(
                difficulty: 'Hard',
                description: 'Verbs, time & abstract concepts',
                count: 11,
                color: const Color(0xFFE05C5C),
                icon: Icons.sentiment_dissatisfied_rounded,
                words: _allWords.sublist(19, 30),
              ),
              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double topPad) {
    return Container(
      width: MediaQuery.sizeOf(context).width,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 16, top: topPad + 8,
            child: Text('ك', style: TextStyle(fontSize: 100, color: Colors.white.withOpacity(0.07), fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w900)),
          ),
          Positioned(
            right: 90, top: topPad + 48,
            child: Text('ل', style: TextStyle(fontSize: 56, color: Colors.white.withOpacity(0.06), fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w900)),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Flashcards', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, fontFamily: 'PlusJakartaSans')),
                const SizedBox(height: 4),
                Text('Pick a difficulty and start learning', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13, fontFamily: 'PlusJakartaSans')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Deck Card ─────────────────────────────────────────────────────────────────

class _DeckCard extends StatelessWidget {
  final String difficulty;
  final String description;
  final int count;
  final Color color;
  final IconData icon;
  final List<Map<String, dynamic>> words;
  const _DeckCard({
    required this.difficulty,
    required this.description,
    required this.count,
    required this.color,
    required this.icon,
    required this.words,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FlashcardSession(words: words, difficulty: difficulty, color: color)),
        ),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 8))],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$count cards',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(difficulty, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, fontFamily: 'PlusJakartaSans')),
                    const SizedBox(height: 4),
                    Text(description, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, fontFamily: 'PlusJakartaSans')),
                  ],
                ),
              ),
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
