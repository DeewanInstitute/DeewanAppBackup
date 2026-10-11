import 'package:deewan_institute_app/core/app_bottom_nav.dart';
import 'package:deewan_institute_app/core/app_colors.dart';
import 'package:deewan_institute_app/core/app_loading.dart';
import 'package:deewan_institute_app/core/app_top_nav.dart';
import 'package:deewan_institute_app/flashcards/review_incorrect_page.dart';
import 'package:deewan_institute_app/podcasts/podcast_models.dart';
import 'package:deewan_institute_app/podcasts/podcast_playback_controller.dart';
import 'package:deewan_institute_app/podcasts/podcast_player.dart';
import 'package:deewan_institute_app/word_search/word_search_page.dart';
import 'package:flutter/material.dart';

class EpisodeDetails extends StatelessWidget {
  const EpisodeDetails({
    super.key,
    required this.season,
    required this.episodeIndex,
  });

  final PodcastSeason season;
  final int episodeIndex;

  EpisodeData get episode => season.episodes[episodeIndex];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 126),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppTopNav(),
              const SizedBox(height: 42),
              _SeasonArtwork(season: season),
              const SizedBox(height: 34),
              _EpisodeMeta(season: season, episode: episode),
              const SizedBox(height: 24),
              Text(
                episode.title,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontFamily: 'Prociono',
                  fontSize: 36,
                  height: 1.16,
                ),
              ),
              const SizedBox(height: 22),
              if (episode.description.isNotEmpty)
                Text(
                  episode.description,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 18,
                    height: 1.55,
                  ),
                )
              else
                const SizedBox(height: 60),
              const SizedBox(height: 54),
              FilledButton.icon(
                onPressed: () => AppLoading.navigate(
                  context,
                  PodcastPlayer(
                    season: season,
                    initialEpisodeIndex: episodeIndex,
                  ),
                ),
                icon: const Icon(Icons.play_circle_outline_rounded, size: 28),
                label: const Text(
                  'Play Episode',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size.fromHeight(62),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: -1,
        onTap: (index) {
          PodcastPlaybackController.instance.stop();
          if (index == 0) {
            Navigator.popUntil(context, (route) => route.isFirst);
          } else if (index == 1) {
            AppLoading.navigate(context, const WordSearchPage());
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReviewIncorrectPage()),
            );
          }
        },
      ),
    );
  }
}

class _SeasonArtwork extends StatelessWidget {
  const _SeasonArtwork({required this.season});

  final PodcastSeason season;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.podcastSeasonImageBackground(
            season.episodes.first.artColor,
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: AppColors.podcastSeasonImageBorder(
              season.episodes.first.artColor,
            ),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: season.imageAssetPath == null || season.imageAssetPath!.isEmpty
            ? const SizedBox.shrink()
            : Image.asset(
                season.imageAssetPath!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
      ),
    );
  }
}

class _EpisodeMeta extends StatelessWidget {
  const _EpisodeMeta({required this.season, required this.episode});

  final PodcastSeason season;
  final EpisodeData episode;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            season.title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.orange,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _MetaPill(label: season.level, color: AppColors.green),
        const SizedBox(width: 8),
        _MetaPill(
          label: episode.durationMinutes == null
              ? '-- min'
              : '${episode.durationMinutes} min',
          color: AppColors.ink,
        ),
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.podcastMetaPill,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
