import 'dart:math';
import 'package:deewan_institute_app/core/app_colors.dart';
import 'package:flutter/material.dart';

class FlashcardSession extends StatefulWidget {
  final List<Map<String, dynamic>> words;
  final String difficulty;
  final Color color;
  const FlashcardSession({super.key, required this.words, required this.difficulty, required this.color});

  @override
  State<FlashcardSession> createState() => _FlashcardSessionState();
}

class _FlashcardSessionState extends State<FlashcardSession> with SingleTickerProviderStateMixin {
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;
  int _currentIndex = 0;
  int _knownCount = 0;
  bool _isFlipped = false;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _flipAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  void _flip() {
    if (_isFlipped) {
      _flipCtrl.reverse();
    } else {
      _flipCtrl.forward();
    }
    setState(() => _isFlipped = !_isFlipped);
  }

  void _answer(bool known) {
    if (known) setState(() => _knownCount++);
    if (_currentIndex + 1 >= widget.words.length) {
      setState(() => _isFinished = true);
    } else {
      _flipCtrl.reset();
      setState(() {
        _currentIndex++;
        _isFlipped = false;
      });
    }
  }

  void _restart() {
    _flipCtrl.reset();
    setState(() {
      _currentIndex = 0;
      _knownCount = 0;
      _isFlipped = false;
      _isFinished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isFinished) return _buildFinishScreen(context);
    final word = widget.words[_currentIndex];
    final total = widget.words.length;
    final progress = (_currentIndex) / total;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F2),
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${widget.difficulty} · ${_currentIndex + 1} / $total',
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'PlusJakartaSans'),
                          ),
                        ),
                        Text(
                          '$_knownCount known',
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, fontFamily: 'PlusJakartaSans'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white.withOpacity(0.25),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Card ────────────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Column(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _flip,
                      child: AnimatedBuilder(
                        animation: _flipAnim,
                        builder: (ctx, _) {
                          final angle = _flipAnim.value * pi;
                          final showFront = _flipAnim.value <= 0.5;
                          return Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(angle),
                            child: showFront
                                ? _buildFront(word)
                                : Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.rotationY(pi),
                                    child: _buildBack(word),
                                  ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Tap hint or action buttons ───────────────────────────
                  if (!_isFlipped)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app_rounded, size: 16, color: Colors.black38),
                        const SizedBox(width: 6),
                        const Text('Tap card to reveal', style: TextStyle(fontSize: 13, color: Colors.black38, fontFamily: 'PlusJakartaSans')),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            label: "Don't Know",
                            icon: Icons.close_rounded,
                            color: const Color(0xFFE05C5C),
                            onTap: () => _answer(false),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            label: 'Know It',
                            icon: Icons.check_rounded,
                            color: const Color(0xFF4ECBA8),
                            onTap: () => _answer(true),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFront(Map<String, dynamic> word) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              word['type'] as String? ?? '',
              style: TextStyle(fontSize: 12, color: widget.color, fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            word['english'] as String,
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, fontFamily: 'PlusJakartaSans', color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Icon(Icons.flip_rounded, size: 20, color: Colors.black.withOpacity(0.15)),
          const SizedBox(height: 8),
          Text('tap to flip', style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.25), fontFamily: 'PlusJakartaSans')),
        ],
      ),
    );
  }

  Widget _buildBack(Map<String, dynamic> word) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [widget.color, widget.color.withOpacity(0.78)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: widget.color.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            word['arabic'] as String,
            style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'PlusJakartaSans', height: 1.1),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            word['transliteration'] as String,
            style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.85), fontFamily: 'PlusJakartaSans'),
            textAlign: TextAlign.center,
          ),
          if (word['arabic_levantine'] != null && word['arabic_levantine'] != word['arabic']) ...[
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Levantine: ', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7), fontFamily: 'PlusJakartaSans')),
                  Text(word['arabic_levantine'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'PlusJakartaSans')),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            word['english'] as String,
            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.65), fontFamily: 'PlusJakartaSans'),
          ),
        ],
      ),
    );
  }

  Widget _buildFinishScreen(BuildContext context) {
    final total = widget.words.length;
    final pct = ((_knownCount / total) * 100).round();
    final emoji = pct >= 80 ? '🏆' : pct >= 50 ? '👍' : '💪';
    final message = pct >= 80 ? 'Excellent work!' : pct >= 50 ? 'Good progress!' : 'Keep practicing!';
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F2),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('${widget.difficulty} Complete', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'PlusJakartaSans')),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 72)),
                  const SizedBox(height: 20),
                  Text(message, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, fontFamily: 'PlusJakartaSans')),
                  const SizedBox(height: 8),
                  Text(
                    'You knew $_knownCount out of $total cards ($pct%)',
                    style: const TextStyle(fontSize: 15, color: Colors.black54, fontFamily: 'PlusJakartaSans'),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),
                  // Score bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _knownCount / total,
                      backgroundColor: Colors.black.withOpacity(0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                      minHeight: 12,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.primaryBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Back', style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600, color: Colors.black87)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _restart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.color,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: const Text('Try Again', style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action Button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'PlusJakartaSans')),
          ],
        ),
      ),
    );
  }
}
