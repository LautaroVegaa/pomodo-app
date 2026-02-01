import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pomodoro_storage.dart';
import '../stats/stats_controller.dart';
import '../../services/completion_audio_service.dart';
import '../../services/completion_banner_controller.dart';
import '../../services/notification_service.dart';

enum SessionType { focus, breakSession }

enum RunState { idle, running, paused }

enum SessionCue { focusComplete, breakComplete }

class PomodoroController extends ChangeNotifier {
  PomodoroController({
    PomodoroStorage? storage,
    bool Function()? hapticsEnabledResolver,
    bool Function()? soundsEnabledResolver,
    StatsController? statsController,
    CompletionAudioService? audioService,
    NotificationService? notificationService,
     CompletionBannerController? bannerController,
     bool Function()? notificationsEnabledResolver,
  }) : _storage = storage ?? PomodoroStorage(),
       _isHapticsEnabled = hapticsEnabledResolver,
       _isSoundsEnabled = soundsEnabledResolver,
       _statsController = statsController,
       _audioService = audioService,
       _notificationService = notificationService,
       _bannerController = bannerController,
       _notificationsEnabledResolver = notificationsEnabledResolver;

  final PomodoroStorage _storage;
  Future<void>? _initialization;
  final bool Function()? _isHapticsEnabled;
  final bool Function()? _isSoundsEnabled;
  final StatsController? _statsController;
  final CompletionAudioService? _audioService;
  final NotificationService? _notificationService;
  final CompletionBannerController? _bannerController;
  final bool Function()? _notificationsEnabledResolver;

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
  int _longBreakEveryCycles = PomodoroConfig.defaults.longBreakEveryCycles;

  final Duration _tick = const Duration(seconds: 1);

  SessionType _sessionType = SessionType.focus;
  RunState _runState = RunState.idle;
  int _totalSeconds = 25 * 60;
  int _cachedRemainingSeconds = 25 * 60;
  int _cycleCount = 0;
  bool _isCurrentBreakLong = false;
  DateTime? _endTime;
  bool _isAppInForeground = true;

  Timer? _timer;

  SessionType get sessionType => _sessionType;
  RunState get runState => _runState;
  int get remainingSeconds => _computeRemainingSeconds();
  int get totalSeconds => _totalSeconds;
  int get cycleCount => _cycleCount;
  int get focusMinutes => _focusMinutes;
  int get breakMinutes => _breakMinutes;
  int get longBreakMinutes => _longBreakMinutes;
  int get longBreakEveryCycles => _longBreakEveryCycles;
  bool get isLongBreakSession =>
      _sessionType == SessionType.breakSession && _isCurrentBreakLong;
  String get durationSummary =>
      '$_focusMinutes min focus · $_breakMinutes min break';
  String get formattedRemaining => _formatTime(remainingSeconds);

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
    final double completed = 1 - (remainingSeconds / _totalSeconds);
    return completed.clamp(0, 1);
  }

  void start() {
    if (_runState != RunState.idle) return;
    _cachedRemainingSeconds = _totalSeconds;
    _endTime = DateTime.now().add(Duration(seconds: _cachedRemainingSeconds));
    _runState = RunState.running;
    _cancelPomodoroNotification('start');
    _notify();
    _schedulePomodoroNotification('start');
    _ensureTimer();
  }

  void pause() {
    if (_runState != RunState.running) return;
    _cachedRemainingSeconds = remainingSeconds;
    _endTime = null;
    _runState = RunState.paused;
    _timer?.cancel();
    _cancelPomodoroNotification('pause');
    _notify();
  }

  void resume() {
    if (_runState != RunState.paused) return;
    _endTime = DateTime.now().add(Duration(seconds: _cachedRemainingSeconds));
    _runState = RunState.running;
    _cancelPomodoroNotification('resume');
    _notify();
    _schedulePomodoroNotification('resume');
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
    _cancelPomodoroNotification('reset');
    _sessionType = SessionType.focus;
    _runState = RunState.idle;
    final int focusSeconds = _minutesToSeconds(_focusMinutes);
    _totalSeconds = focusSeconds;
    _cachedRemainingSeconds = focusSeconds;
    _cycleCount = 0;
    _isCurrentBreakLong = false;
    _endTime = null;
    _notify();
  }

  void handleLifecycleChange(AppLifecycleState state) {
    _isAppInForeground = state == AppLifecycleState.resumed;
    if (state == AppLifecycleState.resumed) {
      _cancelPomodoroNotification('lifecycle_resumed');
      _reconcileElapsedTime();
      return;
    }

    if (state == AppLifecycleState.paused ||
      state == AppLifecycleState.inactive) {
      if (_runState == RunState.running && _endTime != null) {
        _schedulePomodoroNotification('lifecycle_${state.name}');
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cancelPomodoroNotification('dispose');
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
    final int seconds = remainingSeconds;
    if (seconds <= 0) {
      _notify();
      _handleSessionComplete();
    } else {
      _notify();
    }
  }

  void _reconcileElapsedTime() {
    if (_runState != RunState.running) {
      _notify();
      return;
    }
    if (_endTime == null) {
      return;
    }
    if (remainingSeconds <= 0) {
      _handleSessionComplete();
    } else {
      _notify();
      _ensureTimer();
    }
  }

  void _handleSessionComplete() {
    _timer?.cancel();
    _cancelPomodoroNotification('session_complete');
    _cachedRemainingSeconds = 0;
    _endTime = null;
    final bool completedFocus = _sessionType == SessionType.focus;
    final bool completedLongBreak = !completedFocus && _isCurrentBreakLong;
    _handleSessionCue(
      completedFocus ? SessionCue.focusComplete : SessionCue.breakComplete,
    );
    _showCompletionBanner(
      completedFocus: completedFocus,
      completedLongBreak: completedLongBreak,
    );
    if (completedFocus) {
      final int completedMinutes = (_totalSeconds ~/ 60).clamp(0, 1440).toInt();
      _statsController?.recordFocusCompletion(
        completionTime: DateTime.now(),
        focusMinutes: completedMinutes,
      );
      _cycleCount += 1;
      _beginSession(SessionType.breakSession);
    } else {
      _beginSession(SessionType.focus);
    }
  }

  void _beginSession(SessionType type) {
    final bool nextIsLongBreak =
        type == SessionType.breakSession ? _shouldUseLongBreak() : false;
    _isCurrentBreakLong = nextIsLongBreak;
    final int targetDuration =
        _durationFor(type, isLongBreakOverride: nextIsLongBreak);
    _sessionType = type;
    _totalSeconds = targetDuration;
    _cachedRemainingSeconds = targetDuration;
    _endTime = DateTime.now().add(Duration(seconds: targetDuration));
    _runState = RunState.running;
    _cancelPomodoroNotification('begin_session');
    _notify();
    _schedulePomodoroNotification('begin_session');
    _ensureTimer();
  }

  void _applyConfig(PomodoroConfig config) {
    _focusMinutes = config.focusMinutes.clamp(_focusMin, _focusMax);
    _breakMinutes = config.breakMinutes.clamp(_breakMin, _breakMax);
    _longBreakMinutes = config.longBreakMinutes.clamp(
      _longBreakMin,
      _longBreakMax,
    );
    _longBreakEveryCycles = config.longBreakEveryCycles.clamp(
      _longBreakCyclesMin,
      _longBreakCyclesMax,
    );

    if (_runState == RunState.idle) {
      final int target = _sessionType == SessionType.focus
          ? _minutesToSeconds(_focusMinutes)
          : _durationFor(SessionType.breakSession);
      _totalSeconds = target;
      _cachedRemainingSeconds = target;
    }

    _notify();
  }

  int _durationFor(SessionType type, {bool? isLongBreakOverride}) {
    if (type == SessionType.focus) {
      return _minutesToSeconds(_focusMinutes);
    }

    final bool useLongBreak =
      isLongBreakOverride ?? _isCurrentBreakLong;
    final int breakMinutes = useLongBreak ? _longBreakMinutes : _breakMinutes;
    return _minutesToSeconds(breakMinutes);
  }

  bool _shouldUseLongBreak() {
    return _cycleCount > 0 && _cycleCount % _longBreakEveryCycles == 0;
  }

  int _minutesToSeconds(int minutes) => minutes * 60;

  int _computeRemainingSeconds() {
    if (_runState == RunState.running && _endTime != null) {
      final int delta = _endTime!.difference(DateTime.now()).inSeconds;
      return delta > 0 ? delta : 0;
    }
    return _cachedRemainingSeconds;
  }

  void _handleSessionCue(SessionCue cue) {
    if (_isHapticsEnabled?.call() ?? true) {
      HapticFeedback.mediumImpact();
    }
    if (_isSoundsEnabled?.call() ?? false) {
      playCue(cue);
    }
  }

  void playCue(SessionCue cue) {
    _audioService?.playCompletionCue();
  }

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
      _cachedRemainingSeconds = secs;
    }
    _notify();
    _persistConfig();
  }

  void setBreakMinutes(int minutes) {
    final int clamped = minutes.clamp(_breakMin, _breakMax);
    if (_breakMinutes == clamped) return;
    _breakMinutes = clamped;
    if (_runState == RunState.idle &&
        _sessionType == SessionType.breakSession) {
      final int secs = _minutesToSeconds(_breakMinutes);
      _totalSeconds = secs;
      _cachedRemainingSeconds = secs;
    }
    _notify();
    _persistConfig();
  }

  void setLongBreakMinutes(int minutes) {
    final int clamped = minutes.clamp(_longBreakMin, _longBreakMax);
    if (_longBreakMinutes == clamped) return;
    _longBreakMinutes = clamped;
    if (_runState == RunState.idle &&
        _sessionType == SessionType.breakSession) {
      final int secs = _minutesToSeconds(_longBreakMinutes);
      _totalSeconds = secs;
      _cachedRemainingSeconds = secs;
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

  void _schedulePomodoroNotification(String reason) {
    final NotificationService? service = _notificationService;
    if (service == null || _endTime == null) {
      _log('Skipping schedule ($reason); notification service or end time missing.');
      return;
    }
    _log('Scheduling ${_sessionType.name} notification ($reason) for $_endTime');
    unawaited(
      service.scheduleSessionCompletionNotification(
        scheduledTime: _endTime!,
        isFocusSession: _sessionType == SessionType.focus,
      ),
    );
  }

  void _cancelPomodoroNotification(String reason) {
    final NotificationService? service = _notificationService;
    if (service == null) {
      return;
    }
    _log('Cancelling notification ($reason).');
    unawaited(service.cancelScheduledSessionNotification());
  }

  void _log(String message) {
    debugPrint('[PomodoroController] $message');
  }

  void _showCompletionBanner({
    required bool completedFocus,
    required bool completedLongBreak,
  }) {
    if (!_shouldShowForegroundBanner()) {
      return;
    }
    CompletionBannerType type;
    if (completedFocus) {
      type = CompletionBannerType.focus;
    } else if (completedLongBreak) {
      type = CompletionBannerType.longBreak;
    } else {
      type = CompletionBannerType.breakSession;
    }
    _bannerController?.show(type);
  }

  bool _shouldShowForegroundBanner() {
    final bool notificationsEnabled = _notificationsEnabledResolver?.call() ?? true;
    return _isAppInForeground && notificationsEnabled;
  }
}
