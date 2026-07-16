import 'package:deewan_institute_app/auth/auth_widgets.dart';
import 'package:deewan_institute_app/core/app_bottom_nav.dart';
import 'package:deewan_institute_app/core/app_colors.dart';
import 'package:deewan_institute_app/core/app_drawer.dart';
import 'package:deewan_institute_app/flashcards/review_incorrect_page.dart';
import 'package:flutter/material.dart';

enum _Dialect { fusha, levantine }

/// Deep-dive view of a verb's root family: conjugations, masdar,
/// participles, and other nouns sharing the same root. Only reachable for
/// dictionary entries that carry a `root_family` object.
///
/// The root/verb/conjugations section can toggle between Fusha and
/// Levantine, since colloquial conjugation genuinely differs (and for some
/// verbs, Levantine uses an entirely different root). Masdar, participles,
/// and nominal forms stay Fusha-only — those are MSA grammar categories
/// that don't map cleanly onto colloquial speech.
class WordDetailsPage extends StatefulWidget {
  final Map<String, dynamic> word;
  const WordDetailsPage({super.key, required this.word});

  @override
  State<WordDetailsPage> createState() => _WordDetailsPageState();
}

class _WordDetailsPageState extends State<WordDetailsPage> {
  _Dialect _dialect = _Dialect.fusha;

  Map<String, dynamic> get _rootFamily => widget.word['root_family'] as Map<String, dynamic>;

  Map<String, dynamic>? get _levantine => _rootFamily['levantine'] as Map<String, dynamic>?;

  bool get _isFusha => _dialect == _Dialect.fusha || _levantine == null;

  @override
  Widget build(BuildContext context) {
    final rootFamily = _rootFamily;
    final active = _isFusha ? rootFamily : _levantine!;

    final root = active['root'] as String? ?? '';
    final verb = active['verb'] as Map<String, dynamic>?;
    final conjugations = active['conjugations'] as Map<String, dynamic>?;
    final irregularImperative = active['irregular_imperative'] == true;
    final differentRoot = active['different_root_than_fusha'] == true;
    final note = active['note'] as String?;

    // Masdar and active participle can exist per-dialect (Levantine forms
    // often differ from Fusha), so these follow the toggle. Passive
    // participle and nominal forms are Fusha-only — those weren't asked for
    // in Levantine and stay sourced from the top-level root family.
    final masdar = active['masdar'] as Map<String, dynamic>?;
    final activeParticiple = active['active_participle'] as Map<String, dynamic>?;
    final passiveParticiple = rootFamily['passive_participle'] as Map<String, dynamic>?;
    final nominalForms = (rootFamily['nominal_forms'] as List?)?.cast<Map>();

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
          if (i == 1) return;
          if (i == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewIncorrectPage()));
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
              AuthBackButton(onTap: () => Navigator.pop(context)),
              const SizedBox(height: 20),

              Center(
                child: Column(
                  children: [
                    Text(
                      root,
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700, fontFamily: 'Inter', color: AppColors.ink),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Root (جذر)',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (_levantine != null) ...[
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _DialectChip(label: 'Fusha', selected: _isFusha, onTap: () => setState(() => _dialect = _Dialect.fusha)),
                      const SizedBox(width: 10),
                      _DialectChip(label: 'Levantine', selected: !_isFusha, onTap: () => setState(() => _dialect = _Dialect.levantine)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (differentRoot && note != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.orange, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(note, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.ink, height: 1.4)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              if (verb != null)
                _MorphCard(
                  label: 'Verb',
                  arabic: verb['arabic'] as String?,
                  transliteration: verb['transliteration'] as String?,
                  english: verb['english'] as String?,
                ),

              if (conjugations != null) ...[
                const SizedBox(height: 14),
                _ConjugationsCard(conjugations: conjugations, irregularImperative: irregularImperative),
              ],

              if (!_isFusha && passiveParticiple != null) ...[
                const SizedBox(height: 20),
                const Text(
                  'The passive participle below reflects Modern Standard Arabic grammar and is not toggled by dialect.',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.muted, fontStyle: FontStyle.italic),
                ),
              ],

              if (masdar != null) ...[
                const SizedBox(height: 14),
                _MorphCard(
                  label: 'Masdar (Verbal Noun)',
                  arabic: masdar['arabic'] as String?,
                  transliteration: masdar['transliteration'] as String?,
                  english: masdar['english'] as String?,
                ),
              ],

              if (activeParticiple != null) ...[
                const SizedBox(height: 14),
                _MorphCard(
                  label: 'Active Participle (اسم الفاعل)',
                  arabic: activeParticiple['arabic'] as String?,
                  transliteration: activeParticiple['transliteration'] as String?,
                  english: activeParticiple['english'] as String?,
                ),
              ],

              if (passiveParticiple != null) ...[
                const SizedBox(height: 14),
                _MorphCard(
                  label: 'Passive Participle (اسم المفعول)',
                  arabic: passiveParticiple['arabic'] as String?,
                  transliteration: passiveParticiple['transliteration'] as String?,
                  english: passiveParticiple['english'] as String?,
                ),
              ],

              if (nominalForms != null && nominalForms.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Nominal Forms',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.green),
                ),
                const SizedBox(height: 10),
                for (final form in nominalForms)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _MorphCard(
                      arabic: form['arabic'] as String?,
                      transliteration: form['transliteration'] as String?,
                      english: form['english'] as String?,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DialectChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _DialectChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.green : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: selected ? AppColors.green : AppColors.coral),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.coral,
          ),
        ),
      ),
    );
  }
}

class _MorphCard extends StatelessWidget {
  final String? label;
  final String? arabic;
  final String? transliteration;
  final String? english;
  const _MorphCard({this.label, this.arabic, this.transliteration, this.english});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label != null) ...[
                  Text(
                    label!,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.green),
                  ),
                  const SizedBox(height: 6),
                ],
                if (english != null)
                  Text(english!, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (arabic != null)
                Text(
                  arabic!,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, fontFamily: 'Inter', color: AppColors.ink),
                ),
              if (transliteration != null) ...[
                const SizedBox(height: 4),
                Text(
                  transliteration!,
                  style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.muted, fontFamily: 'Inter'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ConjugationsCard extends StatelessWidget {
  final Map<String, dynamic> conjugations;
  final bool irregularImperative;
  const _ConjugationsCard({required this.conjugations, required this.irregularImperative});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Past Tense', conjugations['past'] as Map<String, dynamic>?, false),
      ('Present Tense', conjugations['present'] as Map<String, dynamic>?, false),
      ('Imperative', conjugations['imperative'] as Map<String, dynamic>?, irregularImperative),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verb Conjugations',
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.green),
          ),
          const SizedBox(height: 12),
          for (final (label, value, irregular) in rows)
            if (value != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.muted)),
                          if (irregular) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.coral.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                              child: const Text(
                                'irregular',
                                style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.coral),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      value['arabic'] as String? ?? '',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Inter', color: AppColors.ink),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      value['transliteration'] as String? ?? '',
                      style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.muted, fontFamily: 'Inter'),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
