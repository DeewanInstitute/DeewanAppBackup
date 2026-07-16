import 'package:deewan_institute_app/core/app_bottom_nav.dart';
import 'package:deewan_institute_app/core/app_colors.dart';
import 'package:deewan_institute_app/core/app_drawer.dart';
import 'package:deewan_institute_app/core/app_loading.dart';
import 'package:deewan_institute_app/core/app_top_nav.dart';
import 'package:deewan_institute_app/podcasts/podcast_detail.dart';
import 'package:deewan_institute_app/podcasts/podcast_models.dart';
import 'package:deewan_institute_app/podcasts/podcast_player.dart';
import 'package:deewan_institute_app/flashcards/review_incorrect_page.dart';
import 'package:deewan_institute_app/word_search/word_search_page.dart';
import 'package:flutter/material.dart';

class PodcastHome extends StatefulWidget {
  const PodcastHome({super.key});

  @override
  State<PodcastHome> createState() => _PodcastHomeState();
}

class _PodcastHomeState extends State<PodcastHome> {
  int _selectedFilter = 0;

  static const _filters = ['All', 'Beginner', 'Intermediate', 'Advanced'];

  final PodcastData _featuredPodcast = const PodcastData(
    title: 'Episode 12: At the Market',
    description:
        'Arabic Daily helps you build listening confidence through simple, practical conversations.',
    bgColor: AppColors.coral,
    artColor: AppColors.podcastCoverOrange,
  );

  final EpisodeData _featuredEpisode = const EpisodeData(
    title: 'Episode 12: At the Market',
    podcast: 'Arabic Daily',
    duration: '18:24',
    artColor: AppColors.podcastCoverOrange,
  );

  final List<_SeasonData> _seasons = const [
    _SeasonData(
      number: '1',
      title: 'At the Market',
      episodes: '6 eps',
      color: AppColors.podcastRedGradient,
      accentColor: AppColors.podcastBadgeLight,
    ),
    _SeasonData(
      number: '2',
      title: 'Daily Life',
      episodes: '5 eps',
      color: AppColors.podcastGreenGradient,
      accentColor: Color(0xFF43AA8B),
    ),
    _SeasonData(
      number: '3',
      title: 'Culture &\nTraditions',
      episodes: '7 eps',
      color: AppColors.podcastBlackGradient,
      accentColor: AppColors.podcastDarkBadge,
    ),
    _SeasonData(
      number: '4',
      title: 'Travel &\nTransport',
      episodes: '8 eps',
      color: AppColors.podcastYellowGradient,
      accentColor: AppColors.podcastYellowBadge,
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
                  const SizedBox(height: 58),
                  const _PodcastHeroText(),
                  const SizedBox(height: 30),
                  _FilterChips(
                    filters: _filters,
                    selectedIndex: _selectedFilter,
                    onSelected: (index) {
                      setState(() => _selectedFilter = index);
                    },
                  ),
                  const SizedBox(height: 34),
                  const _SectionTitle('Featured'),
                  const SizedBox(height: 22),
                  _FeaturedEpisodeCard(
                    podcast: _featuredPodcast,
                    episode: _featuredEpisode,
                  ),
                  const SizedBox(height: 34),
                  const _SectionTitle('Seasons'),
                  const SizedBox(height: 22),
                  _SeasonsGrid(seasons: _seasons),
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
}

class _PodcastHeroText extends StatelessWidget {
  const _PodcastHeroText();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Podcasts',
          style: TextStyle(
            color: AppColors.ink,
            fontFamily: 'Prociono',
            fontSize: 45,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Listen & Learn Arabic',
          style: TextStyle(
            color: Color(0xFF898783),
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.filters,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> filters;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      child: ListView.separated(
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = selectedIndex == index;

          return Material(
            color: selected ? AppColors.green : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: selected
                      ? null
                      : Border.all(
                          color: AppColors.podcastChipBorder,
                          width: 1.3,
                        ),
                ),
                alignment: Alignment.center,
                child: Text(
                  filters[index],
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          );
        },
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
        fontFamily: 'Prociono',
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1,
      ),
    );
  }
}

class _FeaturedEpisodeCard extends StatelessWidget {
  const _FeaturedEpisodeCard({required this.podcast, required this.episode});

  final PodcastData podcast;
  final EpisodeData episode;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          AppLoading.navigate(context, PodcastDetail(podcast: podcast)),
      child: Container(
        height: 288,
        width: double.infinity,
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.orange, AppColors.coral],
          ),
        ),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _PodcastCoverArt(),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        episode.podcast.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        episode.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Prociono',
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Positioned(
              right: 0,
              bottom: 8,
              child: FilledButton.icon(
                onPressed: () => AppLoading.navigate(
                  context,
                  PodcastPlayer(podcast: podcast, episode: episode),
                ),
                icon: const Icon(Icons.play_circle_outline_rounded, size: 22),
                label: const Text(
                  'Play Now',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.coral,
                  minimumSize: const Size(146, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PodcastCoverArt extends StatelessWidget {
  const _PodcastCoverArt();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 85,
      height: 85,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const RadialGradient(
          center: Alignment.topLeft,
          radius: 1.15,
          colors: [
            Color(0xFFFFC14A),
            AppColors.podcastCoverOrange,
            AppColors.coral,
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Image(
            image: AssetImage('assets/images/logos/logo.png'),
            width: 85,
            height: 85,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}

class _SeasonsGrid extends StatelessWidget {
  const _SeasonsGrid({required this.seasons});

  final List<_SeasonData> seasons;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
        childAspectRatio: 0.96,
      ),
      itemCount: seasons.length,
      itemBuilder: (context, index) {
        return _SeasonCard(season: seasons[index]);
      },
    );
  }
}

class _SeasonCard extends StatelessWidget {
  const _SeasonCard({required this.season});

  final _SeasonData season;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => AppLoading.navigate(
        context,
        PodcastDetail(
          podcast: PodcastData(
            title:
                'Season ${season.number}: ${season.title.replaceAll('\n', ' ')}',
            description:
                'Practice Arabic listening through ${season.title.toLowerCase().replaceAll('\n', ' ')} episodes.',
            bgColor: season.color.colors.last,
            artColor: season.accentColor,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: season.color,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: Text(
                season.number,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Prociono',
                  fontSize: 40,
                  fontWeight: FontWeight.w500,
                  height: 1,
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: season.accentColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  season.episodes,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Text(
                season.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Prociono',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 1.16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeasonData {
  const _SeasonData({
    required this.number,
    required this.title,
    required this.episodes,
    required this.color,
    required this.accentColor,
  });

  final String number;
  final String title;
  final String episodes;
  final LinearGradient color;
  final Color accentColor;
}
