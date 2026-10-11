import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:just_audio/just_audio.dart';

enum AudioDialect { fusha, levantine }

/// A failure with a message that's safe to show the user as-is.
class AudioException implements Exception {
  final String message;
  const AudioException(this.message);

  @override
  String toString() => message;
}

/// Plays spoken Arabic for a word or sentence. The audio itself is generated
/// by the `generateSpeech` Cloud Function (OpenAI TTS) and cached in Firebase
/// Storage, so the same text is only ever synthesised once — this class just
/// asks for the URL and streams it.
class AudioService {
  AudioService._();

  static final AudioPlayer _player = AudioPlayer();
  static final Map<String, String> _urlCache = {};

  static bool get isSignedIn => FirebaseAuth.instance.currentUser != null;

  /// Resolves once playback has *started* (not finished), so callers can show a
  /// spinner for just the fetch/buffer phase. Throws [AudioException] with a
  /// user-facing message if it can't play.
  static Future<void> play(String text, {AudioDialect dialect = AudioDialect.fusha}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (!isSignedIn) throw const AudioException('Log in to hear pronunciations.');

    try {
      final url = await _urlFor(trimmed, dialect);
      await _player.stop();
      await _player.setUrl(url);
      unawaited(_player.play());
    } on PlayerInterruptedException {
      // Another speaker button took over the shared player — nothing to report.
    } on FirebaseFunctionsException catch (e) {
      throw AudioException(e.message ?? "Couldn't load the audio. Please try again.");
    } catch (_) {
      throw const AudioException("Couldn't play the audio. Please try again.");
    }
  }

  static Future<void> stop() => _player.stop();

  static Future<String> _urlFor(String text, AudioDialect dialect) async {
    final key = '${dialect.name}|$text';
    final cached = _urlCache[key];
    if (cached != null) return cached;

    final callable = FirebaseFunctions.instance.httpsCallable('generateSpeech');
    final result = await callable.call({'text': text, 'dialect': dialect.name});
    final url = (result.data as Map)['url'] as String;
    _urlCache[key] = url;
    return url;
  }
}
