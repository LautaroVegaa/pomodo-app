import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/completion_audio_service.dart';

enum TimerRunState { idle, running, paused, completed }

class TimerController extends ChangeNotifier {
  TimerController({
    int initialMinutes = defaultMinutes,
    CompletionAudioService? audioService,
  }) : _selectedMinutes = _normalizeMinutes(initialMinutes),
       _audioService = audioService {
    _totalSeconds = _selectedMinutes * 60;
    _remainingSeconds = _totalSeconds;
  }

  static const int minMinutes = 5;
  static const int maxMinutes = 180;
  static const int stepMinutes = 5;
  static const int defaultMinutes = 45;

  final Duration _tick = const Duration(seconds: 1);
  Timer? _timer;
  final CompletionAudioService? _audioService;

  int _selectedMinutes;
  late int _totalSeconds;
  late int _remainingSeconds;
  TimerRunState _runState = TimerRunState.idle;

  int get selectedMinutes => _selectedMinutes;
  TimerRunState get runState => _runState;
  bool get isRunning => _runState == TimerRunState.running;
  bool get isPaused => _runState == TimerRunState.paused;
  bool get canAdjustDuration =>
      _runState == TimerRunState.idle || _runState == TimerRunState.completed;

  double get progress {
    if (_totalSeconds == 0) return 0;
    final double completed =
        (_totalSeconds - _remainingSeconds) / _totalSeconds.toDouble();
    return completed.clamp(0, 1);
  }

  String get formattedRemaining => _formatTime(_remainingSeconds);

  void setDurationMinutes(int minutes) {
    if (!canAdjustDuration) return;
    final int normalized = _normalizeMinutes(minutes);
    if (normalized == _selectedMinutes) return;
    _selectedMinutes = normalized;
    _totalSeconds = _selectedMinutes * 60;
    _remainingSeconds = _totalSeconds;
    _runState = TimerRunState.idle;
    notifyListeners();
  }

  void start() {
    if (_runState == TimerRunState.running) return;
    if (_runState == TimerRunState.paused) {
      resume();
      return;
    }
    if (_runState == TimerRunState.completed ||
        _runState == TimerRunState.idle) {
      _remainingSeconds = _totalSeconds;
    }
    _runState = TimerRunState.running;
    notifyListeners();
    _ensureTimer();
  }

  void pause() {
    if (_runState != TimerRunState.running) return;
    _runState = TimerRunState.paused;
    _timer?.cancel();
    notifyListeners();
  }

  void resume() {
    if (_runState != TimerRunState.paused) return;
    _runState = TimerRunState.running;
    notifyListeners();
    _ensureTimer();
  }

  void stop() {
    _timer?.cancel();
    _runState = TimerRunState.idle;
    _remainingSeconds = _totalSeconds;
    notifyListeners();
  }

  void handleLifecycleChange(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      pause();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _ensureTimer() {
    _timer?.cancel();
    if (_runState != TimerRunState.running) return;
    _timer = Timer.periodic(_tick, (_) => _handleTick());
  }

  void _handleTick() {
    if (_runState != TimerRunState.running) {
      _timer?.cancel();
      return;
    }
    if (_remainingSeconds <= 1) {
      _remainingSeconds = 0;
      _runState = TimerRunState.completed;
      _timer?.cancel();
      notifyListeners();
      _audioService?.playCompletionCue();
    } else {
      _remainingSeconds -= 1;
      notifyListeners();
    }
  }

  static int _normalizeMinutes(int minutes) {
    final int clamped = minutes.clamp(minMinutes, maxMinutes);
    final double stepped =
        (clamped / stepMinutes).roundToDouble() * stepMinutes.toDouble();
    return stepped.toInt();
  }

  String _formatTime(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainder = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}';
  }
}
