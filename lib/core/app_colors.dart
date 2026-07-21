import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color.fromRGBO(143, 110, 67, 1);
  static const Color primaryLight = Color(0xFFF5F0EA);
  static const Color primaryBorder = Color(0xFFE0D5C5);

  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color textMuted = Colors.black54;
  static const Color textHint = Colors.black26;
  static const Color error = Colors.red;
  static const Color link = Color.fromRGBO(143, 110, 67, 1);
  static const Color purple = Color(0xFF8B5CF6);

  static const cream = Color(0xFFFFF8F1);
  static const green = Color(0xFF43AA8B);
  static const coral = Color(0xFFF94144);
  static const orange = Color(0xFFF3722C);
  static const ink = Color(0xFF1F1E28);
  static const muted = Color(0xFF8F8C88);

  static const podcastPlayerBackground = Color(0xFF1D1B20);
  static const podcastInfoPill = Color(0xFFF0E9DD);
  static const podcastMetaPill = Color(0xFFECE7DD);
  static const podcastWhite12 = Color(0x20FFFFFF);

  static const podcastAccentOverlay = Color(0x2643AA8B);
  static const podcastAccentGlow = Color(0x6643AA8B);
  static const podcastAccentStrongGlow = Color(0xB343AA8B);
  static const podcastPlaybackError = Color(0xFFFF5252);
  static Color podcastSeasonImageBackground(Color seasonColor) =>
      seasonColor.withValues(alpha: 0.16);

  static Color podcastSeasonImageBorder(Color seasonColor) =>
      seasonColor.withValues(alpha: 0.22);
  static const podcastRedGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF3722C), Color(0xFFF94144)],
  );
  static const podcastGreenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF43AA8B), Color(0xFF2D6A4F)],
  );
  static const podcastBlackGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0B1020), Color.fromARGB(255, 79, 82, 94)],
  );
  static const podcastYellowGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
  );
  static const podcastPurpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
  );
}
