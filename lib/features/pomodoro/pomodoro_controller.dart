import 'dart:async';

import 'package:flutter/material.dart';

import 'pomodoro_storage.dart';

enum SessionType { focus, breakSession }

enum RunState { idle, running, paused }

class PomodoroController extends ChangeNotifier {
  PomodoroController({PomodoroStorage? storage})
      : _storage = storage ?? PomodoroStorage();

  final PomodoroStorage _storage;
  Future<void>? _initialization;

  static const int _focusMin = 5;
  static const int _focusMax = 90;
  static const int _breakMin = 1;
  static const int _breakMax = 30;
  static const int _longBreakMin = 5;
  static const int _longBreakMax = 60;
  static const int _longBreakCyclesMin = 2;
  static const int _longBreakCyclesMax = 8;

  int _focusMinutes = PomodoroConfig.defaults.focusMinutes;
  int _breakMinutes = PomodoroConfig.defaults.breakMinutes;
  int _longBreakMinutes = PomodoroConfig.defaults.longBreakMinutes;
  int _longBreakEveryCycles =
      PomodoroConfig.defaults.longBreakEveryCycles;

  final Duration _tick = const Duration(seconds: 1);

  SessionType _sessionType = SessionType.focus;
  RunState _runState = RunState.idle;
  int _remainingSeconds = 25 * 60;
  int _totalSeconds = 25 * 60;
  int _cycleCount = 0;

  Timer? _timer;

  SessionType get sessionType => _sessionType;
  RunState get runState => _runState;
  int get remainingSeconds => _remainingSeconds;
  int get totalSeconds => _totalSeconds;
  int get cycleCount => _cycleCount;
  int get focusMinutes => _focusMinutes;
  int get breakMinutes => _breakMinutes;
  int get longBreakMinutes => _longBreakMinutes;
  int get longBreakEveryCycles => _longBreakEveryCycles;
  String get durationSummary =>
      '$_focusMinutes min focus · $_breakMinutes min break';
  String get formattedRemaining => _formatTime(_remainingSeconds);

  Future<void> initialize() {
    return _initialization ??= _loadPersistedConfig();
  }

  Future<void> _loadPersistedConfig() async {
    try {
      final PomodoroConfig config = await _storage.loadConfig();
      _applyConfig(config);
    } catch (_) {
      // Ignore persistence errors; defaults remain in place.
    }
  }

  double get progress {
    if (_totalSeconds == 0) return 0;
    final double completed = 1 - (_remainingSeconds / _totalSeconds);
    return completed.clamp(0, 1);
  }

  void start() {
    if (_runState != RunState.idle) return;
    _runState = RunState.running;
    _notify();
    _ensureTimer();
  }

  void pause() {
    if (_runState != RunState.running) return;
    _runState = RunState.paused;
    _timer?.cancel();
    _notify();
  }

  void resume() {
    if (_runState != RunState.paused) return;
    _runState = RunState.running;
    _notify();
    _ensureTimer();
  }

  void togglePause() {
    switch (_runState) {
      case RunState.running:
        pause();
        break;
      case RunState.paused:
        resume();
        break;
      case RunState.idle:
        start();
        break;
    }
  }

  void stopConfirmed() {
    resetToIdleFocus();
  }

  void resetToIdleFocus() {
    _timer?.cancel();
    _sessionType = SessionType.focus;
    _runState = RunState.idle;
    final int focusSeconds = _minutesToSeconds(_focusMinutes);
    _totalSeconds = focusSeconds;
    _remainingSeconds = focusSeconds;
    _cycleCount = 0;
    _notify();
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
    if (_runState != RunState.running) return;
    _timer = Timer.periodic(_tick, (_) => _handleTick());
  }

  void _handleTick() {
    if (_runState != RunState.running) {
      _timer?.cancel();
      return;
    }

    if (_remainingSeconds <= 1) {
      _remainingSeconds = 0;
      _notify();
      _handleSessionComplete();
    } else {
      _remainingSeconds -= 1;
      _notify();
    }
  }

  void _handleSessionComplete() {
    _timer?.cancel();
    if (_sessionType == SessionType.focus) {
      _cycleCount += 1;
      _beginSession(SessionType.breakSession);
    } else {
      _beginSession(SessionType.focus);
    }
  }

  void _beginSession(SessionType type) {
    final int targetDuration = _durationFor(type);
    _sessionType = type;
    _totalSeconds = targetDuration;
    _remainingSeconds = targetDuration;
    _runState = RunState.running;
    _notify();
    _ensureTimer();
  }

  void _applyConfig(PomodoroConfig config) {
    _focusMinutes = config.focusMinutes.clamp(_focusMin, _focusMax);
    _breakMinutes = config.breakMinutes.clamp(_breakMin, _breakMax);
    _longBreakMinutes =
        config.longBreakMinutes.clamp(_longBreakMin, _longBreakMax);
    _longBreakEveryCycles = config.longBreakEveryCycles
        .clamp(_longBreakCyclesMin, _longBreakCyclesMax);

    if (_runState == RunState.idle) {
      final int target = _sessionType == SessionType.focus
          ? _minutesToSeconds(_focusMinutes)
          : _durationFor(SessionType.breakSession);
      _totalSeconds = target;
      _remainingSeconds = target;
    }

    _notify();
  }

  int _durationFor(SessionType type) {
    if (type == SessionType.focus) {
      return _minutesToSeconds(_focusMinutes);
    }

    final bool useLongBreak =
        _cycleCount > 0 && _cycleCount % _longBreakEveryCycles == 0;
    final int breakMinutes = useLongBreak ? _longBreakMinutes : _breakMinutes;
    return _minutesToSeconds(breakMinutes);
  }

  int _minutesToSeconds(int minutes) => minutes * 60;

  void _persistConfig() {
    final PomodoroConfig config = PomodoroConfig(
      focusMinutes: _focusMinutes,
      breakMinutes: _breakMinutes,
      longBreakMinutes: _longBreakMinutes,
      longBreakEveryCycles: _longBreakEveryCycles,
    );
    unawaited(_storage.saveConfig(config));
  }

  void setFocusMinutes(int minutes) {
    final int clamped = minutes.clamp(_focusMin, _focusMax);
    if (_focusMinutes == clamped) return;
    _focusMinutes = clamped;
    if (_runState == RunState.idle && _sessionType == SessionType.focus) {
      final int secs = _minutesToSeconds(_focusMinutes);
      _totalSeconds = secs;
      _remainingSeconds = secs;
    }
    _notify();
    _persistConfig();
  }

  void setBreakMinutes(int minutes) {
    final int clamped = minutes.clamp(_breakMin, _breakMax);
    if (_breakMinutes == clamped) return;
    _breakMinutes = clamped;
    if (_runState == RunState.idle && _sessionType == SessionType.breakSession) {
      final int secs = _minutesToSeconds(_breakMinutes);
      _totalSeconds = secs;
      _remainingSeconds = secs;
    }
    _notify();
    _persistConfig();
  }

  void setLongBreakMinutes(int minutes) {
    final int clamped = minutes.clamp(_longBreakMin, _longBreakMax);
    if (_longBreakMinutes == clamped) return;
    _longBreakMinutes = clamped;
    if (_runState == RunState.idle && _sessionType == SessionType.breakSession) {
      final int secs = _minutesToSeconds(_longBreakMinutes);
      _totalSeconds = secs;
      _remainingSeconds = secs;
    }
    _notify();
    _persistConfig();
  }

  void setLongBreakEveryCycles(int cycles) {
    final int clamped = cycles.clamp(_longBreakCyclesMin, _longBreakCyclesMax);
    if (_longBreakEveryCycles == clamped) return;
    _longBreakEveryCycles = clamped;
    _notify();
    _persistConfig();
  }

  String _formatTime(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainder = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}';
  }

  void _notify() {
    notifyListeners();
  }
}
