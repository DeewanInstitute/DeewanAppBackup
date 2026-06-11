import "package:deewan_institute_app/auth/login.dart";
import "package:deewan_institute_app/auth/signup.dart";
import "package:deewan_institute_app/core/app_colors.dart";
import "package:flutter/material.dart";

class LoginSignup extends StatefulWidget {
  const LoginSignup({super.key});

  @override
  State<LoginSignup> createState() => _LoginSignupState();
}

class _LoginSignupState extends State<LoginSignup> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingSlide> _slides = const [
    _OnboardingSlide(
      title: "Learn the local language\nfor free!",
      subtitle: "Learn all local Arabic\ninteractively at your fingertips!",
    ),
    _OnboardingSlide(
      title: "Practice with native\nspeakers",
      subtitle: "Engage in real conversations\nand build confidence fast.",
    ),
    _OnboardingSlide(
      title: "Track your progress\nevery day",
      subtitle: "Stay motivated with streaks\nand daily learning goals.",
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background/background.png',
              fit: BoxFit.cover,
            ),
          ),
          Column(
        children: [
          // Top white section — logo
          Expanded(
            child: Center(
              child: Image.asset(
                'assets/images/logos/nobgLogo.webp',
                width: size.width * 0.80,
              ),
            ),
          ),

          // Bottom brown card
          SizedBox(
            height: size.height * 0.50,
            child: Container(
              width: double.infinity,
              height: size.height * .20,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(36),
                  topRight: Radius.circular(36),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Handle indicator
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 50),
                  // Sliding text
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _slides.length,
                      onPageChanged: (i) => setState(() => _currentPage = i),
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _slides[i].title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontFamily: 'PlusJakartaSans',
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _slides[i].subtitle,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 15,
                                fontFamily: 'PlusJakartaSans',
                                fontWeight: FontWeight.w400,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Page dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.white
                              : Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 32),

                  // Register + Login buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SignUp()),
                            ),
                            icon: const Icon(Icons.arrow_right_alt,
                                color: Colors.white),
                            label: const Text(
                              "Register",
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'PlusJakartaSans',
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(
                                  color: Colors.white, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const Login()),
                            ),
                            icon: const Icon(Icons.arrow_right_alt,
                                color: AppColors.primary),
                            label: const Text(
                              "Login",
                              style: TextStyle(
                                color: AppColors.primary,
                                fontFamily: 'PlusJakartaSans',
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ],
      ),
    ]));
  }
}

class _OnboardingSlide {
  final String title;
  final String subtitle;
  const _OnboardingSlide({required this.title, required this.subtitle});
}
