import 'package:deewan_institute_app/auth/login.dart';
import 'package:deewan_institute_app/core/app_bottom_nav.dart';
import 'package:deewan_institute_app/core/app_colors.dart';
import 'package:deewan_institute_app/core/app_loading.dart';
import 'package:deewan_institute_app/core/auth_service.dart';
import 'package:deewan_institute_app/courses/arabic_courses_page.dart';
import 'package:deewan_institute_app/flashcards/flashcards_home.dart';
import 'package:deewan_institute_app/podcasts/podcast_home.dart';
import 'package:deewan_institute_app/word_search/word_search_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _navIndex = 0;
  final List<_Course> _newCourses = const [
    _Course(
      category: 'Guide to Deewan \nArabic Podcasts',
      title: 'Season 1',
      color: Color(0xFF765D29),
      duration: '6 weeks',
      students: 342,
    ),
    _Course(
      category: 'Guide to Deewan \nArabic Podcasts',
      title: 'Season 2',
      color: Color(0xFF9F7F3A),
      duration: '4 weeks',
      students: 218,
    ),
    _Course(
      category: 'Guide to Deewan \nArabic Podcasts',
      title: 'Season 3',
      color: Color(0xFFC8A24E),
      duration: '3 weeks',
      students: 157,
    ),
  ];

  final List<_MyCourse> _myCourses = const [
    _MyCourse(
      category: 'Arabic',
      title: 'Levantine\nDialect',
      color: Color(0xFF765D29), // ← was 0xFF9B7FE8
      progress: 0.46,
      current: 11,
      total: 24,
    ),
    _MyCourse(
      category: 'English',
      title: 'IELTS\nPrep',
      color: Color(0xFF9F7F3A), // ← was 0xFFFF7A5A
      progress: 0.12,
      current: 3,
      total: 20,
    ),
  ];

  final List<_AvatarColor> _avatars = const [
    _AvatarColor(Color(0xFFFFB3BA)),
    _AvatarColor(Color(0xFFFFDFBA)),
    _AvatarColor(Color(0xFFBAFFBA)),
    _AvatarColor(Color(0xFFBAD7FF)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F2),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background/background.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryLight,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Merhaba 👋',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black.withOpacity(0.45),
                                fontFamily: 'PlusJakartaSans',
                              ),
                            ),
                            Text(
                              FirebaseAuth.instance.currentUser?.displayName ??
                                  'there',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'PlusJakartaSans',
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // _IconBtn(
                        //   icon: Icons.notifications_outlined,
                        //   bgColor: AppColors.primary,
                        //   iconColor: Colors.white,
                        // ),
                        GestureDetector(
                          onTap: () async {
                            await AuthService.signOut();
                            if (!context.mounted) return;
                            AppLoading.navigate(
                              context,
                              const Login(),
                              clearStack: true,
                            );
                          },
                          child: _IconBtn(
                            icon: Icons.logout,
                            bgColor: AppColors.primary,
                            iconColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  // Upcoming Events
                  _SectionHeader(
                    title: 'Upcoming Events',
                    onTap: () {},
                    showViewAll: false,
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _EventCard(),
                  ),
                  const SizedBox(height: 28),

                  // Arabic Courses
                  _SectionHeader(
                    title: 'Our Arabic Courses',
                    onTap: () {
                      AppLoading.navigate(context, const ArabicCoursesPage());
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 190,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _myCourses.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (_, i) =>
                          _MyCourseCard(course: _myCourses[i]),
                    ),
                  ),

                  const SizedBox(height: 28),
                  // New Courses
                  _SectionHeader(
                    title: 'Deewan Arabic Podcasts',
                    onTap: () {
                      AppLoading.navigate(context, const PodcastHome());
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _newCourses.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (_, i) => _NewCourseCard(
                        course: _newCourses[i],
                        avatars: _avatars,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _navIndex,
        onTap: (i) {
          if (i == 1) {
            AppLoading.navigate(context, const WordSearchPage());
            return;
          }
          if (i == 2) {
            AppLoading.navigate(context, const FlashcardsHome());
            return;
          }
          if (i == 3) {
            AppLoading.navigate(context, const PodcastHome());
            return;
          }
          setState(() => _navIndex = i);
        },
      ),
    );
  }
}

// ── New Course Card ───────────────────────────────────────────────────────────

class _NewCourseCard extends StatelessWidget {
  final _Course course;
  final List<_AvatarColor> avatars;
  const _NewCourseCard({required this.course, required this.avatars});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AppLoading.navigate(context, const PodcastHome());
      },
      child: Container(
        width: 210,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: course.color,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  course.category,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontFamily: 'PlusJakartaSans',
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_outward_rounded,
                    size: 16,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              course.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: 'PlusJakartaSans',
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Stacked avatars
                SizedBox(
                  width: 70,
                  height: 24,
                  child: Stack(
                    children: List.generate(
                      avatars.length > 3 ? 3 : avatars.length,
                      (i) => Positioned(
                        left: i * 16.0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: avatars[i].color,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  '+${course.students}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontFamily: 'PlusJakartaSans',
                  ),
                ),
                const Spacer(),
                Text(
                  course.duration,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontFamily: 'PlusJakartaSans',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── My Course Card ────────────────────────────────────────────────────────────

class _MyCourseCard extends StatelessWidget {
  final _MyCourse course;
  const _MyCourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: course.color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            course.category,
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 12,
              fontFamily: 'PlusJakartaSans',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            course.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              fontFamily: 'PlusJakartaSans',
              height: 1.2,
            ),
          ),
          const Spacer(),
          const SizedBox(height: 12),
          GestureDetector(
            onTap:() async {
              final url = Uri.parse('https://docs.google.com/forms/d/e/1FAIpQLScKQTLvV48wnnLa-MG4VYBXHLXQS-5aP7IrO-8_InTxnRqGIQ/viewform');
              if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
              // optional: handle the case where the link can't open
              debugPrint('Could not launch $url');
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
              ),
              alignment: Alignment.center,
              child: Text(
                'Sign Up',
                style: TextStyle(
                  color: course.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'PlusJakartaSans',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Event Card ────────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'This Week',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontFamily: 'PlusJakartaSans',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Book Fair &\nLanguage Exchange',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'PlusJakartaSans',
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Jan 25 – Jan 30 · Deewan Institute',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 12,
                    fontFamily: 'PlusJakartaSans',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.event_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final bool showViewAll;
  const _SectionHeader({
    required this.title,
    required this.onTap,
    this.showViewAll = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'PlusJakartaSans',
            ),
          ),
          if (showViewAll)
            GestureDetector(
              onTap: onTap,
              child: Text(
                'View all',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontFamily: 'PlusJakartaSans',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Icon Button ───────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color? bgColor;
  final Color? iconColor;
  const _IconBtn({required this.icon, this.bgColor, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bgColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, size: 20, color: iconColor ?? Colors.black87),
    );
  }
}

// ── Data Models ───────────────────────────────────────────────────────────────

class _Course {
  final String category;
  final String title;
  final Color color;
  final String duration;
  final int students;
  const _Course({
    required this.category,
    required this.title,
    required this.color,
    required this.duration,
    required this.students,
  });
}

class _MyCourse {
  final String category;
  final String title;
  final Color color;
  final double progress;
  final int current;
  final int total;
  const _MyCourse({
    required this.category,
    required this.title,
    required this.color,
    required this.progress,
    required this.current,
    required this.total,
  });
}

class _AvatarColor {
  final Color color;
  const _AvatarColor(this.color);
}
