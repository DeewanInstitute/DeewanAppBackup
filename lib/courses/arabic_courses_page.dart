import 'package:deewan_institute_app/core/app_bottom_nav.dart';
import 'package:deewan_institute_app/core/app_colors.dart';
import 'package:deewan_institute_app/core/app_drawer.dart';
import 'package:deewan_institute_app/core/app_loading.dart';
import 'package:deewan_institute_app/core/app_top_nav.dart';
import 'package:deewan_institute_app/flashcards/review_incorrect_page.dart';
import 'package:deewan_institute_app/word_search/word_search_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ArabicCoursesPage extends StatelessWidget {
  const ArabicCoursesPage({super.key});

  static const List<_CourseItem> _courses = [
    _CourseItem(category: 'Beginner', title: 'Arabic\nAlphabet', color: Color(0xFF6B8CFF), progress: 0.85, current: 17, total: 20),
    _CourseItem(category: 'Beginner', title: 'Basic\nVocabulary', color: Color(0xFF4ECBA8), progress: 0.60, current: 12, total: 20),
    _CourseItem(category: 'Intermediate', title: 'Levantine\nDialect', color: Color(0xFF9B7FE8), progress: 0.46, current: 11, total: 24),
    _CourseItem(category: 'Intermediate', title: 'Modern\nStandard Arabic', color: Color(0xFFFF7A5A), progress: 0.30, current: 6, total: 20),
    _CourseItem(category: 'Intermediate', title: 'Arabic\nGrammar', color: Color(0xFFFFB347), progress: 0.20, current: 4, total: 20),
    _CourseItem(category: 'Intermediate', title: 'Egyptian\nDialect', color: Color(0xFF5BB8FF), progress: 0.10, current: 2, total: 18),
    _CourseItem(category: 'Advanced', title: 'Classical\nArabic', color: Color(0xFFE85D8A), progress: 0.70, current: 14, total: 20),
    _CourseItem(category: 'Advanced', title: 'Arabic\nLiterature', color: Color(0xFF56C596), progress: 0.05, current: 1, total: 22),
    _CourseItem(category: 'Advanced', title: 'Quranic\nArabic', color: Color(0xFF8FBF6E), progress: 0.50, current: 10, total: 20),
    _CourseItem(category: 'Culture', title: 'Arab\nHistory', color: Color(0xFFD97B5A), progress: 0.35, current: 7, total: 20),
    _CourseItem(category: 'Culture', title: 'Islamic\nArt & Calligraphy', color: Color(0xFF7B9FD4), progress: 0.15, current: 3, total: 20),
    _CourseItem(category: 'Culture', title: 'Arabic\nPoetry', color: Color(0xFFC47FD4), progress: 0.00, current: 0, total: 16),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      drawer: const AppDrawer(selectedIndex: AppDrawer.coursesIndex),
      bottomNavigationBar: AppBottomNav(
        currentIndex: -1,
        onTap: (i) {
          if (i == 0) {
            Navigator.popUntil(context, (route) => route.isFirst);
            return;
          }
          if (i == 1) {
            AppLoading.navigate(context, const WordSearchPage());
            return;
          }
          if (i == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewIncorrectPage()));
            return;
          }
        },
      ),
      body: Column(
        children: [
          const SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: AppTopNav(),
            ),
          ),
          // ── Hero header ──────────────────────────────────────────
          Container(
            color: AppColors.primary,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // Background image tinted over
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.08,
                    child: Image.asset(
                      'assets/images/background/background.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Decorative Arabic letters scattered in background
                _arabicLetter('ب', top: 10, right: 24, size: 90, opacity: 0.10),
                _arabicLetter('ك', top: 50, right: 80, size: 56, opacity: 0.07),
                _arabicLetter('م', bottom: 10, right: 16, size: 72, opacity: 0.12),
                _arabicLetter('ل', bottom: 30, right: 70, size: 44, opacity: 0.07),
                _arabicLetter('ن', top: 20, right: 160, size: 38, opacity: 0.06),
                _arabicLetter('ا', bottom: 0, right: 130, size: 64, opacity: 0.09),
                _arabicLetter('ح', top: 8, right: 220, size: 48, opacity: 0.06),
                _arabicLetter('ص', bottom: 20, right: 190, size: 36, opacity: 0.07),

                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back button
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(CupertinoIcons.arrow_left, color: Colors.white, size: 18),
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'Arabic Courses',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'PlusJakartaSans',
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _HeaderBadge(label: '12 Courses'),
                            const SizedBox(width: 8),
                            _HeaderBadge(label: 'All Levels'),
                            const SizedBox(width: 8),
                            _HeaderBadge(label: 'Arabic'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Grid ────────────────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/background/background.png',
                    fit: BoxFit.cover,
                  ),
                ),
                GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 126),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _courses.length,
                  itemBuilder: (_, i) => _CourseCard(course: _courses[i]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Positioned _arabicLetter(String letter, {double? top, double? bottom, double? left, double? right, required double size, required double opacity}) {
  return Positioned(
    top: top, bottom: bottom, left: left, right: right,
    child: Text(
      letter,
      style: TextStyle(
        fontSize: size,
        color: Colors.white.withOpacity(opacity),
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _HeaderBadge extends StatelessWidget {
  final String label;
  const _HeaderBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontFamily: 'PlusJakartaSans',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final _CourseItem course;
  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final pct = (course.progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: course.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              course.category,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontFamily: 'PlusJakartaSans',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          Text(
            course.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              fontFamily: 'PlusJakartaSans',
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$pct%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'PlusJakartaSans',
                ),
              ),
              Text(
                '${course.current}/${course.total}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 11,
                  fontFamily: 'PlusJakartaSans',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: course.progress,
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
            ),
            alignment: Alignment.center,
            child: Text(
              course.progress == 0 ? 'Start' : 'Continue',
              style: TextStyle(
                color: course.color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'PlusJakartaSans',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseItem {
  final String category;
  final String title;
  final Color color;
  final double progress;
  final int current;
  final int total;
  const _CourseItem({
    required this.category,
    required this.title,
    required this.color,
    required this.progress,
    required this.current,
    required this.total,
  });
}
