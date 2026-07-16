import 'package:deewan_institute_app/auth/auth_widgets.dart';
import 'package:deewan_institute_app/auth/login.dart';
import 'package:deewan_institute_app/core/app_colors.dart';
import 'package:deewan_institute_app/core/flashcard_service.dart';
import 'package:flutter/material.dart';

/// Shows the create-custom-card sheet. Returns true if a card was created,
/// so the caller can refresh its deck count.
Future<bool> showCreateCustomCardSheet(BuildContext context) async {
  if (!FlashcardService.isSignedIn) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Log in to create your own flashcards.')),
    );
    Navigator.push(context, MaterialPageRoute(builder: (_) => const Login()));
    return false;
  }

  final created = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _CreateCustomCardSheet(),
  );
  return created ?? false;
}

class _CreateCustomCardSheet extends StatefulWidget {
  const _CreateCustomCardSheet();

  @override
  State<_CreateCustomCardSheet> createState() => _CreateCustomCardSheetState();
}

class _CreateCustomCardSheetState extends State<_CreateCustomCardSheet> {
  final _formKey = GlobalKey<FormState>();
  final _categoryController = TextEditingController();
  final _englishController = TextEditingController();
  final _arabicController = TextEditingController();
  final _transliterationController = TextEditingController();
  final _exampleArabicController = TextEditingController();
  final _exampleTransliterationController = TextEditingController();
  final _exampleEnglishController = TextEditingController();
  bool _showExample = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _categoryController.dispose();
    _englishController.dispose();
    _arabicController.dispose();
    _transliterationController.dispose();
    _exampleArabicController.dispose();
    _exampleTransliterationController.dispose();
    _exampleEnglishController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await FlashcardService.createCustomCard(
        english: _englishController.text.trim(),
        arabic: _arabicController.text.trim(),
        category: _categoryController.text.trim(),
        transliteration: _transliterationController.text.trim(),
        exampleArabic: _exampleArabicController.text.trim(),
        exampleTransliteration: _exampleTransliterationController.text.trim(),
        exampleEnglish: _exampleEnglishController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
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
    return Container(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: AppColors.primaryBorder, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Create Custom Card',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Add your own word to study',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.muted),
                ),
                const SizedBox(height: 20),
                Text('Category', style: authLabelStyle),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _categoryController,
                  decoration: authFieldDecoration(hint: 'e.g. Food, Travel, Family', icon: Icons.folder_outlined),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Category is required' : null,
                ),
                const SizedBox(height: 16),
                Text('English Word', style: authLabelStyle),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _englishController,
                  decoration: authFieldDecoration(hint: 'e.g. friendship', icon: Icons.translate_rounded),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'English word is required' : null,
                ),
                const SizedBox(height: 16),
                Text('Arabic Translation', style: authLabelStyle),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _arabicController,
                  textAlign: TextAlign.right,
                  decoration: authFieldDecoration(hint: 'صداقة'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Arabic translation is required' : null,
                ),
                const SizedBox(height: 16),
                Text('Transliteration (optional)', style: authLabelStyle),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _transliterationController,
                  decoration: authFieldDecoration(hint: 'e.g. sadaqa'),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => setState(() => _showExample = !_showExample),
                  child: Row(
                    children: [
                      Icon(_showExample ? Icons.remove_circle_outline : Icons.add_circle_outline, size: 18, color: AppColors.green),
                      const SizedBox(width: 6),
                      Text(
                        _showExample ? 'Remove example sentence' : 'Add an example sentence (optional)',
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.green),
                      ),
                    ],
                  ),
                ),
                if (_showExample) ...[
                  const SizedBox(height: 16),
                  Text('Example (Arabic)', style: authLabelStyle),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _exampleArabicController,
                    textAlign: TextAlign.right,
                    decoration: authFieldDecoration(hint: 'هذه صداقة قوية.'),
                  ),
                  const SizedBox(height: 16),
                  Text('Example (Transliteration)', style: authLabelStyle),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _exampleTransliterationController,
                    decoration: authFieldDecoration(hint: 'e.g. Hathihi sadaqa qawiyya.'),
                  ),
                  const SizedBox(height: 16),
                  Text('Example (English)', style: authLabelStyle),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _exampleEnglishController,
                    decoration: authFieldDecoration(hint: 'e.g. This is a strong friendship.'),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: authPrimaryButtonStyle,
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Save Card'),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.muted, decoration: TextDecoration.underline),
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
}
