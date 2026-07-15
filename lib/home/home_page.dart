import 'package:deewan_institute_app/core/app_loading.dart';
import 'package:deewan_institute_app/core/app_bottom_nav.dart';
import 'package:deewan_institute_app/core/app_drawer.dart';
import 'package:deewan_institute_app/core/app_top_nav.dart';
import 'package:deewan_institute_app/flashcards/flashcards_home.dart';
import 'package:deewan_institute_app/flashcards/review_incorrect_page.dart';
import 'package:deewan_institute_app/word_search/word_search_page.dart';
import 'package:deewan_institute_app/core/app_colors.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _dialectIndex = 0;
  int _navIndex = 0;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _goToDictionarySearch() {
    final query = _searchController.text.trim();
    AppLoading.navigate(context, WordSearchPage(initialQuery: query.isEmpty ? null : query));
  }


  final List<_FlashcardPreview> _flashcards = const [
    _FlashcardPreview(
      word: 'Marhaba',
      meaning: 'Hello',
      color: AppColors.green,
      iconColor: AppColors.orange,
      icon: Icons.check_rounded,
    ),
    _FlashcardPreview(
      word: 'Shukraan',
      meaning: 'Thank you',
      color: AppColors.orange,
      iconColor: AppColors.green,
      icon: Icons.bolt_rounded,
    ),
    _FlashcardPreview(
      word: 'As-salamu\nalaykum',
      meaning: 'Peace be upon you',
      color: AppColors.coral,
      iconColor: Colors.white,
      icon: Icons.error_outline_rounded,
    ),
  ];

  void _openTab(int index) {
    setState(() => _navIndex = index);

    if (index == 1) {
      AppLoading.navigate(context, const WordSearchPage());
      return;
    }

    if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewIncorrectPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.cream,
      extendBody: true,
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          const Positioned.fill(child: _HomeBackdrop()),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 20, 0, 126 + bottomPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: const AppTopNav(),
                  ),
                  const SizedBox(height: 28),
                  const Padding(
                    padding: EdgeInsets.only(right: 20),
                    child: _HeroIntro(),
                  ),
                  const SizedBox(height: 28),
                  const _SectionTitle('Dictionary'),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: _SearchField(
                      controller: _searchController,
                      onSearch: _goToDictionarySearch,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DialectSwitch(
                    selectedIndex: _dialectIndex,
                    onSelected: (index) {
                      setState(() => _dialectIndex = index);
                    },
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: _FlashcardsHeader(
                      onViewMore: () => AppLoading.navigate(
                        context,
                        const FlashcardsHome(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * .30,
                    child: ListView.separated(
                      clipBehavior: Clip.none,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(right: 20),
                      itemCount: _flashcards.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (_, index) {
                        return _FlashcardTile(card: _flashcards[index]);
                      },
                    ),
                  ),
                  const SizedBox(height: 34),
                  const _SectionTitle('Quiz'),
                  const SizedBox(height: 18),
                  const Padding(
                    padding: EdgeInsets.only(right: 20),
                    child: _QuizCard(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _navIndex,
        onTap: _openTab,
      ),
    );
  }
}

class _HeroIntro extends StatelessWidget {
  const _HeroIntro();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ready for your next word?',
          style: TextStyle(
            color: AppColors.coral,
            fontFamily: 'Prociono',
            fontSize: 48,
            height: 1.08,
          ),
        ),
        SizedBox(height: 18),
        Text(
          'Immerse yourself in Levantine and Fusha with a daily dose of vocabulary, flashcards, and quizzes.',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.green,
        fontFamily: 'Prociono',
        fontSize: 24,
        height: 1,
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onSearch});

  final TextEditingController controller;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => onSearch(),
      decoration: InputDecoration(
        hintText: 'Search for a word...',
        hintStyle: const TextStyle(
          color: Color(0xFF8E8B8F),
          fontSize: 15,
          fontFamily: "Inter",
          fontWeight: FontWeight.w400,
        ),
        suffixIcon: GestureDetector(
          onTap: onSearch,
          child: const Icon(
            Icons.search_rounded,
            color: AppColors.orange,
            size: 31,
          ),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.16),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 20,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(36),
          borderSide: const BorderSide(
            color: AppColors.orange,
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(36),
          borderSide: const BorderSide(
            color: AppColors.orange,
            width: 1.2,
          ),
        ),
      ),
    );
  }
}

class _DialectSwitch extends StatelessWidget {
  const _DialectSwitch({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _DialectChip(
          label: 'Levantine',
          selected: selectedIndex == 0,
          onTap: () => onSelected(0),
        ),
        const SizedBox(width: 10),
        _DialectChip(
          label: 'Fusha',
          selected: selectedIndex == 1,
          onTap: () => onSelected(1),
        ),
      ],
    );
  }
}

class _DialectChip extends StatelessWidget {
  const _DialectChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.green : Colors.transparent,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: selected ? AppColors.green : AppColors.coral,
              width: 1.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(
                  Icons.circle,
                  color: Colors.white,
                  size: 10,
                ),
                const SizedBox(width: 9),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.coral,
                  fontSize: 14.5,
                  fontFamily: "Inter",
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlashcardsHeader extends StatelessWidget {
  const _FlashcardsHeader({required this.onViewMore});

  final VoidCallback onViewMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const _SectionTitle('Flashcards'),
        FilledButton(
          onPressed: onViewMore,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.coral,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            minimumSize: const Size(0, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: const Text(
            'View More',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _FlashcardTile extends StatelessWidget {
  const _FlashcardTile({required this.card});

  final _FlashcardPreview card;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: card.color,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => AppLoading.navigate(context, const FlashcardsHome()),
        child: Container(
          width: MediaQuery.sizeOf(context).width * 0.50,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: card.color.withValues(alpha: 0.24),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                card.word,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Prociono',
                  fontSize: 21,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                card.meaning,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: card.iconColor,
                ),
                child: Icon(
                  card.icon,
                  color: card.iconColor == Colors.white
                      ? AppColors.coral
                      : Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 25, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE7E7E7), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.28),
            blurRadius: 28,
            spreadRadius: -4,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level One',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontFamily: 'Prociono',
                        fontSize: 26,
                        height: 1,
                      ),
                    ),
                    SizedBox(height: 11),
                    Text(
                      'Section 1: Alphabets',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 14,
                        fontFamily: "Inter",
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.menu_book_outlined,
                color: AppColors.orange,
                size: 27,
              ),
            ],
          ),
          const SizedBox(height: 34),
          const Center(
            child: _ProgressRing(progress: 0.29),
          ),
          const SizedBox(height: 34),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.coral,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'Continue the Lesson',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: "Inter",
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(width: 13),
                  Icon(Icons.arrow_forward_rounded, size: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 122,
      height: 122,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size.square(122),
            painter: _ProgressRingPainter(progress: progress),
          ),
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '29%',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Progress',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(
      rect.deflate(6),
      -1.5708,
      6.28318,
      false,
      stroke..color = const Color(0xFFE7E9EC),
    );

    canvas.drawArc(
      rect.deflate(6),
      -1.5708,
      6.28318 * progress,
      false,
      stroke..color = AppColors.green,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _HomeBackdrop extends StatelessWidget {
  const _HomeBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: AppColors.cream),
        Positioned(
          top: -120,
          right: -90,
          child: Container(
            width: 250,
            height: 330,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEE0).withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(150),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFEEE0).withValues(alpha: 0.68),
                  blurRadius: 80,
                  spreadRadius: 40,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 220,
          right: -60,
          child: CustomPaint(
            size: const Size(190, 112),
            painter: _OutlineShapePainter(),
          ),
        ),
        Positioned(
          bottom: 80,
          left: -70,
          child: Container(
            width: 190,
            height: 230,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE8BC).withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(120),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFE8BC).withValues(alpha: 0.38),
                  blurRadius: 90,
                  spreadRadius: 36,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OutlineShapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE5EDE2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path()
      ..moveTo(size.width * 0.08, size.height * 0.74)
      ..lineTo(size.width * 0.36, size.height * 0.18)
      ..quadraticBezierTo(
        size.width * 0.42,
        size.height * 0.04,
        size.width * 0.55,
        size.height * 0.04,
      )
      ..lineTo(size.width * 0.96, size.height * 0.04)
      ..quadraticBezierTo(
        size.width * 1.04,
        size.height * 0.04,
        size.width * 1.1,
        size.height * 0.12,
      )
      ..lineTo(size.width * 1.22, size.height * 0.26);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FlashcardPreview {
  const _FlashcardPreview({
    required this.word,
    required this.meaning,
    required this.color,
    required this.iconColor,
    required this.icon,
  });

  final String word;
  final String meaning;
  final Color color;
  final Color iconColor;
  final IconData icon;
}
