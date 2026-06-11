import 'package:flutter/material.dart';

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
  final String title;
  final String podcast;
  final String duration;
  final Color artColor;
  const EpisodeData({
    required this.title,
    required this.podcast,
    required this.duration,
    required this.artColor,
  });
}
