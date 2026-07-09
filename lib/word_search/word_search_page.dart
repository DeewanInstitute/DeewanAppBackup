import 'dart:convert';
import 'package:deewan_institute_app/core/app_bottom_nav.dart';
import 'package:deewan_institute_app/core/app_colors.dart';
import 'package:deewan_institute_app/core/app_drawer.dart';
import 'package:deewan_institute_app/core/app_loading.dart';
import 'package:deewan_institute_app/core/app_top_nav.dart';
import 'package:deewan_institute_app/podcasts/podcast_home.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WordSearchPage extends StatefulWidget {
  const WordSearchPage({super.key});

  @override
  State<WordSearchPage> createState() => _WordSearchPageState();
}

class _WordSearchPageState extends State<WordSearchPage> {
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _dictionary = [];
  Map<String, dynamic>? _result;
  bool _notFound = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _loadDictionary();
  }

  Future<void> _loadDictionary() async {
    final raw = await rootBundle.loadString('assets/data/arabic_dictionary.json');
    final list = jsonDecode(raw) as List;
    if (mounted) setState(() => _dictionary = list.cast<Map<String, dynamic>>());
  }

  void _search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() { _result = null; _notFound = false; });
      return;
    }
    final match = _dictionary.firstWhere(
      (w) => (w['english'] as String).toLowerCase() == q,
      orElse: () => <String, dynamic>{},
    );
    setState(() {
      _result = match.isNotEmpty ? match : null;
      _notFound = match.isEmpty;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F2),
      extendBody: true,
      drawer: const AppDrawer(selectedIndex: AppDrawer.dictionaryIndex),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: AppTopNav(),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildHeader(0)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 126),
            sliver: SliverToBoxAdapter(
              child: _result != null
                  ? _ResultCard(word: _result!)
                  : _notFound
                      ? _NotFoundWidget(query: _controller.text.trim())
                      : _HintWidget(onSuggest: (w) {
                          _controller.text = w;
                          setState(() => _hasText = true);
                          _search(w);
                        }),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 1,
        onTap: (i) {
          if (i == 1) return;
          if (i == 0) {
            Navigator.popUntil(context, (route) => route.isFirst);
            return;
          }
          if (i == 2) {
            AppLoading.navigate(context, const PodcastHome());
            return;
          }
        },
      ),
    );
  }

  Widget _buildHeader(double topPad) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 16, top: topPad + 8,
            child: Text('ب', style: TextStyle(fontSize: 100, color: Colors.white.withOpacity(0.07), fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w900)),
          ),
          Positioned(
            right: 84, top: topPad + 52,
            child: Text('ح', style: TextStyle(fontSize: 54, color: Colors.white.withOpacity(0.06), fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w900)),
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
                const Text('Word Search', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, fontFamily: 'PlusJakartaSans')),
                const SizedBox(height: 4),
                Text(
                  'Type an English word for Arabic translation',
                  style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13, fontFamily: 'PlusJakartaSans'),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _search,
                    onChanged: (v) {
                      setState(() => _hasText = v.trim().isNotEmpty);
                      if (v.trim().isEmpty) setState(() { _result = null; _notFound = false; });
                    },
                    style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'e.g. water, love, morning...',
                      hintStyle: const TextStyle(color: Colors.black38, fontFamily: 'PlusJakartaSans'),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                      suffixIcon: _hasText
                          ? GestureDetector(
                              onTap: () {
                                _controller.clear();
                                setState(() { _result = null; _notFound = false; _hasText = false; });
                              },
                              child: const Icon(Icons.close_rounded, color: Colors.black38),
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Result Card ───────────────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> word;
  const _ResultCard({required this.word});

  @override
  Widget build(BuildContext context) {
    final synonyms = (word['synonyms'] as List?)?.cast<String>() ?? [];
    final antonyms = (word['antonyms'] as List?)?.cast<String>() ?? [];
    final fusha = (word['fusha_sentences'] as List?) ?? [];
    final levantine = (word['levantine_sentences'] as List?) ?? [];
    final isLevantineDiff = word['arabic_levantine'] != word['arabic'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Arabic word header ──────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(20),
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
                            (word['english'] as String).toUpperCase(),
                            style: const TextStyle(fontSize: 11, letterSpacing: 1.2, color: Colors.black45, fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            word['transliteration'] as String,
                            style: const TextStyle(fontSize: 15, color: AppColors.primary, fontFamily: 'PlusJakartaSans', fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
                          ),
                          if (word['type'] != null) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                word['type'] as String,
                                style: const TextStyle(fontSize: 11, color: AppColors.primary, fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      word['arabic'] as String,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w700, fontFamily: 'PlusJakartaSans', color: AppColors.primary, height: 1.1),
                    ),
                  ],
                ),
                if (isLevantineDiff) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primaryBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                          child: const Text('Levantine', style: TextStyle(fontSize: 10, color: AppColors.primary, fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 10),
                        Text(word['arabic_levantine'] as String, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'PlusJakartaSans', color: Colors.black87)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            word['transliteration_levantine'] as String,
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black45, fontFamily: 'PlusJakartaSans'),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (synonyms.isNotEmpty) ...[
                  _ChipRow(label: 'Synonyms', chips: synonyms, color: AppColors.primary),
                  const SizedBox(height: 12),
                ],
                if (antonyms.isNotEmpty) ...[
                  _ChipRow(label: 'Antonyms', chips: antonyms, color: const Color(0xFF9E6B50)),
                  const SizedBox(height: 8),
                ],
                if (synonyms.isNotEmpty || antonyms.isNotEmpty) const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(),
                ),
                _SentenceSection(
                  icon: Icons.menu_book_rounded,
                  label: 'Modern Standard Arabic (Fusha)',
                  sentences: fusha.cast<Map>(),
                  accentColor: AppColors.primary,
                  bgColor: AppColors.primaryLight,
                ),
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 14),
                _SentenceSection(
                  icon: Icons.record_voice_over_rounded,
                  label: 'Jordanian Levantine',
                  sentences: levantine.cast<Map>(),
                  accentColor: const Color(0xFF7B5E3A),
                  bgColor: const Color(0xFFF7F0E8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chip Row ──────────────────────────────────────────────────────────────────

class _ChipRow extends StatelessWidget {
  final String label;
  final List<String> chips;
  final Color color;
  const _ChipRow({required this.label, required this.chips, required this.color});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('$label:', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54, fontFamily: 'PlusJakartaSans')),
        ...chips.map((c) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(c, style: TextStyle(fontSize: 12, color: color, fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w500)),
        )),
      ],
    );
  }
}

// ── Sentence Section ──────────────────────────────────────────────────────────

class _SentenceSection extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Map> sentences;
  final Color accentColor;
  final Color bgColor;
  const _SentenceSection({required this.icon, required this.label, required this.sentences, required this.accentColor, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: accentColor),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: accentColor, fontFamily: 'PlusJakartaSans')),
          ],
        ),
        const SizedBox(height: 10),
        ...sentences.map((s) => _SentenceCard(sentence: s, bgColor: bgColor, accentColor: accentColor)),
      ],
    );
  }
}

// ── Sentence Card ─────────────────────────────────────────────────────────────

class _SentenceCard extends StatelessWidget {
  final Map sentence;
  final Color bgColor;
  final Color accentColor;
  const _SentenceCard({required this.sentence, required this.bgColor, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accentColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            sentence['arabic'] as String,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'PlusJakartaSans', height: 1.5),
          ),
          const SizedBox(height: 4),
          Text(
            sentence['transliteration'] as String,
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: accentColor, fontFamily: 'PlusJakartaSans'),
          ),
          const SizedBox(height: 4),
          Text(
            sentence['english'] as String,
            style: const TextStyle(fontSize: 13, color: Colors.black54, fontFamily: 'PlusJakartaSans'),
          ),
        ],
      ),
    );
  }
}

// ── Not Found ─────────────────────────────────────────────────────────────────

class _NotFoundWidget extends StatelessWidget {
  final String query;
  const _NotFoundWidget({required this.query});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          const Text('🔍', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text('"$query" not found', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'PlusJakartaSans'), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          const Text(
            'Try another word. Dictionary currently covers 130+ common Arabic words.',
            style: TextStyle(fontSize: 13, color: Colors.black45, fontFamily: 'PlusJakartaSans', height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Hint ──────────────────────────────────────────────────────────────────────

class _HintWidget extends StatelessWidget {
  final ValueChanged<String> onSuggest;
  const _HintWidget({required this.onSuggest});

  @override
  Widget build(BuildContext context) {
    const suggestions = ['hello', 'water', 'love', 'family', 'morning', 'beautiful', 'work', 'language'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Try searching for:', style: TextStyle(fontSize: 13, color: Colors.black45, fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions.map((s) => GestureDetector(
            onTap: () => onSuggest(s),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryBorder),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
              ),
              child: Text(s, style: const TextStyle(fontSize: 13, color: Colors.black87, fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w500)),
            ),
          )).toList(),
        ),
      ],
    );
  }
}
