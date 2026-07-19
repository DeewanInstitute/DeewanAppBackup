import 'dart:async';

import 'package:deewan_institute_app/podcasts/podcast_models.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class PodcastPlaybackController extends ChangeNotifier {
  PodcastPlaybackController._() {
    _subscriptions.addAll([
      _player.positionStream.listen((value) {
        position = value;
        notifyListeners();
      }),
      _player.durationStream.listen((value) {
        if (value != null) duration = value;
        notifyListeners();
      }),
      _player.playerStateStream.listen((state) {
        isPlaying = state.playing;
        isLoading =
            state.processingState == ProcessingState.loading ||
            state.processingState == ProcessingState.buffering;
        notifyListeners();
        if (state.processingState == ProcessingState.completed) {
          next();
        }
      }),
      _player.errorStream.listen((_) {
        error = 'This episode could not be played.';
        isLoading = false;
        notifyListeners();
      }),
    ]);
  }

  static final PodcastPlaybackController instance =
      PodcastPlaybackController._();

  final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  PodcastSeason? season;
  int episodeIndex = 0;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  bool isPlaying = false;
  bool isLoading = false;
  String? error;
  double speed = 1;

  bool get hasTrack => season != null;
  EpisodeData? get episode => hasTrack ? season!.episodes[episodeIndex] : null;
  double get progress => duration.inMilliseconds == 0
      ? 0
      : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  String get speedLabel => '${speed % 1 == 0 ? speed.toInt() : speed}x';

  bool isCurrent(PodcastSeason candidate, int index) =>
      season?.seasonNumber == candidate.seasonNumber && episodeIndex == index;

  Future<void> playEpisode(
    PodcastSeason targetSeason,
    int targetIndex, {
    bool autoPlay = true,
  }) async {
    final safeIndex = targetIndex.clamp(0, targetSeason.episodes.length - 1);
    if (isCurrent(targetSeason, safeIndex) && error == null) {
      if (autoPlay && !_player.playing) await _player.play();
      return;
    }

    season = targetSeason;
    episodeIndex = safeIndex;
    position = Duration.zero;
    duration = Duration.zero;
    error = null;
    isLoading = true;
    notifyListeners();

    try {
      await _player.setUrl(episode!.audioUrl);
      await _player.setSpeed(speed);
      if (autoPlay) await _player.play();
    } catch (_) {
      error = 'This episode could not be played.';
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggle() async {
    if (!hasTrack) return;
    if (error != null) {
      await playEpisode(season!, episodeIndex, autoPlay: true);
    } else if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seek(Duration target) async {
    final value = target < Duration.zero
        ? Duration.zero
        : target > duration
        ? duration
        : target;
    await _player.seek(value);
  }

  Future<void> seekBy(int seconds) =>
      seek(position + Duration(seconds: seconds));

  Future<void> seekProgress(double value) => _player.seek(
    Duration(milliseconds: (duration.inMilliseconds * value).round()),
  );

  Future<void> cycleSpeed() async {
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    speed = speeds[(speeds.indexOf(speed) + 1) % speeds.length];
    notifyListeners();
    await _player.setSpeed(speed);
  }

  Future<void> previous() async {
    if (!hasTrack) return;
    if (position > const Duration(seconds: 3) || episodeIndex == 0) {
      await _player.seek(Duration.zero);
      return;
    }
    await playEpisode(season!, episodeIndex - 1);
  }

  Future<void> next() async {
    if (!hasTrack) return;
    if (episodeIndex >= season!.episodes.length - 1) {
      await _player.pause();
      await _player.seek(Duration.zero);
      return;
    }
    await playEpisode(season!, episodeIndex + 1);
  }

  Future<void> stop() async {
    await _player.stop();
    season = null;
    episodeIndex = 0;
    position = Duration.zero;
    duration = Duration.zero;
    isPlaying = false;
    isLoading = false;
    error = null;
    speed = 1;
    notifyListeners();
  }
}
