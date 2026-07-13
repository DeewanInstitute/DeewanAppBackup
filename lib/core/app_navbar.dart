import 'package:deewan_institute_app/auth/auth_widgets.dart';
import 'package:deewan_institute_app/core/app_colors.dart';
import 'package:flutter/material.dart';

class AppNavBar extends StatelessWidget {
  const AppNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AuthBackButton(onTap: () => Navigator.pop(context)),
        const Spacer(),
        const Column(
          children: [
            Text(
              'LinguArabi',
              style: TextStyle(
                color: AppColors.coral,
                fontFamily: 'Prociono',
                fontSize: 24,
                letterSpacing: 1.5,
                height: 1,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Learn Arabic, Every Day',
              style: TextStyle(
                color: AppColors.orange,
                fontSize: 14,
                fontFamily: "Inter",
                fontWeight: FontWeight.w300,
                height: 1,
              ),
            ),
          ],
        ),
        const Spacer(),

      ],
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.green,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            Icons.menu_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFECE0D2),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.85),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Icon(
        Icons.person_rounded,
        color: Color(0xFF8A6548),
        size: 32,
      ),
    );
  }
}
