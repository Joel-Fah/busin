import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:busin_core/busin_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'scan_decision.dart';

/// What the staff member hears after a scan. Each kind has its own sound (assets/sounds, made by tool/make_sounds.py),
/// so the result is clear without looking at the screen.
enum ScanSound {
  /// Let on.
  admit,

  /// Already on board: nothing to do.
  again,

  /// A genuine code, but no right to ride (no subscription, not on today's list, account not active).
  refused,

  /// A code that is not genuine or is old: fake, tampered with, signed with another key, or a screenshot.
  suspect,

  /// The phone could not check (no list for today and no connection, or the server did not answer).
  error;

  String get asset => 'sounds/$name.wav';
}

/// The sound for a decision the phone made on its own. Null when the server is asked: its answer gets the sound.
ScanSound? soundForDecision(ScanDecision decision) => switch (decision) {
      Admit() => ScanSound.admit,
      AlreadyOnBoard() => ScanSound.again,
      Refuse(:final kind) => switch (kind) {
          RefusalKind.invalid || RefusalKind.expired => ScanSound.suspect,
          RefusalKind.notOnList => ScanSound.refused,
          RefusalKind.noKeys => ScanSound.error,
        },
      AskServer() => null,
    };

/// The sound for the server's answer.
ScanSound soundForOutcome(ScanOutcome outcome) => switch (outcome) {
      ScanAccepted(:final duplicate) => duplicate ? ScanSound.again : ScanSound.admit,
      ScanRefused(:final reason) => switch (reason) {
          ScanFailure.invalidCode || ScanFailure.expiredCode => ScanSound.suspect,
          ScanFailure.studentNotFound || ScanFailure.accountNotVerified || ScanFailure.noActiveSubscription => ScanSound.refused,
        },
    };

/// Plays the scan sounds. A provider, so tests use a stand-in that records what was played.
abstract class ScanSoundPlayer {
  /// Loads the sounds so the first scan plays without delay.
  Future<void> preload();
  Future<void> play(ScanSound sound);
  Future<void> dispose();
}

/// Short, low-latency sounds (Android SoundPool). They never take audio focus, so music or a call is not paused, and
/// they use the notification-sound stream, which follows the phone's own volume for such sounds.
class AudioScanSoundPlayer implements ScanSoundPlayer {
  final Map<ScanSound, AudioPlayer> _players = {};

  static final _context = AudioContext(
    android: const AudioContextAndroid(
      usageType: AndroidUsageType.assistanceSonification,
      contentType: AndroidContentType.sonification,
      audioFocus: AndroidAudioFocus.none,
      isSpeakerphoneOn: false,
      stayAwake: false,
    ),
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient, options: const {AVAudioSessionOptions.mixWithOthers}),
  );

  Future<AudioPlayer> _player(ScanSound sound) async {
    final existing = _players[sound];
    if (existing != null) return existing;
    final player = AudioPlayer(playerId: 'scan-${sound.name}');
    _players[sound] = player;
    await player.setAudioContext(_context);
    await player.setPlayerMode(PlayerMode.lowLatency);
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setSource(AssetSource(sound.asset));
    return player;
  }

  @override
  Future<void> preload() async {
    for (final sound in ScanSound.values) {
      try {
        await _player(sound);
      } catch (_) {
        // A sound that cannot load stays silent; scanning goes on.
      }
    }
  }

  @override
  Future<void> play(ScanSound sound) async {
    try {
      final player = await _player(sound);
      await player.stop();
      await player.resume();
    } catch (_) {
      // Never let a sound problem get in the way of a scan.
    }
  }

  @override
  Future<void> dispose() async {
    final players = _players.values.toList();
    _players.clear();
    for (final player in players) {
      unawaited(player.dispose());
    }
  }
}

final scanSoundPlayerProvider = Provider<ScanSoundPlayer>((ref) {
  final player = AudioScanSoundPlayer();
  ref.onDispose(player.dispose);
  return player;
});
