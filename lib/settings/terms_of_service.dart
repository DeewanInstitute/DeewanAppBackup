import 'package:deewan_institute_app/core/app_bottom_nav.dart';
import 'package:deewan_institute_app/core/app_colors.dart';
import 'package:deewan_institute_app/core/app_drawer.dart';
import 'package:deewan_institute_app/core/app_loading.dart';
import 'package:deewan_institute_app/core/app_text_styles.dart';
import 'package:deewan_institute_app/core/app_top_nav.dart';
import 'package:deewan_institute_app/flashcards/review_incorrect_page.dart';
import 'package:deewan_institute_app/settings/policy_widgets.dart';
import 'package:deewan_institute_app/word_search/word_search_page.dart';
import 'package:flutter/material.dart';

class TermsOfService extends StatelessWidget {
  const TermsOfService({super.key});

  void _decline(BuildContext context) => Navigator.pop(context);

  void _agree(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thanks for reviewing our terms.', style: TextStyle(fontFamily: 'Inter')),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppTopNav(),
              const SizedBox(height: 24),
              const Text('Terms of Service', style: AppTextStyles.headingOne),
              const SizedBox(height: 10),
              const Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  PolicyPill(label: 'Effective: Jan 1, 2026'),
                  PolicyPill(label: 'Version 1.0', outlined: true),
                ],
              ),
              const SizedBox(height: 20),
              const PolicyCard(
                children: [
                  PolicySection(
                    title: '1. Acceptance of Terms',
                    body:
                        'By accessing or using LinguArabi, you agree to be bound by these Terms of Service. If you do not agree with any part of these terms, you may not access the service.',
                  ),
                  PolicySection(
                    title: '2. Use of the App',
                    body: '',
                    bullets: [
                      'You must be at least 13 years of age to use this service.',
                      'You agree not to misuse the app for illegal activities.',
                      'Reverse engineering or unauthorized scraping of lessons is strictly prohibited.',
                    ],
                  ),
                  PolicySection(
                    title: '3. User Accounts',
                    body:
                        'You are responsible for maintaining the confidentiality of your login credentials and for all activities that occur under your account. Notify us immediately of any unauthorized use.',
                  ),
                  PolicySection(
                    title: '4. Intellectual Property',
                    body:
                        'All content provided in LinguArabi, including lessons, audio recordings, text, graphics, and logos, is the property of LinguArabi and is protected by copyright laws.',
                  ),
                  PolicySection(
                    title: '5. Subscription & Payments',
                    body:
                        'Optional paid plans provide additional features. Subscriptions are billed in advance and are non-refundable. You may cancel your subscription at any time through the store settings.',
                  ),
                  PolicySection(
                    title: '6. Termination',
                    body:
                        'We reserve the right to suspend or terminate your account at our sole discretion, without notice, for conduct that we believe violates these Terms or is harmful to other users.',
                  ),
                  PolicySection(
                    title: '7. Disclaimer of Warranties',
                    body: "LinguArabi is provided 'as is' without any warranties of any kind. We do not guarantee that the service will be uninterrupted or error-free.",
                    italic: true,
                  ),
                  PolicySection(
                    title: '8. Contact',
                    body: 'For any questions regarding these terms, please contact our legal team at:\nproject@deewandevelopment.com',
                    isLast: true,
                  ),
                ],
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
                    textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () => _agree(context),
                  child: const Text('I Agree & Continue'),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: GestureDetector(
                  onTap: () => _decline(context),
                  child: const Text(
                    'Decline',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.muted, decoration: TextDecoration.underline),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
