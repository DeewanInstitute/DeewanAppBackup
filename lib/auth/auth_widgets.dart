import "package:country_code_picker/country_code_picker.dart";
import "package:deewan_institute_app/core/app_colors.dart";
import "package:flutter/material.dart";

const TextStyle authLabelStyle = TextStyle(
  fontSize: 14,
  fontFamily: 'Inter',
  fontWeight: FontWeight.w600,
  color: AppColors.ink,
);

const TextStyle authLinkStyle = TextStyle(
  fontSize: 14,
  fontFamily: 'Inter',
  fontWeight: FontWeight.w600,
  color: AppColors.green,
);

final ButtonStyle authPrimaryButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: AppColors.green,
  foregroundColor: Colors.white,
  padding: const EdgeInsets.symmetric(vertical: 16),
  textStyle: const TextStyle(
    fontSize: 16,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
  ),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
);

InputDecoration authFieldDecoration({
  required String hint,
  IconData? icon,
  Widget? prefixWidget,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    filled: true,
    fillColor: Colors.white,
    hintText: hint,
    hintStyle: const TextStyle(fontFamily: 'Inter', color: AppColors.muted, fontSize: 14),
    prefixIcon: prefixWidget ?? (icon != null ? Icon(icon, color: AppColors.muted) : null),
    prefixIconConstraints: prefixWidget != null ? const BoxConstraints(minWidth: 0) : null,
    suffixIcon: suffixIcon,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(50), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(50), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(50),
      borderSide: const BorderSide(color: AppColors.green, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(50), borderSide: const BorderSide(color: AppColors.error)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(50), borderSide: const BorderSide(color: AppColors.error)),
    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
  );
}

class PhoneCodePicker extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final String initialCountry;
  const PhoneCodePicker({super.key, required this.onChanged, this.initialCountry = 'LB'});

  static const _flagRadius = BorderRadius.all(Radius.circular(3));

  @override
  Widget build(BuildContext context) {
    return CountryCodePicker(
      onChanged: (code) => onChanged(code.dialCode ?? ''),
      initialSelection: initialCountry,
      favorite: const ['LB', 'US', 'GB', 'SA', 'AE'],
      flagWidth: 22,
      flagDecoration: const BoxDecoration(borderRadius: _flagRadius),
      builder: (country) => Padding(
        padding: const EdgeInsets.only(left: 4, right: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (country != null)
              ClipRRect(
                borderRadius: _flagRadius,
                child: Image.asset(country.flagUri!, package: 'country_code_picker', width: 22),
              ),
            const SizedBox(width: 8),
            Text(
              country?.dialCode ?? '',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.muted),
          ],
        ),
      ),
      pickerStyle: PickerStyle.bottomSheet,
      boxDecoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      closeIcon: const Icon(Icons.close_rounded, color: AppColors.muted, size: 20),
      dialogItemPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      searchPadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      searchDecoration: authFieldDecoration(hint: 'Search country', icon: Icons.search),
      searchStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.ink),
      dialogTextStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.ink),
    );
  }
}

class AuthBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const AuthBackButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: const Icon(Icons.arrow_back, color: AppColors.ink, size: 22),
      ),
    );
  }
}

class AuthDivider extends StatelessWidget {
  final String label;
  const AuthDivider({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.primaryBorder, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label, style: const TextStyle(fontFamily: 'Inter', color: AppColors.muted, fontSize: 13)),
        ),
        Expanded(child: Divider(color: AppColors.primaryBorder, thickness: 1)),
      ],
    );
  }
}

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onTap;
  const GoogleSignInButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: AppColors.primaryBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/images/icon/google.png", height: 20),
            const SizedBox(width: 10),
            const Text(
              "Google",
              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: AppColors.ink),
            ),
          ],
        ),
      ),
    );
  }
}

/// Strength scale: 0 = empty, 1 = weak, 2 = medium, 3 = strong.
int passwordStrength(String password) {
  if (password.isEmpty) return 0;
  var score = 0;
  if (password.length >= 6) score++;
  if (password.length >= 10 &&
      RegExp(r'[A-Z]').hasMatch(password) &&
      RegExp(r'[0-9]').hasMatch(password)) {
    score++;
  }
  if (password.length >= 10 && RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]').hasMatch(password)) {
    score++;
  }
  return score.clamp(0, 3);
}

class PasswordStrengthMeter extends StatelessWidget {
  final String password;
  const PasswordStrengthMeter({super.key, required this.password});

  static const _colors = [AppColors.error, AppColors.orange, AppColors.green];
  static const _labels = ['Weak password', 'Medium password', 'Strong password'];

  @override
  Widget build(BuildContext context) {
    final strength = passwordStrength(password);
    if (strength == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(3, (i) {
              final active = i < strength;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                  height: 4,
                  decoration: BoxDecoration(
                    color: active ? _colors[strength - 1] : AppColors.primaryBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(
            _labels[strength - 1],
            style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: _colors[strength - 1]),
          ),
        ],
      ),
    );
  }
}
