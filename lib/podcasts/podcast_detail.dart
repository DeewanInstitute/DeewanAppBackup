import 'package:deewan_institute_app/core/app_bottom_nav.dart';
import 'package:deewan_institute_app/core/app_colors.dart';
import 'package:deewan_institute_app/core/app_drawer.dart';
import 'package:deewan_institute_app/core/app_loading.dart';
import 'package:deewan_institute_app/core/app_top_nav.dart';
import 'package:deewan_institute_app/flashcards/review_incorrect_page.dart';
import 'package:deewan_institute_app/podcasts/episode_details.dart';
import 'package:deewan_institute_app/podcasts/podcast_models.dart';
import 'package:deewan_institute_app/podcasts/podcast_player.dart';
import 'package:deewan_institute_app/word_search/word_search_page.dart';
import 'package:flutter/material.dart';

class PodcastDetail extends StatelessWidget {
  const PodcastDetail({super.key, required this.podcast});

  final PodcastData podcast;

  // Swap this list later with API / Firestore data.
  static const List<_SeasonDetailData> _seasons = [
    _SeasonDetailData(
      label: 'Arabic Daily',
      seasonNumber: 1,
      seasonTitle: 'Season 1',
      topicTitle: 'At the Market',
      aboutTitle: 'About This Season',
      description:
          'Learn essential Arabic vocabulary and phrases used in everyday market situations. Perfect for beginners exploring real-world conversations.',
      episodeCount: '6 Episodes',
      averageDuration: '~18 min avg',
      level: 'Beginner',
      gradient: AppColors.podcastRedGradient,
      imageAssetPath: null,
      episodes: [
        _SeasonEpisodeData(id: 'E1', title: 'Greetings at the Market', duration: '12 min'),
        _SeasonEpisodeData(id: 'E2', title: 'Buying Fruits', duration: '10 min'),
        _SeasonEpisodeData(id: 'E3', title: 'Asking for Prices', duration: '15 min'),
        _SeasonEpisodeData(id: 'E4', title: 'Colors & Quantities', duration: '11 min'),
        _SeasonEpisodeData(id: 'E5', title: 'Paying & Change', duration: '09 min'),
        _SeasonEpisodeData(id: 'E6', title: 'Review & Practice', duration: '14 min'),
      ],
    ),
    _SeasonDetailData(
      label: 'Arabic Daily',
      seasonNumber: 2,
      seasonTitle: 'Season 2',
      topicTitle: 'Daily Life',
      aboutTitle: 'About This Season',
      description:
          'Practice useful Arabic phrases for home, errands, routines, and everyday conversations.',
      episodeCount: '5 Episodes',
      averageDuration: '~16 min avg',
      level: 'Beginner',
      gradient: AppColors.podcastGreenGradient,
      imageAssetPath: null,
      episodes: [
        _SeasonEpisodeData(id: 'E1', title: 'Morning Routines', duration: '13 min'),
        _SeasonEpisodeData(id: 'E2', title: 'At Home', duration: '15 min'),
        _SeasonEpisodeData(id: 'E3', title: 'Running Errands', duration: '17 min'),
        _SeasonEpisodeData(id: 'E4', title: 'Making Plans', duration: '16 min'),
        _SeasonEpisodeData(id: 'E5', title: 'Daily Review', duration: '14 min'),
      ],
    ),
    _SeasonDetailData(
      label: 'Arabic Daily',
      seasonNumber: 3,
      seasonTitle: 'Season 3',
      topicTitle: 'Culture & Traditions',
      aboutTitle: 'About This Season',
      description:
          'Explore cultural phrases, hospitality, celebrations, and traditions through guided listening.',
      episodeCount: '7 Episodes',
      averageDuration: '~20 min avg',
      level: 'Intermediate',
      gradient: AppColors.podcastBlackGradient,
      imageAssetPath: null,
      episodes: [
        _SeasonEpisodeData(id: 'E1', title: 'Hospitality', duration: '18 min'),
        _SeasonEpisodeData(id: 'E2', title: 'Family Visits', duration: '20 min'),
        _SeasonEpisodeData(id: 'E3', title: 'Celebrations', duration: '22 min'),
        _SeasonEpisodeData(id: 'E4', title: 'Food Traditions', duration: '19 min'),
        _SeasonEpisodeData(id: 'E5', title: 'Polite Expressions', duration: '17 min'),
        _SeasonEpisodeData(id: 'E6', title: 'Stories & Proverbs', duration: '21 min'),
        _SeasonEpisodeData(id: 'E7', title: 'Culture Review', duration: '16 min'),
      ],
    ),
    _SeasonDetailData(
      label: 'Arabic Daily',
      seasonNumber: 4,
      seasonTitle: 'Season 4',
      topicTitle: 'Travel & Transport',
      aboutTitle: 'About This Season',
      description:
          'Learn travel vocabulary for taxis, buses, directions, tickets, and getting around confidently.',
      episodeCount: '8 Episodes',
      averageDuration: '~18 min avg',
      level: 'Intermediate',
      gradient: AppColors.podcastYellowGradient,
      imageAssetPath: null,
      episodes: [
        _SeasonEpisodeData(id: 'E1', title: 'Asking Directions', duration: '15 min'),
        _SeasonEpisodeData(id: 'E2', title: 'Taking a Taxi', duration: '18 min'),
        _SeasonEpisodeData(id: 'E3', title: 'Bus Station', duration: '16 min'),
        _SeasonEpisodeData(id: 'E4', title: 'Buying Tickets', duration: '17 min'),
        _SeasonEpisodeData(id: 'E5', title: 'Hotel Check-in', duration: '20 min'),
        _SeasonEpisodeData(id: 'E6', title: 'Lost & Found', duration: '14 min'),
        _SeasonEpisodeData(id: 'E7', title: 'Travel Problems', duration: '19 min'),
        _SeasonEpisodeData(id: 'E8', title: 'Transport Review', duration: '13 min'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final season = _seasonForPodcast(podcast);

    return Scaffold(
      backgroundColor: AppColors.cream,
      extendBody: true,
      drawer: const AppDrawer(selectedIndex: AppDrawer.podcastsIndex),
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 126),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppTopNav(),
                  const SizedBox(height: 48),
                  _SeasonHeroCard(season: season),
                  const SizedBox(height: 34),
                  _AboutSeason(season: season),
                  const SizedBox(height: 26),
                  _PlayAllButton(
                    onTap: () => _openPlayer(context, season, season.episodes.first),
                  ),
                  const SizedBox(height: 34),
                  const _SectionTitle('Episodes'),
                  const SizedBox(height: 20),
                  ...season.episodes.map(
                    (episode) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _EpisodeTile(
                        episode: episode,
                        onTap: () => _openEpisode(context, season, episode),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: -1,
        onTap: (index) {
          if (index == 0) {
            Navigator.popUntil(context, (route) => route.isFirst);
            return;
          }
          if (index == 1) {
            AppLoading.navigate(context, const WordSearchPage());
            return;
          }
          if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewIncorrectPage()));
          }
        },
      ),
    );
  }

  _SeasonDetailData _seasonForPodcast(PodcastData podcast) {
    final title = podcast.title.toLowerCase();

    for (final season in _seasons) {
      if (title.contains('season ${season.seasonNumber}') ||
          title.contains(season.topicTitle.toLowerCase())) {
        return season;
      }
    }

    for (final season in _seasons) {
      if (podcast.bgColor == season.gradient.colors.last ||
          podcast.bgColor == season.gradient.colors.first) {
        return season;
      }
    }

    return _seasons.first;
  }

  void _openEpisode(
    BuildContext context,
    _SeasonDetailData season,
    _SeasonEpisodeData episode,
  ) {
    AppLoading.navigate(
      context,
      EpisodeDetails(
        podcast: PodcastData(
          title: season.label,
          description: season.description,
          bgColor: season.gradient.colors.last,
          artColor: AppColors.orange,
        ),
        episode: EpisodeData(
          title: episode.title,
          podcast: season.label,
          duration: episode.duration,
          artColor: AppColors.orange,
        ),
        seasonGradient: season.gradient,
        level: season.level,
      ),
    );
  }

  void _openPlayer(
    BuildContext context,
    _SeasonDetailData season,
    _SeasonEpisodeData episode,
  ) {
    AppLoading.navigate(
      context,
      PodcastPlayer(
        podcast: PodcastData(
          title: season.label,
          description: season.description,
          bgColor: season.gradient.colors.last,
          artColor: AppColors.orange,
        ),
        episode: EpisodeData(
          title: episode.title,
          podcast: season.label,
          duration: episode.duration,
          artColor: AppColors.orange,
        ),
      ),
    );
  }
}

class _SeasonHeroCard extends StatelessWidget {
  const _SeasonHeroCard({required this.season});

  final _SeasonDetailData season;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(26, 28, 26, 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: season.gradient,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  season.label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const Spacer(),
                Text(
                  season.seasonTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Lora',
                    fontSize: 41,
                    fontWeight: FontWeight.w500,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  season.topicTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          _SeasonImagePlaceholder(imageAssetPath: season.imageAssetPath),
        ],
      ),
    );
  }
}

class _SeasonImagePlaceholder extends StatelessWidget {
  const _SeasonImagePlaceholder({required this.imageAssetPath});

  final String? imageAssetPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 125,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageAssetPath == null
          ? const SizedBox.shrink()
          : Image.asset(
              imageAssetPath!,
              fit: BoxFit.cover,
            ),
      // TODO: Add the real season image later.
      // Example:
      // child: Image.asset('assets/images/podcasts/season_market.png', fit: BoxFit.cover),
    );
  }
}

class _AboutSeason extends StatelessWidget {
  const _AboutSeason({required this.season});

  final _SeasonDetailData season;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          season.aboutTitle.toUpperCase(),
          style: const TextStyle(
            color: AppColors.green,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          season.description,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 18,
            fontWeight: FontWeight.w500,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InfoPill(season.episodeCount),
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EDE3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

class _PlayAllButton extends StatelessWidget {
  const _PlayAllButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 65,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.play_circle_outline_rounded, size: 28),
        label: const Text(
          'Play All',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(34),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.green,
        fontFamily: 'Lora',
        fontSize: 27,
        fontWeight: FontWeight.w600,
        height: 1,
      ),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile({
    required this.episode,
    required this.onTap,
  });

  final _SeasonEpisodeData episode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 76,
          padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.green,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  episode.id,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 16),
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
                        color: AppColors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      episode.duration,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.orange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeasonDetailData {
  const _SeasonDetailData({
    required this.label,
    required this.seasonNumber,
    required this.seasonTitle,
    required this.topicTitle,
    required this.aboutTitle,
    required this.description,
    required this.episodeCount,
    required this.averageDuration,
    required this.level,
    required this.gradient,
    required this.imageAssetPath,
    required this.episodes,
  });

  final String label;
  final int seasonNumber;
  final String seasonTitle;
  final String topicTitle;
  final String aboutTitle;
  final String description;
  final String episodeCount;
  final String averageDuration;
  final String level;
  final LinearGradient gradient;
  final String? imageAssetPath;
  final List<_SeasonEpisodeData> episodes;
}

class _SeasonEpisodeData {
  const _SeasonEpisodeData({
    required this.id,
    required this.title,
    required this.duration,
  });

  final String id;
  final String title;
  final String duration;
}
