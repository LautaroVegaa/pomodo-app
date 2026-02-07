import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class CompletionAudioService {
  CompletionAudioService({
    required bool Function() soundsEnabledResolver,
    AudioPlayer? player,
    bool enableWarmup = true,
  }) : _soundsEnabledResolver = soundsEnabledResolver,
       _player = player ?? AudioPlayer(playerId: 'completion_audio'),
       _enableWarmup = enableWarmup {
    _ensureAudioContext();
    unawaited(_player.setReleaseMode(ReleaseMode.stop));
  }

  static const String _assetPath = 'audio/pomodoro_ring.m4a';
  static bool _audioContextConfigured = false;

  final bool Function() _soundsEnabledResolver;
  final AudioPlayer _player;
  final bool _enableWarmup;
  bool _disposed = false;
  bool _debugWarmupRun = false;

  Future<void> playCompletionCue() async {
    if (_disposed) return;
    final bool enabled = _resolveSoundsEnabled();
    if (!enabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource(_assetPath), mode: PlayerMode.lowLatency);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[CompletionAudioService] Playback failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      // Silently ignore playback failures to avoid crashing the session completion flow.
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      await _player.stop();
    } catch (_) {}
    await _player.dispose();
  }

  bool _resolveSoundsEnabled() {
    try {
      return _soundsEnabledResolver();
    } catch (_) {
      return false;
    }
  }

  void _ensureAudioContext() {
    if (_audioContextConfigured) return;
    _audioContextConfigured = true;
    unawaited(
      AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.alarm,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
            isSpeakerphoneOn: false,
            stayAwake: false,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      ),
    );
  }

  Future<void> debugWarmupPlayback() async {
    if (!_enableWarmup || !kDebugMode || _disposed || _debugWarmupRun) return;
    _debugWarmupRun = true;
    debugPrint('[CompletionAudioService] Debug warmup start');
    try {
      await _player.setVolume(0);
      await _player.stop();
      await _player.play(AssetSource(_assetPath), mode: PlayerMode.lowLatency);
      debugPrint('[CompletionAudioService] Debug warmup completed');
    } catch (error, stackTrace) {
      debugPrint('[CompletionAudioService] Debug warmup failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      await _player.stop();
      await _player.setVolume(1);
    }
  }
}
