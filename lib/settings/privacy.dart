import 'package:deewan_institute_app/core/app_bottom_nav.dart';
import 'package:deewan_institute_app/core/app_colors.dart';
import 'package:deewan_institute_app/core/app_drawer.dart';
import 'package:deewan_institute_app/core/app_loading.dart';
import 'package:deewan_institute_app/core/app_text_styles.dart';
import 'package:deewan_institute_app/flashcards/review_incorrect_page.dart';
import 'package:deewan_institute_app/settings/policy_widgets.dart';
import 'package:deewan_institute_app/word_search/word_search_page.dart';
import 'package:flutter/material.dart';

import '../core/app_top_nav.dart';

class Privacy extends StatelessWidget {
  const Privacy({super.key});

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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReviewIncorrectPage()),
            );
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(child: Text('Privacy Policy', style: AppTextStyles.headingOne)),
                  const SizedBox(width: 12),
                  const Padding(padding: EdgeInsets.only(top: 8), child: PolicyPill(label: 'Jan 2025')),
                ],
              ),
              const SizedBox(height: 20),
              const PolicyCard(
                children: [
                  PolicySection(
                    title: 'Data We Collect',
                    body: 'We collect usage data, learning progress, and account information to improve your experience.',
                  ),
                  PolicySection(
                    title: 'How We Use Your Data',
                    body:
                        'Your data is used to personalize flashcards, track streaks, and provide analytics on your Arabic learning journey.',
                  ),
                  PolicySection(
                    title: 'Your Rights',
                    body: 'You can request data deletion or export your progress at any time through the account settings.',
                  ),
                  PolicySection(
                    title: 'Contact',
                    body: 'For privacy concerns, reach us at project@deewandevelopment.com',
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Accept & Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
