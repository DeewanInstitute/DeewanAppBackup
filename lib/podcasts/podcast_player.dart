import 'package:deewan_institute_app/core/app_colors.dart';
import 'package:deewan_institute_app/podcasts/podcast_models.dart';
import 'package:deewan_institute_app/podcasts/podcast_playback_controller.dart';
import 'package:flutter/material.dart';

class PodcastPlayer extends StatefulWidget {
  final PodcastSeason season;
  final int initialEpisodeIndex;

  const PodcastPlayer({
    super.key,
    required this.season,
    required this.initialEpisodeIndex,
  });

  @override
  State<PodcastPlayer> createState() => _PodcastPlayerState();
}

class _PodcastPlayerState extends State<PodcastPlayer> {
  final PodcastPlaybackController _playback =
      PodcastPlaybackController.instance;

  EpisodeData get _episode => _playback.episode!;

  String get _episodeTitle =>
      _episode.title.replaceFirst(RegExp(r'^Episode\s+\d+\s*:\s*'), '');

  @override
  void initState() {
    super.initState();
    if (!_playback.isCurrent(widget.season, widget.initialEpisodeIndex)) {
      _playback.playEpisode(widget.season, widget.initialEpisodeIndex);
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _playback,
      builder: (context, _) => Scaffold(
        backgroundColor: AppColors.podcastPlayerBackground,
        body: SafeArea(
          child: Column(
            children: [
              _PlayerHeader(onClose: () => Navigator.pop(context)),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxHeight < 760;
                    final coverSize = compact ? 240.0 : 280.0;

                    return SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        24,
                        compact ? 40 : 111,
                        24,
                        32,
                      ),
                      child: Column(
                        children: [
                          _CoverArt(
                            size: coverSize,
                            imageAssetPath: _playback.season!.imageAssetPath,
                          ),
                          const SizedBox(height: 32),
                          Text(
                            _episodeTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontFamily: 'Prociono',
                              fontSize: 28,
                              fontWeight: FontWeight.w400,
                              height: 37 / 28,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_playback.season!.title} · ${_playback.season!.hostedBy}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.green,
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 19 / 16,
                            ),
                          ),
                          const SizedBox(height: 32),
                          if (_playback.error != null) ...[
                            Text(
                              _playback.error!,
                              style: const TextStyle(
                                color: AppColors.podcastPlaybackError,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          _Scrubber(
                            progress: _playback.progress,
                            elapsed: _formatTime(_playback.position.inSeconds),
                            duration: _playback.duration == Duration.zero
                                ? '--:--'
                                : _formatTime(_playback.duration.inSeconds),
                            onChanged: _playback.duration == Duration.zero
                                ? null
                                : _playback.seekProgress,
                          ),
                          const SizedBox(height: 32),
                          _PlaybackRow(
                            speed: _playback.speedLabel,
                            isPlaying: _playback.isPlaying,
                            isLoading: _playback.isLoading,
                            onSpeedTap: _playback.cycleSpeed,
                            onReplay: () => _playback.seekBy(-10),
                            onPrevious: _playback.previous,
                            onPlayPause: _playback.toggle,
                            onNext: _playback.next,
                            onForward: () => _playback.seekBy(10),
                            onShare: () {},
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerHeader extends StatelessWidget {
  const _PlayerHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 24, height: 24),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.white,
                size: 32,
              ),
            ),
            const Text(
              'Now Playing',
              style: TextStyle(
                color: AppColors.white,
                fontFamily: 'Prociono',
                fontSize: 20,
                fontWeight: FontWeight.w400,
                height: 26 / 20,
              ),
            ),
            IconButton(
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 24, height: 24),
              icon: const Icon(
                Icons.more_horiz_rounded,
                color: AppColors.white,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverArt extends StatelessWidget {
  const _CoverArt({required this.size, required this.imageAssetPath});

  final double size;
  final String? imageAssetPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.cream),
        boxShadow: const [
          BoxShadow(
            color: AppColors.podcastAccentGlow,
            blurRadius: 30,
            spreadRadius: -12,
            offset: Offset(0, 20),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: imageAssetPath == null || imageAssetPath!.isEmpty
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

class _Scrubber extends StatelessWidget {
  const _Scrubber({
    required this.progress,
    required this.elapsed,
    required this.duration,
    required this.onChanged,
  });

  final double progress;
  final String elapsed;
  final String duration;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            activeTrackColor: AppColors.green,
            inactiveTrackColor: AppColors.cream,
            thumbColor: AppColors.white,
            overlayColor: AppColors.podcastAccentOverlay,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            trackShape: const RoundedRectSliderTrackShape(),
          ),
          child: Slider(value: progress, min: 0, max: 1, onChanged: onChanged),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [_TimeLabel(elapsed), _TimeLabel(duration)],
        ),
      ],
    );
  }
}

class _TimeLabel extends StatelessWidget {
  const _TimeLabel(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: TextStyle(
        color: AppColors.cream,
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 15 / 12,
      ),
    );
  }
}

class _PlaybackRow extends StatelessWidget {
  const _PlaybackRow({
    required this.speed,
    required this.isPlaying,
    required this.isLoading,
    required this.onSpeedTap,
    required this.onReplay,
    required this.onPrevious,
    required this.onPlayPause,
    required this.onNext,
    required this.onForward,
    required this.onShare,
  });

  final String speed;
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onSpeedTap;
  final VoidCallback onReplay;
  final VoidCallback onPrevious;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onForward;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ControlTapTarget(
            onTap: onSpeedTap,
            child: Text(
              speed,
              style: TextStyle(
                color: AppColors.cream,
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _ControlTapTarget(
            onTap: onReplay,
            child: const Icon(
              Icons.replay_10_rounded,
              color: AppColors.white,
              size: 28,
            ),
          ),
          _ControlTapTarget(
            onTap: onPrevious,
            child: const Icon(
              Icons.skip_previous_rounded,
              color: AppColors.white,
              size: 34,
            ),
          ),
          _PlayPauseButton(
            isPlaying: isPlaying,
            isLoading: isLoading,
            onTap: onPlayPause,
          ),
          _ControlTapTarget(
            onTap: onNext,
            child: const Icon(
              Icons.skip_next_rounded,
              color: AppColors.white,
              size: 34,
            ),
          ),
          _ControlTapTarget(
            onTap: onForward,
            child: const Icon(
              Icons.forward_10_rounded,
              color: AppColors.white,
              size: 28,
            ),
          ),
          _ControlTapTarget(
            onTap: onShare,
            child: const Icon(
              Icons.ios_share_rounded,
              color: AppColors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlTapTarget extends StatelessWidget {
  const _ControlTapTarget({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 24,
      child: SizedBox(width: 32, height: 48, child: Center(child: child)),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({
    required this.isPlaying,
    required this.isLoading,
    required this.onTap,
  });

  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: const BoxDecoration(
          color: AppColors.green,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.podcastAccentStrongGlow,
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
        ),
        child: isLoading
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Icon(
                isPlaying
                    ? Icons.pause_circle_outline_rounded
                    : Icons.play_circle_outline_rounded,
                color: AppColors.white,
                size: 34,
              ),
      ),
    );
  }
}
