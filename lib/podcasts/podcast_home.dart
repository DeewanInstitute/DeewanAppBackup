import 'package:deewan_institute_app/auth/login.dart';
import 'package:deewan_institute_app/core/app_bottom_nav.dart';
import 'package:deewan_institute_app/core/app_colors.dart';
import 'package:deewan_institute_app/core/app_loading.dart';
import 'package:deewan_institute_app/flashcards/flashcards_home.dart';
import 'package:deewan_institute_app/podcasts/podcast_detail.dart';
import 'package:deewan_institute_app/podcasts/podcast_models.dart';
import 'package:deewan_institute_app/podcasts/podcast_player.dart';
import 'package:deewan_institute_app/word_search/word_search_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PodcastHome extends StatefulWidget {
  const PodcastHome({super.key});

  @override
  State<PodcastHome> createState() => _PodcastHomeState();
}

class _PodcastHomeState extends State<PodcastHome> {
  int _navIndex = 3;

  final List<PodcastData> _featured = const [
    PodcastData(
      title: 'Pixel by Pixel',
      description:
          'A podcast about design, interfaces, and the people who create the digital world around us.',
      bgColor: Color(0xFF1E1E1E),
      artColor: Color(0xFFE85D3A),
    ),
    PodcastData(
      title: 'Loud Thoughts',
      description: 'How sound shapes your voice and never stops evolving.',
      bgColor: Color(0xFF1A2E2A),
      artColor: Color(0xFF4ECBA8),
    ),
    PodcastData(
      title: 'Deep Focus',
      description: 'Conversations about mindfulness, creativity, and flow.',
      bgColor: Color(0xFF1C1C2E),
      artColor: Color(0xFF7C6FCD),
    ),
  ];

  final List<EpisodeData> _popular = const [
    EpisodeData(
      title: 'Why silence is the best tool...',
      podcast: 'Loud Thoughts',
      duration: '33:37',
      artColor: Color(0xFF4ECBA8),
    ),
    EpisodeData(
      title: 'How design systems save months...',
      podcast: 'Pixel by Pixel',
      duration: '33:37',
      artColor: Color(0xFFE85D3A),
    ),
    EpisodeData(
      title: 'Freelance or office: where to go...',
      podcast: 'Money Microscope',
      duration: '33:37',
      artColor: Color(0xFF7C6FCD),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background/background.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryLight,
                            border: Border.all(color: AppColors.primary, width: 2),
                          ),
                          child: const Icon(Icons.person, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Merhaba 👋',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black.withOpacity(0.45),
                                fontFamily: 'PlusJakartaSans',
                              ),
                            ),
                            Text(
                              FirebaseAuth.instance.currentUser?.displayName ?? 'there',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'PlusJakartaSans',
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // _IconBtn(
                        //   icon: Icons.notifications_outlined,
                        //   bgColor: AppColors.primary,
                        //   iconColor: Colors.white,
                        // ),
                        GestureDetector(
                          onTap: () => AppLoading.navigate(context, const Login(), clearStack: true),
                          child: _IconBtn(
                            icon: Icons.logout,
                            bgColor: AppColors.primary,
                            iconColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Deewan Arabic \nPodcasts',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'PlusJakartaSans',
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Featured cards
                  SizedBox(
                    height: 230,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _featured.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () => AppLoading.navigate(context, PodcastDetail(podcast: _featured[i])),
                        child: _FeaturedCard(podcast: _featured[i]),
                      ),
                    ),
                  ),

                  // Popular Episodes
                  _SectionHeader(title: 'Popular Episodes', onTap: () {}),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _popular.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 72),
                    itemBuilder: (_, i) => _EpisodeTile(episode: _popular[i]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MiniPlayer(episode: _popular[1]),
          AppBottomNav(
            currentIndex: 3,
            onTap: (i) {
              if (i == 3) return;
              if (i == 0) { Navigator.pop(context); return; }
              if (i == 1) { AppLoading.navigate(context, const WordSearchPage()); return; }
              if (i == 2) { AppLoading.navigate(context, const FlashcardsHome()); return; }
            },
          ),
        ],
      ),
    );
  }
}

// ── Featured Card ─────────────────────────────────────────────────────────────

class _FeaturedCard extends StatelessWidget {
  final PodcastData podcast;
  const _FeaturedCard({required this.podcast});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: podcast.bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: SizedBox(
              height: 110,
              child: CustomPaint(painter: _ArtPainter(color: podcast.artColor)),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  podcast.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'PlusJakartaSans',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  podcast.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 11,
                    fontFamily: 'PlusJakartaSans',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Episode Tile ──────────────────────────────────────────────────────────────

class _EpisodeTile extends StatelessWidget {
  final EpisodeData episode;
  const _EpisodeTile({required this.episode});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: episode.artColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.mic, color: episode.artColor, size: 22),
      ),
      title: Text(
        episode.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: 'PlusJakartaSans',
        ),
      ),
      subtitle: Text(
        episode.podcast,
        style: TextStyle(
          fontSize: 12,
          color: Colors.black.withOpacity(0.45),
          fontFamily: 'PlusJakartaSans',
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            episode.duration,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withOpacity(0.4),
              fontFamily: 'PlusJakartaSans',
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.more_horiz,
            color: Colors.black.withOpacity(0.3),
            size: 20,
          ),
        ],
      ),
    );
  }
}

// ── Category Chip ─────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final _Category category;
  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: category.color,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        category.name,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          fontFamily: 'PlusJakartaSans',
        ),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  const _SectionHeader({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 12, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              fontFamily: 'PlusJakartaSans',
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Row(
              children: [
                Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withOpacity(0.4),
                    fontFamily: 'PlusJakartaSans',
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward,
                  size: 14,
                  color: Colors.black.withOpacity(0.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mini Player ───────────────────────────────────────────────────────────────

class _MiniPlayer extends StatelessWidget {
  final EpisodeData episode;
  const _MiniPlayer({required this.episode});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => AppLoading.navigate(
        context,
        PodcastPlayer(
          podcast: PodcastData(
            title: episode.podcast,
            description: '',
            bgColor: const Color(0xFF1E1E1E),
            artColor: episode.artColor,
          ),
          episode: episode,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: episode.artColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.mic, color: episode.artColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    episode.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'PlusJakartaSans',
                    ),
                  ),
                  Text(
                    episode.podcast,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                      fontFamily: 'PlusJakartaSans',
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(Icons.pause, color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Art Painter ───────────────────────────────────────────────────────────────

class _ArtPainter extends CustomPainter {
  final Color color;
  _ArtPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.28;
    canvas.drawCircle(Offset(cx + r, cy - r), r, paint);
    canvas.drawCircle(Offset(cx - r, cy - r), r, paint);
    canvas.drawCircle(Offset(cx + r, cy + r), r, paint);
    canvas.drawCircle(Offset(cx - r, cy + r), r, paint);
  }

  @override
  bool shouldRepaint(_ArtPainter old) => old.color != color;
}

// ── Icon Button ───────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color? bgColor;
  final Color? iconColor;
  const _IconBtn({required this.icon, this.bgColor, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bgColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Icon(icon, size: 20, color: iconColor ?? Colors.black87),
    );
  }
}

// ── Data Models ───────────────────────────────────────────────────────────────

class _Category {
  final String name;
  final Color color;
  const _Category({required this.name, required this.color});
}

