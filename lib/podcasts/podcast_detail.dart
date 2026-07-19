import 'package:deewan_institute_app/core/app_bottom_nav.dart';
import 'package:deewan_institute_app/core/app_colors.dart';
import 'package:deewan_institute_app/core/app_drawer.dart';
import 'package:deewan_institute_app/core/app_loading.dart';
import 'package:deewan_institute_app/core/app_top_nav.dart';
import 'package:deewan_institute_app/flashcards/review_incorrect_page.dart';
import 'package:deewan_institute_app/podcasts/episode_details.dart';
import 'package:deewan_institute_app/podcasts/podcast_models.dart';
import 'package:deewan_institute_app/podcasts/podcast_playback_controller.dart';
import 'package:deewan_institute_app/podcasts/podcast_player.dart';
import 'package:deewan_institute_app/word_search/word_search_page.dart';
import 'package:flutter/material.dart';

class PodcastDetail extends StatelessWidget {
  const PodcastDetail({super.key, required this.season});

  final PodcastSeason season;

  @override
  Widget build(BuildContext context) {
    final color = PodcastCatalog.seasonColors[season.seasonNumber - 1];
    return Scaffold(
      backgroundColor: AppColors.cream,
      extendBody: true,
      drawer: const AppDrawer(selectedIndex: AppDrawer.podcastsIndex),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 126),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppTopNav(),
              const SizedBox(height: 42),
              _SeasonHeader(season: season, color: color.colors.first),
              const SizedBox(height: 34),
              _AboutSeason(season: season),
              const SizedBox(height: 30),
              FilledButton.icon(
                onPressed: () => AppLoading.navigate(
                  context,
                  PodcastPlayer(season: season, initialEpisodeIndex: 0),
                ),
                icon: const Icon(Icons.play_circle_outline_rounded),
                label: const Text('Play All'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size.fromHeight(58),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              const SizedBox(height: 34),
              Text(
                'Episodes',
                style: const TextStyle(
                  color: AppColors.green,
                  fontFamily: 'Prociono',
                  fontSize: 27,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ...List.generate(
                season.episodes.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _EpisodeTile(
                    episode: season.episodes[index],
                    onTap: () => AppLoading.navigate(
                      context,
                      EpisodeDetails(season: season, episodeIndex: index),
                    ),
                    onPlay: () => AppLoading.navigate(
                      context,
                      PodcastPlayer(season: season, initialEpisodeIndex: index),
                    ),
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

class _AboutSeason extends StatelessWidget {
  const _AboutSeason({required this.season});

  final PodcastSeason season;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ABOUT THIS SEASON',
          style: TextStyle(
            color: AppColors.green,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 18),
        if (season.about.isNotEmpty)
          Text(
            season.about,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 17,
              height: 1.5,
            ),
          )
        else
          const SizedBox(height: 30),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InfoPill('${season.episodes.length} Episodes'),
            _InfoPill(season.averageDuration),
            _InfoPill(season.level),
          ],
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.podcastInfoPill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SeasonHeader extends StatelessWidget {
  const _SeasonHeader({required this.season, required this.color});

  final PodcastSeason season;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.cream),
            ),
            clipBehavior: Clip.antiAlias,
            child: season.imageAssetPath == null
                ? const SizedBox.shrink()
                : Image.asset(
                    season.imageAssetPath!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  season.title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontFamily: 'Prociono',
                    fontSize: 32,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Hosted by ${season.hostedBy}',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  season.episodeCount,
                  style: const TextStyle(color: AppColors.cream, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile({
    required this.episode,
    required this.onTap,
    required this.onPlay,
  });

  final EpisodeData episode;
  final VoidCallback onTap;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: episode.artColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${episode.id}',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      episode.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      episode.durationMinutes == null
                          ? '-- min'
                          : '${episode.durationMinutes} min',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: onPlay,
                icon: const Icon(
                  Icons.play_circle_fill_rounded,
                  color: AppColors.orange,
                  size: 44,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
