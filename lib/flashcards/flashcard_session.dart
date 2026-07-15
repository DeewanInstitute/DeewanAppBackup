import 'dart:math';

import 'package:deewan_institute_app/core/app_bottom_nav.dart';
import 'package:deewan_institute_app/core/app_colors.dart';
import 'package:deewan_institute_app/core/app_drawer.dart';
import 'package:deewan_institute_app/core/app_loading.dart';
import 'package:deewan_institute_app/core/app_top_nav.dart';
import 'package:deewan_institute_app/core/flashcard_service.dart';
import 'package:deewan_institute_app/flashcards/flashcards_home.dart';
import 'package:deewan_institute_app/flashcards/review_incorrect_page.dart';
import 'package:deewan_institute_app/word_search/word_search_page.dart';
import 'package:flutter/material.dart';

class FlashcardSession extends StatefulWidget {
  final List<Map<String, dynamic>> words;
  final String difficulty;
  final Color color;

  /// When true, this is a "review the ones you got wrong" session: button
  /// labels change to "Still Wrong", both answers advance to the next card
  /// (rather than "Again" holding you on the same card), and answering
  /// "Got it!" removes the card from the persisted incorrect list.
  final bool isReviewMode;

  const FlashcardSession({
    super.key,
    required this.words,
    required this.difficulty,
    required this.color,
    this.isReviewMode = false,
  });

  @override
  State<FlashcardSession> createState() => _FlashcardSessionState();
}

class _FlashcardSessionState extends State<FlashcardSession> with SingleTickerProviderStateMixin {
  late final AnimationController _flipCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  late final Animation<double> _flipAnim = CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut);

  int _currentIndex = 0;
  int _knownCount = 0;
  int _incorrectCount = 0;
  bool _isFlipped = false;
  bool _isFinished = false;

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _word => widget.words[_currentIndex];

  Map<String, String>? get _example => FlashcardService.extractExample(_word);

  void _flip() {
    if (_isFlipped) {
      _flipCtrl.reverse();
    } else {
      _flipCtrl.forward();
    }
    setState(() => _isFlipped = !_isFlipped);
  }

  void _resetFlip() {
    _flipCtrl.reset();
    _isFlipped = false;
  }

  void _goTo(int index) {
    if (index < 0 || index >= widget.words.length) return;
    setState(() {
      _currentIndex = index;
      _resetFlip();
    });
  }

  void _advance() {
    if (_currentIndex + 1 >= widget.words.length) {
      setState(() => _isFinished = true);
    } else {
      setState(() {
        _currentIndex++;
        _resetFlip();
      });
    }
  }

  Future<void> _gotIt() async {
    setState(() => _knownCount++);
    if (widget.isReviewMode) {
      await FlashcardService.removeIncorrect(FlashcardService.wordKeyOf(_word));
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CorrectSheet(),
    );
    if (mounted) _advance();
  }

  Future<void> _again() async {
    if (!widget.isReviewMode) {
      setState(() => _incorrectCount++);
      await FlashcardService.markIncorrect(_word);
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotQuiteSheet(
        arabic: _word['arabic'] as String? ?? '',
        transliteration: _word['transliteration'] as String? ?? '',
        isReviewMode: widget.isReviewMode,
      ),
    );
    if (mounted && widget.isReviewMode) _advance();
  }

  void _restart() {
    setState(() {
      _currentIndex = 0;
      _knownCount = 0;
      _incorrectCount = 0;
      _isFinished = false;
      _resetFlip();
    });
  }

  void _goHome() => Navigator.popUntil(context, (route) => route.isFirst);

  void _openSearch() => AppLoading.navigate(context, const WordSearchPage());

  void _openReviewIncorrect() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewIncorrectPage()));
  }

  void _backToFlashcardsHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const FlashcardsHome()),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isFinished) {
      return widget.isReviewMode ? _buildReviewFinishScreen(context) : _buildFinishScreen(context);
    }
    final total = widget.words.length;
    final progress = (_currentIndex + 1) / total;

    return Scaffold(
      backgroundColor: AppColors.cream,
      drawer: const AppDrawer(),
      bottomNavigationBar: AppBottomNav(
        currentIndex: widget.isReviewMode ? 2 : -1,
        onTap: (i) {
          if (widget.isReviewMode && i == 2) return;
          if (i == 0) _goHome();
          if (i == 1) _openSearch();
          if (i == 2) _openReviewIncorrect();
        },
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppTopNav(),
              const SizedBox(height: 20),
              if (widget.isReviewMode)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.coral.withOpacity(0.1), borderRadius: BorderRadius.circular(50)),
                    child: Text(
                      '${_currentIndex + 1} of $total incorrect',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.coral),
                    ),
                  ),
                )
              else ...[
                Text(
                  '${_currentIndex + 1} of $total',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
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
              ],
              const SizedBox(height: 20),
              Expanded(
                child: GestureDetector(
                  onTap: _flip,
                  child: AnimatedBuilder(
                    animation: _flipAnim,
                    builder: (context, _) {
                      final angle = _flipAnim.value * pi;
                      final showFront = _flipAnim.value <= 0.5;
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(angle),
                        child: showFront
                            ? _buildFront()
                            : Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.rotationY(pi),
                                child: _buildBack(),
                              ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RoundIconButton(icon: Icons.arrow_back_rounded, enabled: _currentIndex > 0, onTap: () => _goTo(_currentIndex - 1)),
                  const SizedBox(width: 24),
                  _RoundIconButton(
                    icon: Icons.arrow_forward_rounded,
                    enabled: _currentIndex < total - 1,
                    onTap: () => _goTo(_currentIndex + 1),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (!_isFlipped) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.touch_app_rounded, size: 16, color: AppColors.muted),
                    const SizedBox(width: 6),
                    Text(
                      widget.isReviewMode ? 'Tap to reveal answer' : 'Tap card to reveal',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.muted),
                    ),
                  ],
                ),
                if (widget.isReviewMode) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _flip,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                        elevation: 0,
                        textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      child: const Text('Reveal Answer'),
                    ),
                  ),
                ],
              ] else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _again,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppColors.coral),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                        ),
                        child: Text(
                          widget.isReviewMode ? 'Still Wrong' : 'Again',
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.coral),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _gotIt,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                          elevation: 0,
                          textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        child: const Text('Got it!'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFront() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isReviewMode) ...[
              Text(
                _word['arabic'] as String? ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, fontFamily: 'Inter', color: AppColors.ink),
              ),
              const SizedBox(height: 8),
              if (_word['transliteration'] != null)
                Text(
                  _word['transliteration'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.orange, fontFamily: 'Inter'),
                ),
              const SizedBox(height: 16),
              _SpeakerButton(color: AppColors.orange, size: 36),
            ] else ...[
              Text(
                _word['english'] as String? ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, fontFamily: 'Inter', color: AppColors.ink),
              ),
              const SizedBox(height: 28),
              Icon(Icons.flip_camera_android_outlined, size: 20, color: AppColors.muted.withOpacity(0.6)),
              const SizedBox(height: 8),
              Text('tap to flip', style: TextStyle(fontSize: 12, color: AppColors.muted.withOpacity(0.8), fontFamily: 'Inter')),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBack() {
    final example = _example;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: SingleChildScrollView(
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              child: _SpeakerButton(color: AppColors.orange),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 52),
                    child: Column(
                      children: [
                        Text(
                          _word['arabic'] as String? ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700, fontFamily: 'Inter', color: AppColors.ink),
                        ),
                        const SizedBox(height: 6),
                        if (_word['transliteration'] != null)
                          Text(
                            _word['transliteration'] as String,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: AppColors.muted, fontFamily: 'Inter'),
                          ),
                        const SizedBox(height: 6),
                        Text(
                          _word['english'] as String? ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.green, fontFamily: 'Inter'),
                        ),
                      ],
                    ),
                  ),
                  if (example != null) ...[
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.primaryBorder),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'EXAMPLE',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.green, letterSpacing: 0.5),
                        ),
                        _SpeakerButton(color: AppColors.green, size: 32),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      example['arabic']!,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'Inter', color: AppColors.ink, height: 1.4),
                    ),
                    if (example['transliteration']!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        example['transliteration']!,
                        style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.muted, fontFamily: 'Inter'),
                      ),
                    ],
                    if (example['english']!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        example['english']!,
                        style: const TextStyle(fontSize: 14, color: AppColors.ink, fontFamily: 'Inter'),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinishScreen(BuildContext context) {
    final total = widget.words.length;
    final pct = total == 0 ? 0 : ((_knownCount / total) * 100).round();
    return Scaffold(
      backgroundColor: AppColors.cream,
      drawer: const AppDrawer(),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onTap: (i) {
          if (i == 0) return;
          if (i == 1) _openSearch();
          if (i == 2) _openReviewIncorrect();
        },
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppTopNav(),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Session Complete!',
                        style: TextStyle(fontFamily: 'Prociono', fontSize: 30, color: AppColors.ink),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "You've finished all $total cards!",
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
                            Expanded(child: _StatColumn(icon: Icons.check_rounded, color: AppColors.green, value: '$_knownCount', label: 'Correct')),
                            const SizedBox(height: 40, child: VerticalDivider(color: AppColors.primaryBorder)),
                            Expanded(child: _StatColumn(icon: Icons.close_rounded, color: AppColors.coral, value: '$_incorrectCount', label: 'Incorrect')),
                            const SizedBox(height: 40, child: VerticalDivider(color: AppColors.primaryBorder)),
                            Expanded(child: _StatColumn(icon: Icons.show_chart_rounded, color: AppColors.orange, value: '$pct%', label: 'Score')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_incorrectCount > 0) ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _openReviewIncorrect,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: AppColors.coral),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                            ),
                            child: Text(
                              'Review Incorrect ($_incorrectCount)',
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.coral),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _backToFlashcardsHome,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                            elevation: 0,
                            textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          child: const Text('Back to Flashcards'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewFinishScreen(BuildContext context) {
    final total = widget.words.length;
    final mastered = _knownCount;
    final stillPracticing = total - mastered;
    return Scaffold(
      backgroundColor: AppColors.cream,
      drawer: const AppDrawer(),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onTap: (i) {
          if (i == 0) return;
          if (i == 1) _openSearch();
          if (i == 2) _openReviewIncorrect();
        },
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppTopNav(),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('✨ ⭐ ✨', style: TextStyle(fontSize: 20)),
                      const SizedBox(height: 8),
                      const Text(
                        'Review Complete!',
                        style: TextStyle(fontFamily: 'Prociono', fontSize: 30, color: AppColors.green),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'You reviewed all incorrect cards',
                        style: TextStyle(fontSize: 14, color: AppColors.muted, fontFamily: 'Inter'),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: AppColors.orange, borderRadius: BorderRadius.circular(50)),
                        child: const Text(
                          '+20 XP',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 6))],
                        ),
                        child: Column(
                          children: [
                            _ReviewStatRow(icon: Icons.check_rounded, color: AppColors.green, label: 'Mastered', value: '$mastered cards'),
                            const Divider(color: AppColors.primaryBorder),
                            _ReviewStatRow(icon: Icons.close_rounded, color: AppColors.coral, label: 'Still Practicing', value: '$stillPracticing card${stillPracticing == 1 ? '' : 's'}'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _restart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                            elevation: 0,
                            textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          child: const Text('Practice Again'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _backToFlashcardsHome,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: AppColors.green),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                          ),
                          child: const Text(
                            'Back to Flashcards',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.green),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stat Widgets ──────────────────────────────────────────────────────────────

class _StatColumn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  const _StatColumn({required this.icon, required this.color, required this.value, required this.label});

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

class _ReviewStatRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _ReviewStatRow({required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.12)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.ink)),
          const Spacer(),
          Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

// ── Speaker Button ────────────────────────────────────────────────────────────

class _SpeakerButton extends StatelessWidget {
  final Color color;
  final double size;
  const _SpeakerButton({required this.color, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio pronunciation coming soon.')),
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        child: Icon(Icons.volume_up_rounded, color: Colors.white, size: size * 0.5),
      ),
    );
  }
}

// ── Round Prev/Next Button ────────────────────────────────────────────────────

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: AppColors.primaryBorder)),
        child: Icon(icon, color: enabled ? AppColors.ink : AppColors.primaryBorder, size: 20),
      ),
    );
  }
}

// ── Correct Sheet ─────────────────────────────────────────────────────────────

class _CorrectSheet extends StatelessWidget {
  const _CorrectSheet();

  @override
  Widget build(BuildContext context) {
    return _SessionSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.green),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 30),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Correct!',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Prociono', fontSize: 26, color: AppColors.green),
          ),
          const SizedBox(height: 6),
          const Text(
            'Great job! Keep it up.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: AppColors.green.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: AppColors.green, size: 16),
                  const SizedBox(width: 4),
                  const Text(
                    '+10 XP',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.green),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Next Card'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Not Quite Sheet ───────────────────────────────────────────────────────────

class _NotQuiteSheet extends StatelessWidget {
  final String arabic;
  final String transliteration;
  final bool isReviewMode;
  const _NotQuiteSheet({required this.arabic, required this.transliteration, required this.isReviewMode});

  @override
  Widget build(BuildContext context) {
    return _SessionSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.coral),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Not quite!',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Prociono', fontSize: 26, color: AppColors.coral),
          ),
          const SizedBox(height: 6),
          Text(
            isReviewMode ? "This one still needs practice." : "Don't worry, practice makes perfect.",
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.muted),
          ),
          const SizedBox(height: 20),
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
                Text.rich(
                  TextSpan(
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
                    children: [
                      TextSpan(text: arabic),
                      if (transliteration.isNotEmpty)
                        TextSpan(
                          text: '  —  $transliteration',
                          style: const TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.w400, color: AppColors.muted),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: Icon(isReviewMode ? Icons.arrow_forward_rounded : Icons.refresh_rounded, size: 18),
              label: Text(isReviewMode ? 'Next Card' : 'Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.coral,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionSheet extends StatelessWidget {
  final Widget child;
  const _SessionSheet({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.primaryBorder, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}
