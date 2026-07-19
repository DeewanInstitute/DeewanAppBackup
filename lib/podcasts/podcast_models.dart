import 'dart:convert';

import 'package:deewan_institute_app/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PodcastData {
  final String title;
  final String description;
  final Color bgColor;
  final Color artColor;

  const PodcastData({
    required this.title,
    required this.description,
    required this.bgColor,
    required this.artColor,
  });
}

class EpisodeData {
  final int id;
  final String title;
  final String podcast;
  final String audioUrl;
  final String duration;
  final int? durationMinutes;
  final String description;
  final Color artColor;

  const EpisodeData({
    this.id = 0,
    required this.title,
    required this.podcast,
    this.audioUrl = '',
    this.duration = '',
    this.durationMinutes,
    this.description = '',
    required this.artColor,
  });

  factory EpisodeData.fromJson(
    Map<String, dynamic> json, {
    required String podcast,
    required Color artColor,
  }) {
    return EpisodeData(
      id: json['id'] as int,
      title: json['title'] as String,
      podcast: podcast,
      audioUrl: json['audioUrl'] as String,
      durationMinutes: json['durationMinutes'] as int?,
      description: json['description'] as String? ?? '',
      artColor: artColor,
    );
  }
}

class PodcastSeason {
  final int seasonNumber;
  final String hostedBy;
  final String? imageAssetPath;
  final String about;
  final int? averageMinutes;
  final String level;
  final List<EpisodeData> episodes;

  const PodcastSeason({
    required this.seasonNumber,
    required this.hostedBy,
    required this.imageAssetPath,
    required this.about,
    required this.averageMinutes,
    required this.level,
    required this.episodes,
  });

  String get title => 'Season $seasonNumber';
  String get episodeCount => '${episodes.length} episodes';
  int? get resolvedAverageMinutes {
    if (averageMinutes != null) return averageMinutes;
    final knownDurations = episodes
        .map((episode) => episode.durationMinutes)
        .whereType<int>()
        .toList(growable: false);
    if (knownDurations.isEmpty) return null;
    final total = knownDurations.fold<int>(0, (sum, value) => sum + value);
    return (total / knownDurations.length).round();
  }

  String get averageDuration {
    final minutes = resolvedAverageMinutes;
    return minutes == null ? '~-- min avg' : '~$minutes min avg';
  }

  PodcastData get podcast => PodcastData(
        title: title,
        description: 'Hosted by $hostedBy',
        bgColor: AppColors.ink,
        artColor: AppColors.green,
      );

  factory PodcastSeason.fromJson(Map<String, dynamic> json) {
    final number = json['seasonNumber'] as int;
    final host = json['hostedBy'] as String;
    final color = PodcastCatalog.seasonColors[(number - 1) %
        PodcastCatalog.seasonColors.length];

    return PodcastSeason(
      seasonNumber: number,
      hostedBy: host,
      imageAssetPath: json['imageAssetPath'] as String?,
      about: json['about'] as String? ?? '',
      averageMinutes: json['averageMinutes'] as int?,
      level: json['level'] as String? ?? 'Beginner',
      episodes: (json['episodes'] as List<dynamic>)
          .map(
            (episode) => EpisodeData.fromJson(
              episode as Map<String, dynamic>,
              podcast: 'Season $number',
              artColor: color.colors.first,
            ),
          )
          .toList(growable: false),
    );
  }
}

class PodcastCatalog {
  PodcastCatalog._();

  static const seasonColors = <LinearGradient>[
    AppColors.podcastRedGradient,
    AppColors.podcastGreenGradient,
    AppColors.podcastBlackGradient,
    AppColors.podcastYellowGradient,
    AppColors.podcastPurpleGradient,
  ];

  static Future<List<PodcastSeason>>? _cached;

  static Future<List<PodcastSeason>> load() {
    return _cached ??= _load();
  }

  static Future<List<PodcastSeason>> _load() async {
    final source = await rootBundle.loadString('assets/data/podcasts.json');
    final json = jsonDecode(source) as Map<String, dynamic>;
    return (json['seasons'] as List<dynamic>)
        .map((season) => PodcastSeason.fromJson(season as Map<String, dynamic>))
        .toList(growable: false);
  }
}
