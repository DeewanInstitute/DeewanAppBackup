import 'dart:convert';

import 'package:deewan_institute_app/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CourseData {
  const CourseData({
    required this.id,
    required this.title,
    required this.icon,
    required this.theme,
    required this.isNew,
    required this.heroLetter,
    required this.formats,
    required this.registrationDetails,
    required this.courseDetails,
    required this.websiteUrl,
  });

  final String id;
  final String title;
  final String icon;
  final String theme;
  final bool isNew;
  final String heroLetter;
  final List<String> formats;
  final String registrationDetails;
  final String courseDetails;
  final String websiteUrl;

  LinearGradient get gradient => switch (theme) {
    'conversation' => AppColors.courseConversationGradient,
    'dark' => AppColors.courseDarkGradient,
    'calligraphy' => AppColors.courseCalligraphyGradient,
    'business' => AppColors.courseBusinessGradient,
    'quran' => AppColors.courseQuranGradient,
    _ => AppColors.courseAlphabetGradient,
  };

  IconData get iconData => switch (icon) {
    'conversation' => Icons.chat_bubble_outline_rounded,
    'book' => Icons.menu_book_outlined,
    'pen' => Icons.edit_outlined,
    'business' => Icons.business_center_outlined,
    'quran' => Icons.nightlight_round,
    _ => Icons.alternate_email_rounded,
  };

  factory CourseData.fromJson(Map<String, dynamic> json) {
    return CourseData(
      id: json['id'] as String,
      title: json['title'] as String,
      icon: json['icon'] as String? ?? 'book',
      theme: json['theme'] as String? ?? 'alphabet',
      isNew: json['isNew'] as bool? ?? false,
      heroLetter: json['heroLetter'] as String? ?? '',
      formats: (json['formats'] as List<dynamic>? ?? const []).cast<String>(),
      registrationDetails: json['registrationDetails'] as String? ?? '',
      courseDetails: json['courseDetails'] as String? ?? '',
      websiteUrl: json['websiteUrl'] as String? ?? '',
    );
  }
}

class CourseCatalog {
  CourseCatalog._();

  static Future<List<CourseData>>? _cache;

  static Future<List<CourseData>> load() => _cache ??= _load();

  static Future<List<CourseData>> _load() async {
    final source = await rootBundle.loadString('assets/data/courses.json');
    final json = jsonDecode(source) as Map<String, dynamic>;
    return (json['courses'] as List<dynamic>)
        .map((item) => CourseData.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }
}
