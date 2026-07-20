import 'package:deewan_institute_app/core/app_bottom_nav.dart';
import 'package:deewan_institute_app/core/app_colors.dart';
import 'package:deewan_institute_app/core/app_loading.dart';
import 'package:deewan_institute_app/courses/course_data.dart';
import 'package:deewan_institute_app/flashcards/review_incorrect_page.dart';
import 'package:deewan_institute_app/word_search/word_search_page.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CourseDetailsPage extends StatelessWidget {
  const CourseDetailsPage({super.key, required this.course});

  final CourseData course;

  Future<void> _openWebsite(BuildContext context) async {
    final uri = Uri.tryParse(course.websiteUrl);
    if (uri == null || !uri.hasScheme) {
      _showLinkError(context);
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) _showLinkError(context);
  }

  void _showLinkError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add a valid websiteUrl for this course.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.courseBackground,
      extendBody: true,
      body: Stack(
        children: [
          const Positioned.fill(child: _DetailsPattern()),
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _CourseHero(course: course)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 150),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionHeading('REGISTRATION DETAILS'),
                        const SizedBox(height: 14),
                        Text(
                          course.registrationDetails,
                          style: const TextStyle(
                            color: AppColors.courseBodyText,
                            fontFamily: 'Inter',
                            fontSize: 16,
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 26),
                        const _SectionHeading('COURSE DETAILS'),
                        const SizedBox(height: 14),
                        Text(
                          course.courseDetails,
                          style: const TextStyle(
                            color: AppColors.courseBodyText,
                            fontFamily: 'Inter',
                            fontSize: 16,
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 34),
                        FilledButton(
                          onPressed: () => _openWebsite(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.green,
                            foregroundColor: AppColors.white,
                            minimumSize: const Size.fromHeight(60),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Register For The Course',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
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
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: -1,
        onTap: (index) {
          if (index == 0) {
            Navigator.popUntil(context, (route) => route.isFirst);
          } else if (index == 1) {
            AppLoading.navigate(context, const WordSearchPage());
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReviewIncorrectPage()),
            );
          }
        },
      ),
    );
  }
}

class _CourseHero extends StatelessWidget {
  const _CourseHero({required this.course});

  final CourseData course;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 315),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 34),
      decoration: BoxDecoration(
        gradient: course.theme == 'alphabet'
            ? AppColors.courseHeroGradient
            : course.gradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: AppColors.courseBackButtonBackground,
              borderRadius: BorderRadius.circular(13),
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(13),
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.white,
                    size: 27,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 80,
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.courseHeroIconBackground,
              borderRadius: BorderRadius.circular(24),
            ),
            child: course.heroLetter.isEmpty
                ? Icon(course.iconData, color: AppColors.white, size: 40)
                : Text(
                    course.heroLetter,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontFamily: 'Prociono',
                      fontSize: 38,
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          Text(
            course.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.white,
              fontFamily: 'Prociono',
              fontSize: 38,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: course.formats
                .map((format) => _CourseFormatBadge(format))
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _CourseFormatBadge extends StatelessWidget {
  const _CourseFormatBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.courseTagText,
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.green,
        fontFamily: 'Inter',
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _DetailsPattern extends StatelessWidget {
  const _DetailsPattern();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.courseBackground,
      child: Opacity(
        opacity: 0.08,
        child: Image.asset(
          'assets/images/background/background.png',
          fit: BoxFit.cover,
          repeat: ImageRepeat.repeat,
        ),
      ),
    );
  }
}
