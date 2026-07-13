import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle heading = TextStyle(
    fontSize: 28,
    fontFamily: 'Prociono',
    color: AppColors.primary,
  );

  static const TextStyle headingOne = TextStyle(
    fontSize: 45,
    fontFamily: 'Prociono',
    color: AppColors.coral,
    letterSpacing: 1.5,
    height: 1,
  );

  static const TextStyle subheading = TextStyle(
    fontSize: 14,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontFamily: 'PlusJakartaSans-SemiBold',
    color: AppColors.primary,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 16,
    fontFamily: 'PlusJakartaSans-SemiBold',
    color: AppColors.primary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontFamily: 'Inter',
    color: AppColors.black,
  );

  static const TextStyle bodyLight = TextStyle(
    fontSize: 15,
    fontFamily: 'PlusJakartaSans-Light',
    color: AppColors.black,
  );

  static const TextStyle button = TextStyle(
    fontSize: 18,
    fontFamily: 'PlusJakartaSans-Regular',
    color: AppColors.white,
  );

  static const TextStyle link = TextStyle(
    fontSize: 15,
    fontFamily: 'PlusJakartaSans-Light',
    color: AppColors.link,
  );

  static const TextStyle hint = TextStyle(
    fontFamily: 'PlusJakartaSans',
    color: AppColors.textHint,
    fontSize: 14,
  );

  static const TextStyle errorStyle = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 12,
    color: AppColors.error,
  );
}
