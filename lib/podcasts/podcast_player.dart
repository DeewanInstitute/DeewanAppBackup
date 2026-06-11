import 'package:deewan_institute_app/podcasts/podcast_models.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PodcastPlayer extends StatefulWidget {
  final PodcastData podcast;
  final EpisodeData episode;
  const PodcastPlayer({super.key, required this.podcast, required this.episode});

  @override
  State<PodcastPlayer> createState() => _PodcastPlayerState();
}

class _PodcastPlayerState extends State<PodcastPlayer>
    with TickerProviderStateMixin {
  bool _isPlaying = true;
  bool _isFavorited = false;
  double _progress = 0.35;
  double _volume = 0.7;
  String _speed = '1x';
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (!_isPlaying) _rotationController.stop();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      _rotationController.repeat();
      _pulseController.repeat(reverse: true);
    } else {
      _rotationController.stop();
      _pulseController.stop();
    }
  }

  String _formatTime(double progress, int totalSeconds) {
    final seconds = (progress * totalSeconds).round();
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    const totalSeconds = 33 * 60 + 37;
    final artColor = widget.podcast.artColor;
    final bgColor = widget.podcast.bgColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(CupertinoIcons.arrow_left, color: Colors.white, size: 18),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        'Now Playing',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          fontFamily: 'PlusJakartaSans',
                        ),
                      ),
                      Text(
                        widget.podcast.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'PlusJakartaSans',
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.more_horiz, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Animated cover art
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (_, child) => Transform.scale(
                scale: _isPlaying ? _pulseAnimation.value : 1.0,
                child: child,
              ),
              child: RotationTransition(
                turns: _rotationController,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: bgColor,
                    boxShadow: [
                      BoxShadow(
                        color: artColor.withOpacity(0.4),
                        blurRadius: 50,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: _PlayerArtPainter(color: artColor),
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Episode info + favorite
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.episode.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'PlusJakartaSans',
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.podcast.title,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.55),
                            fontSize: 14,
                            fontFamily: 'PlusJakartaSans',
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _isFavorited = !_isFavorited),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        _isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        key: ValueKey(_isFavorited),
                        color: _isFavorited ? artColor : Colors.white.withOpacity(0.6),
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                      activeTrackColor: artColor,
                      inactiveTrackColor: Colors.white.withOpacity(0.2),
                      thumbColor: Colors.white,
                      overlayColor: artColor.withOpacity(0.2),
                    ),
                    child: Slider(
                      value: _progress,
                      onChanged: (v) => setState(() => _progress = v),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatTime(_progress, totalSeconds),
                          style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12, fontFamily: 'PlusJakartaSans'),
                        ),
                        Text(
                          '33:37',
                          style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12, fontFamily: 'PlusJakartaSans'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Playback controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Skip back
                  GestureDetector(
                    onTap: () => setState(() => _progress = (_progress - 0.05).clamp(0.0, 1.0)),
                    child: Column(
                      children: [
                        Icon(Icons.replay_10_rounded, color: Colors.white.withOpacity(0.8), size: 32),
                      ],
                    ),
                  ),
                  // Previous
                  GestureDetector(
                    onTap: () {},
                    child: Icon(Icons.skip_previous_rounded, color: Colors.white.withOpacity(0.8), size: 36),
                  ),
                  // Play / Pause
                  GestureDetector(
                    onTap: _togglePlay,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.25),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: bgColor,
                        size: 36,
                      ),
                    ),
                  ),
                  // Next
                  GestureDetector(
                    onTap: () {},
                    child: Icon(Icons.skip_next_rounded, color: Colors.white.withOpacity(0.8), size: 36),
                  ),
                  // Skip forward
                  GestureDetector(
                    onTap: () => setState(() => _progress = (_progress + 0.05).clamp(0.0, 1.0)),
                    child: Icon(Icons.forward_10_rounded, color: Colors.white.withOpacity(0.8), size: 32),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Bottom row: speed, volume, share
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Speed
                  GestureDetector(
                    onTap: () {
                      final speeds = ['0.5x', '0.75x', '1x', '1.25x', '1.5x', '2x'];
                      final idx = speeds.indexOf(_speed);
                      setState(() => _speed = speeds[(idx + 1) % speeds.length]);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _speed,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'PlusJakartaSans'),
                      ),
                    ),
                  ),
                  // Volume
                  Row(
                    children: [
                      Icon(Icons.volume_down_rounded, color: Colors.white.withOpacity(0.5), size: 18),
                      SizedBox(
                        width: 100,
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                            activeTrackColor: Colors.white.withOpacity(0.8),
                            inactiveTrackColor: Colors.white.withOpacity(0.2),
                            thumbColor: Colors.white,
                            overlayColor: Colors.white.withOpacity(0.15),
                          ),
                          child: Slider(
                            value: _volume,
                            onChanged: (v) => setState(() => _volume = v),
                          ),
                        ),
                      ),
                      Icon(Icons.volume_up_rounded, color: Colors.white.withOpacity(0.5), size: 18),
                    ],
                  ),
                  // Share
                  GestureDetector(
                    onTap: () {},
                    child: Icon(Icons.share_outlined, color: Colors.white.withOpacity(0.7), size: 24),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _PlayerArtPainter extends CustomPainter {
  final Color color;
  _PlayerArtPainter({required this.color});

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
  bool shouldRepaint(_PlayerArtPainter old) => old.color != color;
}
