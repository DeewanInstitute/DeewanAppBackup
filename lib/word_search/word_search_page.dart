import 'dart:convert';
import 'package:deewan_institute_app/core/app_bottom_nav.dart';
import 'package:deewan_institute_app/core/app_colors.dart';
import 'package:deewan_institute_app/core/app_drawer.dart';
import 'package:deewan_institute_app/core/app_loading.dart';
import 'package:deewan_institute_app/core/app_top_nav.dart';
import 'package:deewan_institute_app/podcasts/podcast_home.dart';
import 'package:deewan_institute_app/word_search/save_to_flashcards_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum _Dialect { fusha, levantine }

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
  _Dialect _dialect = _Dialect.fusha;

  @override
  void initState() {
    super.initState();
    _loadDictionary();
  }

  Future<void> _loadDictionary() async {
    final raw = await rootBundle.loadString(
      'assets/data/arabic_dictionary.json',
    );
    final list = jsonDecode(raw) as List;
    if (mounted)
      setState(() => _dictionary = list.cast<Map<String, dynamic>>());
  }

  void _search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() {
        _result = null;
        _notFound = false;
      });
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
      backgroundColor: AppColors.cream,
      extendBody: true,
      drawer: const AppDrawer(),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppTopNav(),
              const SizedBox(height: 24),
              _buildSearchField(),
              const SizedBox(height: 16),
              _buildDialectToggle(),
              const SizedBox(height: 20),
              if (_result != null) ...[
                Text(
                  'Results for "${_controller.text.trim()}" in ${_dialect == _Dialect.fusha ? 'Fusha' : 'Levantine'}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 12),
                _ResultCard(word: _result!, dialect: _dialect),
              ] else if (_notFound)
                _NotFoundWidget(query: _controller.text.trim())
              else
                _HintWidget(
                  onSuggest: (w) {
                    _controller.text = w;
                    setState(() => _hasText = true);
                    _search(w);
                  },
                ),
            ],
          ),
        ),
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

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.orange.withOpacity(0.4)),
      ),
      child: TextField(
        controller: _controller,
        textInputAction: TextInputAction.search,
        onSubmitted: _search,
        onChanged: (v) => setState(() => _hasText = v.trim().isNotEmpty),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          color: AppColors.ink,
        ),
        decoration: InputDecoration(
          hintText: 'e.g. water, love, morning...',
          hintStyle: const TextStyle(
            fontFamily: 'Inter',
            color: AppColors.muted,
            fontSize: 14,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 20,
          ),
          suffixIconConstraints: const BoxConstraints(minWidth: 0),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                  GestureDetector(
                    onTap: () {
                      _controller.clear();
                      setState(() {
                        _result = null;
                        _notFound = false;
                        _hasText = false;
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        Icons.close_rounded,
                        color: AppColors.muted,
                        size: 20,
                      ),
                    ),
                  ),
                GestureDetector(
                  onTap: () => _search(_controller.text),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.search,
                      color: AppColors.orange,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialectToggle() {
    return Row(
      children: [
        _DialectChip(
          label: 'Fusha',
          selected: _dialect == _Dialect.fusha,
          onTap: () => setState(() => _dialect = _Dialect.fusha),
        ),
        const SizedBox(width: 10),
        _DialectChip(
          label: 'Levantine',
          selected: _dialect == _Dialect.levantine,
          onTap: () => setState(() => _dialect = _Dialect.levantine),
        ),
      ],
    );
  }
}

// ── Dialect Chip ──────────────────────────────────────────────────────────────

class _DialectChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _DialectChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.green : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: selected ? AppColors.green : AppColors.coral,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.coral,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Result Card ───────────────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> word;
  final _Dialect dialect;
  const _ResultCard({required this.word, required this.dialect});

  bool get _isFusha => dialect == _Dialect.fusha;

  @override
  Widget build(BuildContext context) {
    final arabic =
        (_isFusha ? word['arabic'] : word['arabic_levantine']) as String? ?? '';
    final translit =
        (_isFusha ? word['transliteration'] : word['transliteration_levantine'])
            as String? ??
        '';
    final sentences =
        ((_isFusha ? word['fusha_sentences'] : word['levantine_sentences'])
                as List?)
            ?.cast<Map>() ??
        [];
    final synonyms = (word['synonyms'] as List?)?.cast<String>() ?? [];
    final antonyms = (word['antonyms'] as List?)?.cast<String>() ?? [];
    final english = word['english'] as String? ?? '';
    final wordId = english.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '_');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              arabic,
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              translit,
              style: const TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: AppColors.muted,
                fontFamily: 'Inter',
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (word['type'] != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          (word['type'] as String).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.green,
                            fontFamily: 'Inter',
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    Text(
                      english.isEmpty
                          ? english
                          : english[0].toUpperCase() + english.substring(1),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Audio pronunciation coming soon.'),
                  ),
                ),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.orange,
                  ),
                  child: const Icon(
                    Icons.volume_up_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          if (sentences.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Example Sentences',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.green,
              ),
            ),
            const SizedBox(height: 12),
            ...sentences.map((s) => _SentenceCard(sentence: s)),
          ],
          if (synonyms.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Synonyms',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.green,
              ),
            ),
            const SizedBox(height: 8),
            _ChipRow(chips: synonyms, color: AppColors.green),
          ],
          if (antonyms.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Antonyms',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.coral,
              ),
            ),
            const SizedBox(height: 8),
            _ChipRow(chips: antonyms, color: AppColors.coral),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => showSaveToFlashcardsSheet(
                context,
                word: word,
                wordId: wordId,
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Save to Flashcards'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sentence Card ─────────────────────────────────────────────────────────────

class _SentenceCard extends StatelessWidget {
  final Map sentence;
  const _SentenceCard({required this.sentence});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sentence['arabic'] as String,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                    color: AppColors.ink,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sentence['transliteration'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.muted,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sentence['english'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.ink,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Audio pronunciation coming soon.')),
            ),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.volume_up_rounded,
                color: AppColors.orange,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chip Row ──────────────────────────────────────────────────────────────────

class _ChipRow extends StatelessWidget {
  final List<String> chips;
  final Color color;
  const _ChipRow({required this.chips, required this.color});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips
          .map(
            (c) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Text(
                c,
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
          .toList(),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text('🔍', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            '"$query" not found',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
              color: AppColors.ink,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Try another word. Dictionary currently covers 130+ common Arabic words.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.muted,
              fontFamily: 'Inter',
              height: 1.4,
            ),
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
    const suggestions = [
      'hello',
      'water',
      'love',
      'family',
      'morning',
      'beautiful',
      'work',
      'language',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Try searching for:',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.muted,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions
              .map(
                (s) => GestureDetector(
                  onTap: () => onSuggest(s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primaryBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Text(
                      s,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.ink,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
