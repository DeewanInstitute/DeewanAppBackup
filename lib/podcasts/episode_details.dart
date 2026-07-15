import 'package:deewan_institute_app/core/app_bottom_nav.dart';
import 'package:deewan_institute_app/core/app_colors.dart';
import 'package:deewan_institute_app/core/app_drawer.dart';
import 'package:deewan_institute_app/core/app_loading.dart';
import 'package:deewan_institute_app/core/app_top_nav.dart';
import 'package:deewan_institute_app/flashcards/review_incorrect_page.dart';
import 'package:deewan_institute_app/podcasts/podcast_models.dart';
import 'package:deewan_institute_app/podcasts/podcast_player.dart';
import 'package:deewan_institute_app/word_search/word_search_page.dart';
import 'package:flutter/material.dart';

class EpisodeDetails extends StatelessWidget {
  const EpisodeDetails({
    super.key,
    required this.podcast,
    required this.episode,
    this.seasonGradient = AppColors.podcastGreenGradient,
    this.level = 'Intermediate',
    this.description,
    this.imageAssetPath,
    this.transcript,
  });

  final PodcastData podcast;
  final EpisodeData episode;
  final LinearGradient seasonGradient;
  final String level;
  final String? description;
  final String? imageAssetPath;
  final String? transcript;

  String get _description =>
      description ??
      'In this episode, we dive into the sensory experience of a traditional Levantine souq. Learn the vocabulary for spices, bargaining, and polite interactions with vendors.';

  @override
  Widget build(BuildContext context) {
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
              _EpisodeImagePlaceholder(
                imageAssetPath: imageAssetPath,
                gradient: seasonGradient,
              ),
              const SizedBox(height: 36),
              _EpisodeMetaRow(
                podcastName: podcast.title,
                level: level,
                duration: episode.duration,
              ),
              const SizedBox(height: 26),
              Text(
                episode.title,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontFamily: 'Lora',
                  fontSize: 43,
                  fontWeight: FontWeight.w500,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _description,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 36),
              _TranscriptLink(
                transcript: transcript,
                onTap: () {},
              ),
              const SizedBox(height: 72),
              _PlayEpisodeButton(
                onTap: () => AppLoading.navigate(
                  context,
                  PodcastPlayer(
                    podcast: podcast,
                    episode: episode,
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

class _EpisodeImagePlaceholder extends StatelessWidget {
  const _EpisodeImagePlaceholder({
    required this.imageAssetPath,
    required this.gradient,
  });

  final String? imageAssetPath;
  final LinearGradient gradient;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 640),
        height: 374,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: gradient.colors.last.withValues(alpha: 0.13),
              blurRadius: 28,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: imageAssetPath == null
            ? const SizedBox.shrink()
            : Image.asset(
                imageAssetPath!,
                fit: BoxFit.cover,
              ),
        // TODO: Add the real episode image later.
        // Example:
        // child: Image.asset('assets/images/podcasts/episode_market.png', fit: BoxFit.cover),
      ),
    );
  }
}

class _EpisodeMetaRow extends StatelessWidget {
  const _EpisodeMetaRow({
    required this.podcastName,
    required this.level,
    required this.duration,
  });

  final String podcastName;
  final String level;
  final String duration;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            podcastName.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.orange,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 12),
        _MetaPill(
          label: level,
          backgroundColor: const Color(0xFFE7F1DF),
          foregroundColor: AppColors.green,
        ),
        const SizedBox(width: 10),
        _MetaPill(
          label: duration,
          backgroundColor: const Color(0xFFEDE6DA),
          foregroundColor: AppColors.ink,
        ),
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _TranscriptLink extends StatelessWidget {
  const _TranscriptLink({
    required this.transcript,
    required this.onTap,
  });

  final String? transcript;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.description_outlined,
              color: AppColors.green,
              size: 30,
            ),
            SizedBox(width: 14),
            Text(
              'View Full Transcript',
              style: TextStyle(
                color: AppColors.green,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayEpisodeButton extends StatelessWidget {
  const _PlayEpisodeButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 65,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.play_circle_outline_rounded, size: 30),
        label: const Text(
          'Play Episode',
          style: TextStyle(
            fontSize: 24,
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
