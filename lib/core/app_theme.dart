import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Global, app-wide theme mode. Toggling this immediately rebuilds the
/// MaterialApp under the new theme (see main.dart's ValueListenableBuilder).
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.light);

class ThemePreference {
  ThemePreference._();

  static const _key = 'theme_mode';

  /// Loads the persisted choice (defaults to light if never set) and applies
  /// it to [themeModeNotifier].
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    themeModeNotifier.value = prefs.getString(_key) == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  static Future<void> save(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode == ThemeMode.dark ? 'dark' : 'light');
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          primary: AppColors.primary,
          surface: AppColors.white,
          onSurface: AppColors.ink,
          onSurfaceVariant: AppColors.muted,
          outline: AppColors.primaryBorder,
        ),
        scaffoldBackgroundColor: AppColors.white,
        fontFamily: 'PlusJakartaSans',

        // ElevatedButton
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            textStyle: AppTextStyles.button,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
        ),

        // TextFormField / InputDecoration
        inputDecorationTheme: InputDecorationTheme(
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          hintStyle: AppTextStyles.hint,
          errorStyle: AppTextStyles.errorStyle,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: const BorderSide(color: AppColors.primaryBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: const BorderSide(color: AppColors.primaryBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: const BorderSide(color: AppColors.error),
          ),
        ),
      );

  /// A real dark theme. Only the new Settings page currently reads its
  /// colors through `Theme.of(context)` — the rest of the app hardcodes
  /// light-mode `AppColors` directly on each screen, so switching to dark
  /// won't yet change their appearance. See conversation notes.
  static ThemeData get dark {
    const surface = Color(0xFF201D18);
    const background = Color(0xFF15130F);
    const onSurface = Color(0xFFF3EFE8);
    const onSurfaceVariant = Color(0xFFA9A399);
    const outline = Color(0xFF3A362E);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.green,
        surface: surface,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        error: AppColors.coral,
      ),
      scaffoldBackgroundColor: background,
      cardColor: surface,
      dividerColor: outline,
      fontFamily: 'PlusJakartaSans',

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: AppColors.white,
          textStyle: AppTextStyles.button,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        hintStyle: const TextStyle(fontFamily: 'Inter', color: onSurfaceVariant, fontSize: 14),
        errorStyle: AppTextStyles.errorStyle,
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: AppColors.green, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }
}
