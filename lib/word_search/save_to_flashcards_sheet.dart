import 'package:deewan_institute_app/auth/login.dart';
import 'package:deewan_institute_app/core/app_colors.dart';
import 'package:deewan_institute_app/core/flashcard_service.dart';
import 'package:deewan_institute_app/flashcards/flashcards_home.dart';
import 'package:flutter/material.dart';

Future<void> showSaveToFlashcardsSheet(
  BuildContext context, {
  required Map<String, dynamic> word,
  required String wordId,
  bool levantine = false,
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
    builder: (_) => _DeckPickerSheet(word: word, wordId: wordId, levantine: levantine),
  );
}

class _DeckPickerSheet extends StatefulWidget {
  final Map<String, dynamic> word;
  final String wordId;
  final bool levantine;
  const _DeckPickerSheet({required this.word, required this.wordId, required this.levantine});

  @override
  State<_DeckPickerSheet> createState() => _DeckPickerSheetState();
}

class _DeckPickerSheetState extends State<_DeckPickerSheet> {
  String _selectedDeck = FlashcardDecks.beginner.id;
  bool _isSaving = false;

  final _nameController = TextEditingController();
  List<CustomCategory> _existingDecks = [];
  String? _nameError;

  /// The form that gets saved: Levantine when the word was viewed in Levantine.
  String get _savedArabic => FlashcardService.dialectForm(widget.word, levantine: widget.levantine).arabic;

  bool get _isCustom => _selectedDeck == FlashcardDecks.custom.id;

  @override
  void initState() {
    super.initState();
    _loadExistingDecks();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingDecks() async {
    try {
      final decks = await FlashcardService.getCustomCategories();
      if (mounted) setState(() => _existingDecks = decks);
    } catch (_) {
      // Typing a deck name still works without the quick picks.
    }
  }

  /// Reuses an existing deck's exact spelling when the typed name matches it
  /// ignoring case, so "food" and "Food" don't become two different decks.
  String _resolvedDeckName() {
    final typed = _nameController.text.trim();
    for (final deck in _existingDecks) {
      if (deck.name.toLowerCase() == typed.toLowerCase()) return deck.name;
    }
    return typed;
  }

  Future<void> _save() async {
    String? deckName;
    if (_isCustom) {
      deckName = _resolvedDeckName();
      if (deckName.isEmpty) {
        setState(() => _nameError = 'Give your flashcard deck a name');
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final count = await FlashcardService.saveWord(
        wordId: widget.wordId,
        word: widget.word,
        deckId: _selectedDeck,
        category: deckName,
        levantine: widget.levantine,
      );
      if (!mounted) return;
      final deckLabel = deckName ?? FlashcardDecks.byId(_selectedDeck).label;
      Navigator.pop(context);
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _SavedConfirmationSheet(
          arabic: _savedArabic,
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
    final arabic = _savedArabic;
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
              onTap: () => setState(() {
                _selectedDeck = deck.id;
                _nameError = null;
              }),
            ),
          ),
          if (_isCustom) ...[
            const SizedBox(height: 16),
            const Text(
              'Name your flashcard deck',
              style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 15, color: AppColors.ink),
              onChanged: (_) => setState(() => _nameError = null),
              decoration: InputDecoration(
                hintText: 'e.g. Food, Travel, Family',
                hintStyle: const TextStyle(fontFamily: 'Inter', color: AppColors.muted, fontSize: 14),
                errorText: _nameError,
                filled: true,
                fillColor: AppColors.cream,
                prefixIcon: const Icon(Icons.folder_outlined, color: AppColors.muted),
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(50), borderSide: const BorderSide(color: AppColors.primaryBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(50), borderSide: const BorderSide(color: AppColors.primaryBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(50), borderSide: const BorderSide(color: AppColors.green, width: 1.5)),
                errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(50), borderSide: const BorderSide(color: AppColors.coral)),
                focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(50), borderSide: const BorderSide(color: AppColors.coral, width: 1.5)),
              ),
            ),
            if (_existingDecks.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Or add it to one of your decks:',
                style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final deck in _existingDecks)
                    _DeckNameChip(
                      label: deck.name,
                      selected: _nameController.text.trim().toLowerCase() == deck.name.toLowerCase(),
                      onTap: () => setState(() {
                        _nameController.text = deck.name;
                        _nameError = null;
                      }),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            const Text(
              'The Arabic, pronunciation and example sentence are filled in from the dictionary.',
              style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.muted, height: 1.4),
            ),
          ],
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

class _DeckNameChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _DeckNameChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.green : Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: selected ? AppColors.green : AppColors.primaryBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.ink,
          ),
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
      // Lift the sheet above the keyboard and let it scroll when the deck-name
      // field makes it taller than the space left.
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: SafeArea(top: false, child: SingleChildScrollView(child: child)),
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
