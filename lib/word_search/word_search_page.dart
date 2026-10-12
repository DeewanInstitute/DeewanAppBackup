import 'package:deewan_institute_app/core/app_bottom_nav.dart';
import 'package:deewan_institute_app/core/app_colors.dart';
import 'package:deewan_institute_app/core/app_drawer.dart';
import 'package:deewan_institute_app/core/app_top_nav.dart';
import 'package:deewan_institute_app/core/audio_service.dart';
import 'package:deewan_institute_app/core/dictionary_repository.dart';
import 'package:deewan_institute_app/core/gender_forms.dart';
import 'package:deewan_institute_app/core/speaker_button.dart';
import 'package:deewan_institute_app/flashcards/review_incorrect_page.dart';
import 'package:deewan_institute_app/word_search/save_to_flashcards_sheet.dart';
import 'package:deewan_institute_app/word_search/word_details_page.dart';
import 'package:flutter/material.dart';

enum _Dialect { fusha, levantine }

class WordSearchPage extends StatefulWidget {
  final String? initialQuery;

  /// Opens with the Levantine toggle selected (the home page passes its choice).
  final bool initialLevantine;
  const WordSearchPage({super.key, this.initialQuery, this.initialLevantine = false});

  @override
  State<WordSearchPage> createState() => _WordSearchPageState();
}

class _WordSearchPageState extends State<WordSearchPage> {
  late final _controller = TextEditingController(text: widget.initialQuery ?? '');
  List<Map<String, dynamic>> _dictionary = [];
  Map<String, dynamic>? _result;
  bool _notFound = false;
  bool _hasText = false;
  bool _isLoadingDictionary = true;
  bool _loadFailed = false;
  bool _isSearching = false;
  late _Dialect _dialect = widget.initialLevantine ? _Dialect.levantine : _Dialect.fusha;

  @override
  void initState() {
    super.initState();
    _hasText = (widget.initialQuery ?? '').trim().isNotEmpty;
    _loadDictionary();
  }

  Future<void> _loadDictionary() async {
    setState(() {
      _isLoadingDictionary = true;
      _loadFailed = false;
    });
    try {
      final list = await DictionaryRepository.load();
      if (!mounted) return;
      setState(() {
        _dictionary = list;
        _isLoadingDictionary = false;
      });
      if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
        _search(widget.initialQuery!);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingDictionary = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _search(String query) async {
    if (_isLoadingDictionary || _loadFailed) return;
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
    if (match.isNotEmpty) {
      setState(() {
        _result = match;
        _notFound = false;
      });
      return;
    }

    if (!DictionaryRepository.isSignedIn) {
      setState(() {
        _result = null;
        _notFound = true;
      });
      return;
    }

    setState(() {
      _result = null;
      _notFound = false;
      _isSearching = true;
    });
    try {
      final entry = await DictionaryRepository.lookupWithAi(query);
      if (!mounted) return;
      setState(() {
        _result = entry;
        _notFound = false;
        _isSearching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _result = null;
        _notFound = true;
        _isSearching = false;
      });
    }
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
              if (_isLoadingDictionary)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: CircularProgressIndicator(color: AppColors.green)),
                )
              else if (_loadFailed)
                _LoadErrorWidget(onRetry: _loadDictionary)
              else if (_isSearching)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: CircularProgressIndicator(color: AppColors.green)),
                )
              else if (_result != null) ...[
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
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewIncorrectPage()));
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

// ── Gender forms ──────────────────────────────────────────────────────────────

class _GenderTag extends StatelessWidget {
  final String label;
  final Color color;
  const _GenderTag({required this.label, this.color = AppColors.green});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.5),
      ),
    );
  }
}

class _FeminineFormCard extends StatelessWidget {
  final String arabic;
  final String? transliteration;
  final AudioDialect dialect;
  const _FeminineFormCard({required this.arabic, required this.transliteration, required this.dialect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.coral.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.coral.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _GenderTag(label: 'FEMININE', color: AppColors.coral),
                const SizedBox(height: 8),
                Text(
                  arabic,
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, fontFamily: 'Inter', color: AppColors.ink),
                ),
                if (transliteration != null && transliteration!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    transliteration!,
                    style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: AppColors.muted, fontFamily: 'Inter'),
                  ),
                ],
              ],
            ),
          ),
          SpeakerButton(text: arabic, dialect: dialect, size: 44, iconSize: 20),
        ],
      ),
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

  AudioDialect get _audioDialect => _isFusha ? AudioDialect.fusha : AudioDialect.levantine;

  @override
  Widget build(BuildContext context) {
    final feminine = GenderForms.feminineOf(word, levantine: !_isFusha);
    // Verbs show their masculine straight from the conjugation table, the same
    // table the feminine form comes from, so the pair always matches.
    final masculine = feminine == null ? null : GenderForms.masculineOf(word, levantine: !_isFusha);
    final arabic = masculine?.arabic ??
        (_isFusha ? word['arabic'] : word['arabic_levantine']) as String? ??
        '';
    final translit = masculine?.transliteration ??
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
          if (feminine != null) ...[
            const Center(child: _GenderTag(label: 'MASCULINE')),
            const SizedBox(height: 8),
          ],
          Center(
            child: Text(
              arabic,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
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
              SpeakerButton(
                text: arabic,
                dialect: _audioDialect,
                size: 48,
                iconSize: 22,
              ),
            ],
          ),
          if (feminine != null) ...[
            const SizedBox(height: 18),
            _FeminineFormCard(
              arabic: feminine.arabic,
              transliteration: feminine.transliteration,
              dialect: _audioDialect,
            ),
          ],
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
            ...sentences.map((s) => _SentenceCard(sentence: s, dialect: _audioDialect)),
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
                levantine: !_isFusha,
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
          if (word['root_family'] != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => WordDetailsPage(word: word)),),
                icon: const Icon(Icons.account_tree_outlined, size: 18),
                label: const Text('View Root & Conjugations'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.green,
                  side: const BorderSide(color: AppColors.green),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Sentence Card ─────────────────────────────────────────────────────────────

class _SentenceCard extends StatelessWidget {
  final Map sentence;
  final AudioDialect dialect;
  const _SentenceCard({required this.sentence, required this.dialect});

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
                  textDirection: TextDirection.rtl,
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
          SpeakerButton(
            text: sentence['arabic'] as String? ?? '',
            dialect: dialect,
            size: 28,
            iconSize: 16,
            backgroundColor: AppColors.orange.withOpacity(0.12),
            iconColor: AppColors.orange,
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
              padding: const EdgeInsets.fromLTRB(12, 4, 6, 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    c,
                    style: TextStyle(
                      fontSize: 13,
                      color: color,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Synonyms/antonyms are a single Fusha list, not split by dialect.
                  SpeakerButton(
                    text: c,
                    size: 22,
                    iconSize: 13,
                    backgroundColor: color.withOpacity(0.12),
                    iconColor: color,
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

// ── Load Error ────────────────────────────────────────────────────────────────

class _LoadErrorWidget extends StatelessWidget {
  final VoidCallback onRetry;
  const _LoadErrorWidget({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.coral, size: 36),
          const SizedBox(height: 12),
          const Text(
            "Couldn't load the dictionary",
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
            "It's not in the dictionary yet. Try a different word or spelling.",
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
