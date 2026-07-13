import 'package:deewan_institute_app/auth/login.dart';
import 'package:deewan_institute_app/core/app_colors.dart';
import 'package:deewan_institute_app/core/flashcard_service.dart';
import 'package:deewan_institute_app/flashcards/flashcards_home.dart';
import 'package:flutter/material.dart';

Future<void> showSaveToFlashcardsSheet(
  BuildContext context, {
  required Map<String, dynamic> word,
  required String wordId,
}) async {
  if (!FlashcardService.isSignedIn) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Log in to save words to your flashcards.')),
    );
    Navigator.push(context, MaterialPageRoute(builder: (_) => const Login()));
    return;
  }

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DeckPickerSheet(word: word, wordId: wordId),
  );
}

class _DeckPickerSheet extends StatefulWidget {
  final Map<String, dynamic> word;
  final String wordId;
  const _DeckPickerSheet({required this.word, required this.wordId});

  @override
  State<_DeckPickerSheet> createState() => _DeckPickerSheetState();
}

class _DeckPickerSheetState extends State<_DeckPickerSheet> {
  String _selectedDeck = FlashcardDecks.beginner.id;
  bool _isSaving = false;

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final count = await FlashcardService.saveWord(
        wordId: widget.wordId,
        word: widget.word,
        deckId: _selectedDeck,
      );
      if (!mounted) return;
      final deckLabel = FlashcardDecks.byId(_selectedDeck).label;
      Navigator.pop(context);
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _SavedConfirmationSheet(
          arabic: widget.word['arabic'] as String? ?? '',
          deckLabel: deckLabel,
          cardCount: count,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final arabic = widget.word['arabic'] as String? ?? '';
    return _SheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SheetHandle(),
          const SizedBox(height: 20),
          const Center(child: _SheetIcon(icon: Icons.bookmark_rounded, color: AppColors.green)),
          const SizedBox(height: 16),
          const Text(
            'Save to Flashcards',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.muted),
              children: [
                const TextSpan(text: 'Choose which deck to save "'),
                TextSpan(text: arabic, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                const TextSpan(text: '" to:'),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ...FlashcardDecks.all.map(
            (deck) => _DeckOption(
              label: deck.label,
              selected: _selectedDeck == deck.id,
              onTap: () => setState(() => _selectedDeck = deck.id),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600),
              ),
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.muted, decoration: TextDecoration.underline),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedConfirmationSheet extends StatelessWidget {
  final String arabic;
  final String deckLabel;
  final int cardCount;
  const _SavedConfirmationSheet({required this.arabic, required this.deckLabel, required this.cardCount});

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SheetHandle(),
          const SizedBox(height: 24),
          const Center(child: _SheetIcon(icon: Icons.check_rounded, color: AppColors.green)),
          const SizedBox(height: 16),
          const Text(
            'Saved!',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.green),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.ink),
              children: [
                TextSpan(text: '$arabic has been added to your '),
                TextSpan(text: deckLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
                const TextSpan(text: ' deck.'),
              ],
            ),
            textAlign: TextAlign.center,
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
              child: Text(
                '$cardCount CARDS',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.green),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const FlashcardsHome()));
              },
              child: const Text('Go to Flashcards'),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Text(
                'Continue Searching',
                style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.muted, decoration: TextDecoration.underline),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeckOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _DeckOption({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF0EDE8)))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 15, color: AppColors.ink)),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? AppColors.green : AppColors.primaryBorder, width: 2),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.green),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetShell extends StatelessWidget {
  final Widget child;
  const _SheetShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: SafeArea(top: false, child: child),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(color: AppColors.primaryBorder, borderRadius: BorderRadius.circular(2)),
      ),
    );
  }
}

class _SheetIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _SheetIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: Icon(icon, color: Colors.white, size: 30),
    );
  }
}
