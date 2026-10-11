import 'package:deewan_institute_app/core/app_theme.dart';
import 'package:deewan_institute_app/core/notification_service.dart';
import 'package:deewan_institute_app/home/home_page.dart';
import 'package:deewan_institute_app/onboarding/feature_splash_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await ThemePreference.load();
  await NotificationService.syncFromPreferences();
  runApp(const DeewanApp());
}

class DeewanApp extends StatelessWidget {
  const DeewanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        home: const HomePage(),
      ),
    );
  }
}


// home: FirebaseAuth.instance.currentUser == null
//             ? const FeatureSplashPage()
//             : const HomePage(),