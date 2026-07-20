import 'package:deewan_institute_app/core/app_bottom_nav.dart';
import 'package:deewan_institute_app/core/app_colors.dart';
import 'package:deewan_institute_app/core/app_drawer.dart';
import 'package:deewan_institute_app/core/app_loading.dart';
import 'package:deewan_institute_app/core/app_top_nav.dart';
import 'package:deewan_institute_app/flashcards/review_incorrect_page.dart';
import 'package:deewan_institute_app/podcasts/podcast_detail.dart';
import 'package:deewan_institute_app/podcasts/podcast_models.dart';
import 'package:deewan_institute_app/podcasts/podcast_playback_controller.dart';
import 'package:deewan_institute_app/podcasts/podcast_player.dart';
import 'package:deewan_institute_app/word_search/word_search_page.dart';
import 'package:flutter/material.dart';

class PodcastHome extends StatefulWidget {
  const PodcastHome({super.key});

  @override
  State<PodcastHome> createState() => _PodcastHomeState();
}

class _PodcastHomeState extends State<PodcastHome> {
  @override
  void dispose() {
    PodcastPlaybackController.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      extendBody: true,
      drawer: const AppDrawer(selectedIndex: AppDrawer.podcastsIndex),
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<List<PodcastSeason>>(
          future: PodcastCatalog.load(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _CatalogError(onRetry: () => PodcastCatalog.load());
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final seasons = snapshot.data!;
            final featuredSeason = seasons.last;
            final featuredEpisode = featuredSeason.episodes.last;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 210),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppTopNav(),
                  const SizedBox(height: 58),
                  const Text(
                    'Podcasts',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontFamily: 'Prociono',
                      fontSize: 45,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Listen & Learn Arabic',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 38),
                  const _SectionTitle('Latest Episode'),
                  const SizedBox(height: 20),
                  _FeaturedEpisode(
                    season: featuredSeason,
                    episode: featuredEpisode,
                  ),
                  const SizedBox(height: 38),
                  const _SectionTitle('Seasons'),
                  const SizedBox(height: 20),
                  ...seasons.map(
                    (season) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _SeasonCard(season: season),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _PodcastBottomArea(
        onNavigate: (index) {
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

class _PodcastBottomArea extends StatelessWidget {
  const _PodcastBottomArea({required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final playback = PodcastPlaybackController.instance;
    return AnimatedBuilder(
      animation: playback,
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (playback.hasTrack) _MiniPodcastPlayer(playback: playback),
          AppBottomNav(currentIndex: -1, onTap: onNavigate),
        ],
      ),
    );
  }
}

class _MiniPodcastPlayer extends StatelessWidget {
  const _MiniPodcastPlayer({required this.playback});

  final PodcastPlaybackController playback;

  @override
  Widget build(BuildContext context) {
    final season = playback.season!;
    final episode = playback.episode!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Material(
        color: AppColors.podcastPlayerBackground,
        borderRadius: BorderRadius.circular(20),
        elevation: 8,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PodcastPlayer(
                season: season,
                initialEpisodeIndex: playback.episodeIndex,
              ),
            ),
          ),
          child: SizedBox(
            height: 72,
            child: Stack(
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(20),
                      ),
                      child: SizedBox(
                        width: 72,
                        height: 72,
                        child: season.imageAssetPath == null
                            ? const ColoredBox(color: AppColors.cream)
                            : Image.asset(
                                season.imageAssetPath!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const ColoredBox(color: AppColors.cream),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            episode.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            season.title,
                            style: const TextStyle(
                              color: AppColors.cream,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: playback.toggle,
                      icon: playback.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: AppColors.green,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              playback.isPlaying
                                  ? Icons.pause_circle_filled_rounded
                                  : Icons.play_circle_fill_rounded,
                              color: AppColors.green,
                              size: 38,
                            ),
                    ),
                    const SizedBox(width: 6),
                  ],
                ),
                Positioned(
                  left: 72,
                  right: 0,
                  bottom: 0,
                  child: LinearProgressIndicator(
                    value: playback.progress,
                    minHeight: 3,
                    backgroundColor: AppColors.podcastWhite12,
                    valueColor: const AlwaysStoppedAnimation(AppColors.green),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.green,
        fontFamily: 'Prociono',
        fontSize: 27,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _FeaturedEpisode extends StatelessWidget {
  const _FeaturedEpisode({required this.season, required this.episode});

  final PodcastSeason season;
  final EpisodeData episode;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: episode.artColor,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => AppLoading.navigate(
          context,
          PodcastPlayer(
            season: season,
            initialEpisodeIndex: season.episodes.length - 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              _BlankArtwork(size: 86, imageAssetPath: season.imageAssetPath),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      season.title.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.cream,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      episode.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontFamily: 'Prociono',
                        fontSize: 21,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Hosted by ${season.hostedBy}',
                      style: const TextStyle(
                        color: AppColors.cream,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.play_circle_fill_rounded,
                color: AppColors.white,
                size: 44,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeasonCard extends StatelessWidget {
  const _SeasonCard({required this.season});

  final PodcastSeason season;

  @override
  Widget build(BuildContext context) {
    final color = PodcastCatalog.seasonColors[season.seasonNumber - 1];
    return Material(
      color: color.colors.first,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () =>
            AppLoading.navigate(context, PodcastDetail(season: season)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              _BlankArtwork(size: 92, imageAssetPath: season.imageAssetPath),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      season.title,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontFamily: 'Prociono',
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Hosted by ${season.hostedBy}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.cream,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      season.episodeCount,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.white,
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlankArtwork extends StatelessWidget {
  const _BlankArtwork({required this.size, this.imageAssetPath});

  final double size;
  final String? imageAssetPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cream),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageAssetPath == null
          ? const SizedBox.shrink()
          : Image.asset(
              imageAssetPath!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
    );
  }
}

class _CatalogError extends StatelessWidget {
  const _CatalogError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Unable to load podcasts.'),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
