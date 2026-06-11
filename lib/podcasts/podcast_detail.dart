import 'package:deewan_institute_app/core/app_colors.dart';
import 'package:deewan_institute_app/podcasts/podcast_models.dart';
import 'package:deewan_institute_app/podcasts/podcast_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PodcastDetail extends StatefulWidget {
  final PodcastData podcast;
  const PodcastDetail({super.key, required this.podcast});

  @override
  State<PodcastDetail> createState() => _PodcastDetailState();
}

class _PodcastDetailState extends State<PodcastDetail> {
  bool _showFullDescription = false;
  int _navIndex = 0;

  final List<_DetailEpisode> _episodes = const [
    _DetailEpisode(number: '#88', title: 'How design systems save months of work', date: '27 Nov', duration: '33:37'),
    _DetailEpisode(number: '#87', title: 'The art of saying no to clients', date: '20 Nov', duration: '28:14'),
    _DetailEpisode(number: '#86', title: 'Building products people actually use', date: '13 Nov', duration: '41:02'),
    _DetailEpisode(number: '#85', title: 'Remote work changed everything', date: '6 Nov', duration: '35:50'),
  ];

  static const String _fullDescription =
      'A podcast about design, interfaces, and the people who create the digital world around us. '
      'Every episode is a conversation about how things work, what breaks them, and what makes them great. '
      'We talk to designers, engineers, and thinkers who shape the products you use every day.';

  @override
  Widget build(BuildContext context) {
    final artColor = widget.podcast.artColor;
    final bgColor = widget.podcast.bgColor;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cover
                  Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: size.height * 0.38,
                        color: bgColor,
                        child: Center(
                          child: CustomPaint(
                            size: Size(size.width * 0.65, size.width * 0.65),
                            painter: _CoverArtPainter(color: artColor),
                          ),
                        ),
                      ),
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 12,
                        left: 16,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
                            child: const Icon(CupertinoIcons.arrow_left, size: 18, color: Colors.black),
                          ),
                        ),
                      ),
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 12,
                        right: 16,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
                          child: const Icon(Icons.more_horiz, size: 20, color: Colors.black),
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.podcast.title,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, fontFamily: 'PlusJakartaSans', height: 1.2),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _showFullDescription ? _fullDescription : '${_fullDescription.substring(0, 100)}...',
                          style: TextStyle(fontSize: 13, color: Colors.black.withOpacity(0.5), fontFamily: 'PlusJakartaSans', height: 1.5),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => setState(() => _showFullDescription = !_showFullDescription),
                          child: Text(
                            _showFullDescription ? 'Show less' : 'Show more',
                            style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'PlusJakartaSans'),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Play row
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(50)),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                                    SizedBox(width: 6),
                                    Text('27 min', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'PlusJakartaSans')),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            _ActionButton(icon: Icons.share_outlined),
                            const SizedBox(width: 10),
                            _ActionButton(icon: Icons.favorite_border_rounded),
                          ],
                        ),
                        const SizedBox(height: 28),
                        // Latest Episodes header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Latest Episodes', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, fontFamily: 'PlusJakartaSans')),
                            Row(
                              children: [
                                Text('See all', style: TextStyle(fontSize: 13, color: Colors.black.withOpacity(0.4), fontFamily: 'PlusJakartaSans')),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_forward, size: 14, color: Colors.black.withOpacity(0.4)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _episodes.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                    itemBuilder: (_, i) => _EpisodeTile(episode: _episodes[i], artColor: artColor),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini player
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PodcastPlayer(
                  podcast: widget.podcast,
                  episode: EpisodeData(
                    title: '#88. How design systems save months of work',
                    podcast: widget.podcast.title,
                    duration: '33:37',
                    artColor: widget.podcast.artColor,
                  ),
                ),
              ),
            ),
            child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: artColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.mic, color: artColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('#88. How design systems sav...', maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'PlusJakartaSans')),
                      Text(widget.podcast.title,
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, fontFamily: 'PlusJakartaSans')),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(50)),
                  child: const Icon(Icons.pause, color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
          ),
          _BottomNav(currentIndex: _navIndex, onTap: (i) => setState(() => _navIndex = i)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  const _ActionButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(color: const Color(0xFFF2F2F2), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, size: 20, color: Colors.black87),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  final _DetailEpisode episode;
  final Color artColor;
  const _EpisodeTile({required this.episode, required this.artColor});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: artColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
        child: Icon(Icons.mic, color: artColor, size: 22),
      ),
      title: Text('${episode.number}. ${episode.title}', maxLines: 2, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'PlusJakartaSans', height: 1.3)),
      subtitle: Text('${episode.date} · ${episode.duration}',
          style: TextStyle(fontSize: 11, color: Colors.black.withOpacity(0.4), fontFamily: 'PlusJakartaSans')),
      trailing: Icon(Icons.more_horiz, color: Colors.black.withOpacity(0.3), size: 20),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      [Icons.star_rounded, Icons.star_outline_rounded, 'Home'],
      [Icons.search_rounded, Icons.search_rounded, 'Search'],
      [Icons.favorite_rounded, Icons.favorite_border_rounded, 'Saved'],
      [Icons.person_rounded, Icons.person_outline_rounded, 'Profile'],
    ];

    return Container(
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFEEEEEE)))),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final isActive = i == currentIndex;
          return GestureDetector(
            onTap: () => onTap(i),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isActive ? items[i][0] as IconData : items[i][1] as IconData,
                    color: isActive ? AppColors.primary : Colors.black38, size: 26),
                const SizedBox(height: 2),
                Text(items[i][2] as String,
                    style: TextStyle(fontSize: 11, fontFamily: 'PlusJakartaSans',
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive ? AppColors.primary : Colors.black38)),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _CoverArtPainter extends CustomPainter {
  final Color color;
  _CoverArtPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.28;
    canvas.drawCircle(Offset(cx + r, cy - r), r, paint);
    canvas.drawCircle(Offset(cx - r, cy - r), r, paint);
    canvas.drawCircle(Offset(cx + r, cy + r), r, paint);
    canvas.drawCircle(Offset(cx - r, cy + r), r, paint);
  }

  @override
  bool shouldRepaint(_CoverArtPainter old) => old.color != color;
}

class _DetailEpisode {
  final String number;
  final String title;
  final String date;
  final String duration;
  const _DetailEpisode({required this.number, required this.title, required this.date, required this.duration});
}
