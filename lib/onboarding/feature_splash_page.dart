import 'package:deewan_institute_app/auth/signup.dart';
import 'package:deewan_institute_app/core/app_colors.dart';
import 'package:dotlottie_flutter/dotlottie_flutter.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class FeatureSplashPage extends StatefulWidget {
  const FeatureSplashPage({super.key});

  @override
  State<FeatureSplashPage> createState() => _FeatureSplashPageState();
}

class _FeatureSplashPageState extends State<FeatureSplashPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _slides = [
    _FeatureSlide(
      title: 'Find the words you need',
      description:
          'Explore our Arabic dictionary and quickly discover useful words for everyday conversations.',
      accent: AppColors.green,
      animation: _AnimationType.dictionary,
    ),
    _FeatureSlide(
      title: 'Remember with flashcards',
      description:
          'Build your vocabulary with focused flashcard practice that makes new Arabic words easier to remember.',
      accent: AppColors.coral,
      animation: _AnimationType.flashcards,
    ),
    _FeatureSlide(
      title: 'Put your skills to the test',
      description:
          'Take quick quizzes, check your understanding, and keep making progress one lesson at a time.',
      accent: AppColors.orange,
      animation: _AnimationType.quiz,
    ),
  ];

  bool get _isLastPage => _currentPage == _slides.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openSignup() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SignUp()),
    );
  }

  void _continue() {
    if (_isLastPage) {
      _openSignup();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 16, 0),
              child: Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: _openSignup,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.muted,
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) => _SlideContent(
                  slide: _slides[index],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        width: index == _currentPage ? 28 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: index == _currentPage
                              ? _slides[_currentPage].accent
                              : AppColors.primaryBorder,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: FilledButton(
                      onPressed: _continue,
                      style: FilledButton.styleFrom(
                        backgroundColor: _slides[_currentPage].accent,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Text(
                          _isLastPage ? 'Get Started' : 'Next',
                          key: ValueKey(_isLastPage),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
              ],
          ),
        ),
      ),
    );
  }
}

class _SlideContent extends StatelessWidget {
  const _SlideContent({required this.slide});

  final _FeatureSlide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Expanded(
            flex: 6,
            child: Center(
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 430),
                margin: const EdgeInsets.symmetric(vertical: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: AppColors.primaryBorder),
                  boxShadow: [
                    BoxShadow(
                      color: slide.accent.withValues(alpha: 0.16),
                      blurRadius: 34,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: _FeatureAnimation(type: slide.animation),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  slide.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontFamily: 'Prociono',
                    fontSize: 34,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  slide.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureAnimation extends StatelessWidget {
  const _FeatureAnimation({required this.type});

  final _AnimationType type;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case _AnimationType.dictionary:
        return Lottie.asset(
          'assets/animation_lottie/dictionary.json',
          fit: BoxFit.contain,
          repeat: true,
        );
      case _AnimationType.flashcards:
        return const DotLottieView(
          source: 'animation_lottie/flashcards.lottie',
          sourceType: 'asset',
          autoplay: true,
          loop: true,
        );
      case _AnimationType.quiz:
        return Lottie.asset(
          'assets/animation_lottie/quiz.json',
          fit: BoxFit.contain,
          repeat: true,
        );
    }
  }
}

enum _AnimationType { dictionary, flashcards, quiz }

class _FeatureSlide {
  const _FeatureSlide({
    required this.title,
    required this.description,
    required this.accent,
    required this.animation,
  });

  final String title;
  final String description;
  final Color accent;
  final _AnimationType animation;
}
