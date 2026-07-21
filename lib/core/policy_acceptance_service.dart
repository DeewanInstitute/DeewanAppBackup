import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether the user has accepted the Privacy Policy / Terms of
/// Service, so returning to either page reflects their last decision
/// instead of always showing the initial "Agree" prompt.
class PolicyAcceptance {
  PolicyAcceptance._();

  static const _privacyKey = 'privacy_accepted';
  static const _termsKey = 'terms_accepted';

  static Future<bool> isPrivacyAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_privacyKey) ?? false;
  }

  static Future<void> setPrivacyAccepted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_privacyKey, value);
  }

  static Future<bool> isTermsAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_termsKey) ?? false;
  }

  static Future<void> setTermsAccepted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_termsKey, value);
  }
}
