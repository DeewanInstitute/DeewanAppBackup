import 'package:deewan_institute_app/auth/login.dart';
import 'package:deewan_institute_app/core/app_loading.dart';
import 'package:deewan_institute_app/core/auth_service.dart';
import 'package:deewan_institute_app/courses/arabic_courses_page.dart';
import 'package:deewan_institute_app/podcasts/podcast_home.dart';
import 'package:deewan_institute_app/core/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    this.selectedIndex = 0,
  });

  final int selectedIndex;

  static const homeIndex = 0;
  static const coursesIndex = 1;
  static const podcastsIndex = 2;
  static const settingsIndex = 3;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.75,
      backgroundColor: AppColors.cream,
      elevation: 18,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsetsGeometry.all(15.0),
          child: Column(
            children: [
              const _DrawerProfileCard(),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _DrawerItem(
                      icon: Icons.home_outlined,
                      label: 'Home',
                      selected: selectedIndex == homeIndex,
                      onTap: () => _goHome(context),
                    ),
                    const SizedBox(height: 12),
                    _DrawerItem(
                      icon: Icons.menu_book_outlined,
                      label: 'Arabic Courses',
                      selected: selectedIndex == coursesIndex,
                      onTap: selectedIndex == coursesIndex
                          ? () => Navigator.pop(context)
                          : () => _open(context, const ArabicCoursesPage()),
                    ),
                    const SizedBox(height: 12),
                    _DrawerItem(
                      icon: Icons.bluetooth_audio,
                      label: 'Podcasts',
                      selected: selectedIndex == podcastsIndex,
                      onTap: selectedIndex == podcastsIndex
                          ? () => Navigator.pop(context)
                          : () => _open(context, const PodcastHome()),
                    ),
                    const SizedBox(height: 12),
                    _DrawerItem(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      selected: selectedIndex == settingsIndex,
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(
                height: 34,
                thickness: 1,
                color: Color(0xFFE6E2DC),
              ),
              const SizedBox(height: 12),
              _LogoutButton(onTap: () => _logout(context)),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _open(BuildContext context, Widget page) async {
    final navigator = Navigator.of(context);
    navigator.pop();

    await Future<void>.delayed(const Duration(milliseconds: 220));

    if (!navigator.mounted) return;
    AppLoading.navigate(navigator.context, page);
  }

  static void _goHome(BuildContext context) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.popUntil((route) => route.isFirst);
  }

  static Future<void> _logout(BuildContext context) async {
    final navigator = Navigator.of(context);
    navigator.pop();

    await Future<void>.delayed(const Duration(milliseconds: 220));
    await AuthService.signOut();

    if (!navigator.mounted) return;
    AppLoading.navigate(
      navigator.context,
      const Login(),
      clearStack: true,
    );
  }
}

class _DrawerProfileCard extends StatelessWidget {
  const _DrawerProfileCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * .15,
      padding: const EdgeInsets.fromLTRB(28, 22, 22, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.orange,
            Color(0xFF6D7F93),
          ],
        ),
      ),
      child: const Row(
        children: [
          _DrawerAvatar(),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amira',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Prociono',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
                SizedBox(height: 11),
                Text(
                  'Deewan Student',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: "Inter",
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1,
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

class _DrawerAvatar extends StatelessWidget {
  const _DrawerAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 65,
      height: 65,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFEADCCA),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.72),
          width: 3,
        ),
      ),
      child: const Icon(
        Icons.person_rounded,
        color: Color(0xFF8A6548),
        size: 47,
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : AppColors.ink;

    return Material(
      color: selected
          ? AppColors.green
          : Colors.white.withValues(alpha: 0.34),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 25),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: selected
                ? null
                : Border.all(
                    color: const Color(0xFFE4E4E4),
                    width: 1.1,
                  ),
          ),
          child: Row(
            children: [
              Icon(icon, color: foreground, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 16,
                    fontFamily: "Inter",
                    fontWeight: FontWeight.w500,
                    height: 1,
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

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width * .90,
      height: MediaQuery.sizeOf(context).height *.07,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.logout_rounded, size: 30),
        label: const Text(
          'Log Out',
          style: TextStyle(
            fontFamily: "Inter",
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.coral,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(34),
          ),
        ),
      ),
    );
  }
}
