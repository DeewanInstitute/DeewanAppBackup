import 'package:deewan_institute_app/auth/login.dart';
import 'package:deewan_institute_app/core/app_bottom_nav.dart';
import 'package:deewan_institute_app/core/app_colors.dart';
import 'package:deewan_institute_app/core/app_drawer.dart';
import 'package:deewan_institute_app/core/app_loading.dart';
import 'package:deewan_institute_app/core/app_text_styles.dart';
import 'package:deewan_institute_app/core/app_theme.dart';
import 'package:deewan_institute_app/core/app_top_nav.dart';
import 'package:deewan_institute_app/core/auth_service.dart';
import 'package:deewan_institute_app/flashcards/review_incorrect_page.dart';
import 'package:deewan_institute_app/settings/change_password_page.dart';
import 'package:deewan_institute_app/settings/privacy.dart';
import 'package:deewan_institute_app/settings/terms_of_service.dart';
import 'package:deewan_institute_app/word_search/word_search_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _notificationsKey = 'notifications_enabled';

  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPref();
  }

  Future<void> _loadNotificationPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true);
  }

  Future<void> _setNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, value);
  }

  Future<void> _setDarkMode(bool value) async {
    final mode = value ? ThemeMode.dark : ThemeMode.light;
    themeModeNotifier.value = mode;
    await ThemePreference.save(mode);
  }

  Future<void> _editProfile(User user) async {
    final controller = TextEditingController(text: user.displayName ?? '');
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _EditProfileSheet(controller: controller),
    );
    if (saved == true) {
      await user.updateDisplayName(controller.text.trim());
      await user.reload();
      if (mounted) setState(() {});
    }
    controller.dispose();
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature coming soon.', style: const TextStyle(fontFamily: 'Inter'))),
    );
  }

  Future<void> _logOut() async {
    await AuthService.signOut();
    if (!mounted) return;
    AppLoading.navigate(context, const Login(), clearStack: true);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      drawer: const AppDrawer(selectedIndex: AppDrawer.settingsIndex),
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
              const Text('Settings', style: AppTextStyles.headingOne),
              const SizedBox(height: 20),

              _Card(
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFECE0D2)),
                      child: const Icon(Icons.person_rounded, color: Color(0xFF8A6548), size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (user?.displayName?.trim().isNotEmpty ?? false) ? user!.displayName! : 'Guest',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? 'Not signed in',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    if (user != null)
                      TextButton(
                        onPressed: () => _editProfile(user),
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                          textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        child: const Text('Edit'),
                      )
                    else
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Login())),
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                          textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        child: const Text('Log In'),
                      ),
                  ],
                ),
              ),

              const _SectionHeader('Account'),
              _Card(
                padding: EdgeInsets.zero,
                child: _SettingsRow(
                  icon: Icons.person_outline,
                  label: 'Change Password',
                  onTap: user == null
                      ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Login()))
                      : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordPage())),
                ),
              ),

              const _SectionHeader('Preferences'),
              _Card(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ValueListenableBuilder<ThemeMode>(
                      valueListenable: themeModeNotifier,
                      builder: (context, mode, _) => _SettingsToggleRow(
                        icon: Icons.dark_mode_outlined,
                        label: 'Dark Mode',
                        value: mode == ThemeMode.dark,
                        onChanged: _setDarkMode,
                      ),
                    ),
                    Divider(height: 1, color: colorScheme.outline),
                    _SettingsToggleRow(
                      icon: Icons.notifications_outlined,
                      label: 'Notifications',
                      value: _notificationsEnabled,
                      onChanged: _setNotifications,
                    ),
                  ],
                ),
              ),

              const _SectionHeader('Support'),
              _Card(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SettingsRow(icon: Icons.chat_bubble_outline_rounded, label: 'Contact Us', onTap: () => _comingSoon('Contact Us')),
                    Divider(height: 1, color: colorScheme.outline),
                    _SettingsRow(
                      icon: Icons.shield_outlined,
                      label: 'Privacy Policy',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Privacy())),
                    ),
                    Divider(height: 1, color: colorScheme.outline),
                    _SettingsRow(
                      icon: Icons.description_outlined,
                      label: 'Terms of Service',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsOfService())),
                    ),
                  ],
                ),
              ),

              const _SectionHeader('Danger Zone'),
              _Card(
                padding: EdgeInsets.zero,
                child: _SettingsRow(
                  icon: Icons.logout_rounded,
                  label: user == null ? 'Log In' : 'Log Out',
                  color: AppColors.coral,
                  onTap: user == null
                      ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Login()))
                      : _logOut,
                ),
              ),

              const SizedBox(height: 24),
              Center(
                child: Text(
                  'LinguArabi v1.0.0',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
      child: Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.green)),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _Card({required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isLight ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 6))] : null,
      ),
      child: child,
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _SettingsRow({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tint = color ?? AppColors.green;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: tint.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: tint, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: color ?? colorScheme.onSurface),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _SettingsToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SettingsToggleRow({required this.icon, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: AppColors.green.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.green, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.green),
        ],
      ),
    );
  }
}

class _EditProfileSheet extends StatelessWidget {
  final TextEditingController controller;
  const _EditProfileSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.primaryBorder, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Edit Profile',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
            const SizedBox(height: 20),
            const Text('Full Name', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Enter your name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(50), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(50), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(50), borderSide: const BorderSide(color: AppColors.green, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
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
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save'),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: GestureDetector(
                onTap: () => Navigator.pop(context, false),
                child: const Text('Cancel', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.muted, decoration: TextDecoration.underline)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
