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

  static const cream = Color(0xFFFFF8F1);
  static const green = Color.fromRGBO(93, 203, 169, 1.0);
  static const coral = Color.fromRGBO(249, 65, 68, 1.0);
  static const orange = Color(0xFFFF7327);
  static const ink = Color(0xFF1F1E28);
  static const muted = Color(0xFF8F8C88);

  static const podcastChipBorder = Color(0xFF8F8C88);
  static const podcastCoverOrange = Color(0xFFF47A2A);
  static const podcastSeasonGreen = Color.fromRGBO(93, 203, 169, 1.0);
  static const podcastSeasonBlack = Color(0xFF0B1020);
  static const podcastSeasonYellow = Color(0xFFFFB814);
  static const podcastBadgeLight = Color(0xFFFF777A);
  static const podcastDarkBadge = Color(0xFF444B59);
  static const podcastYellowBadge = Color(0xFFFFCE56);
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
    colors: [
      Color(0xFFFFF8F1),
      Color(0xFF0B1020),
    ],
  );
  static const podcastYellowGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF59E0B),
      Color(0xFFFBBF24),
    ],
  );
}
