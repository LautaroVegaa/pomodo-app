import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/completion_audio_service.dart';
import '../../services/completion_banner_controller.dart';
import '../../services/notification_service.dart';

enum TimerRunState { idle, running, paused, completed }

class TimerController extends ChangeNotifier {
  TimerController({
    int initialMinutes = defaultMinutes,
    CompletionAudioService? audioService,
    NotificationService? notificationService,
    CompletionBannerController? bannerController,
    bool Function()? notificationsEnabledResolver,
    DateTime Function()? nowProvider,
  })  : _selectedMinutes = _normalizeMinutes(initialMinutes),
        _audioService = audioService,
        _notificationService = notificationService,
        _bannerController = bannerController,
        _notificationsEnabledResolver = notificationsEnabledResolver,
        _nowProvider = nowProvider ?? DateTime.now {
    _totalSeconds = _selectedMinutes * 60;
    _cachedRemainingSeconds = _totalSeconds;
  }

  static const int minMinutes = 5;
  static const int maxMinutes = 180;
  static const int stepMinutes = 5;
  static const int defaultMinutes = 45;

  final Duration _tick = const Duration(seconds: 1);
  Timer? _timer;
  final CompletionAudioService? _audioService;
  final NotificationService? _notificationService;
  final CompletionBannerController? _bannerController;
  final bool Function()? _notificationsEnabledResolver;
  final DateTime Function() _nowProvider;
  DateTime? _endTime;
  bool _isAppInForeground = true;

  int _selectedMinutes;
  late int _totalSeconds;
  late int _cachedRemainingSeconds;
  TimerRunState _runState = TimerRunState.idle;

  int get selectedMinutes => _selectedMinutes;
  TimerRunState get runState => _runState;
  bool get isRunning => _runState == TimerRunState.running;
  bool get isPaused => _runState == TimerRunState.paused;
  bool get canAdjustDuration =>
      _runState == TimerRunState.idle || _runState == TimerRunState.completed;
  int get remainingSeconds => _computeRemainingSeconds();

  double get progress {
    if (_totalSeconds == 0) return 0;
    final double completed =
        (_totalSeconds - remainingSeconds) / _totalSeconds.toDouble();
    return completed.clamp(0, 1);
  }

  String get formattedRemaining => _formatTime(remainingSeconds);

  void setDurationMinutes(int minutes) {
    if (!canAdjustDuration) return;
    final int normalized = _normalizeMinutes(minutes);
    if (normalized == _selectedMinutes) return;
    _selectedMinutes = normalized;
    _totalSeconds = _selectedMinutes * 60;
    _cachedRemainingSeconds = _totalSeconds;
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
      _cachedRemainingSeconds = _totalSeconds;
    }
    _runState = TimerRunState.running;
    _endTime = _now().add(Duration(seconds: _cachedRemainingSeconds));
    _cancelTimerNotification('start');
    _scheduleTimerNotification('start');
    _notify();
    _ensureTimer();
  }

  void pause() {
    if (_runState != TimerRunState.running) return;
    _cachedRemainingSeconds = remainingSeconds;
    _runState = TimerRunState.paused;
    _timer?.cancel();
    _endTime = null;
    _cancelTimerNotification('pause');
    _notify();
  }

  void resume() {
    if (_runState != TimerRunState.paused) return;
    _runState = TimerRunState.running;
    _endTime = _now().add(Duration(seconds: _cachedRemainingSeconds));
    _cancelTimerNotification('resume');
    _scheduleTimerNotification('resume');
    _notify();
    _ensureTimer();
  }

  void stop() {
    _timer?.cancel();
    _runState = TimerRunState.idle;
    _cachedRemainingSeconds = _totalSeconds;
    _endTime = null;
    _cancelTimerNotification('stop');
    _notify();
  }

  void handleLifecycleChange(AppLifecycleState state) {
    _isAppInForeground = state == AppLifecycleState.resumed;
    if (state == AppLifecycleState.resumed) {
      _cancelTimerNotification('lifecycle_resumed');
      _reconcileElapsedTime();
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_runState == TimerRunState.running && _endTime != null) {
        _timer?.cancel();
        _scheduleTimerNotification('lifecycle_${state.name}');
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cancelTimerNotification('dispose');
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
    final int seconds = remainingSeconds;
    if (seconds <= 0) {
      _completeTimer();
    } else {
      _notify();
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

  void _scheduleTimerNotification(String reason) {
    final NotificationService? service = _notificationService;
    if (service == null || _endTime == null) {
      _log('Skipping schedule ($reason); notification service or end time missing.');
      return;
    }
    _log('Scheduling timer notification ($reason) for $_endTime');
    unawaited(
      service.scheduleTimerCompletionNotification(
        scheduledTime: _endTime!,
      ),
    );
  }

  void _cancelTimerNotification(String reason) {
    final NotificationService? service = _notificationService;
    if (service == null) {
      return;
    }
    _log('Cancelling timer notification ($reason).');
    unawaited(service.cancelScheduledTimerNotification());
  }

  void _log(String message) {
    debugPrint('[TimerController] $message');
  }

  void _showCompletionBanner() {
    final bool notificationsEnabled = _notificationsEnabledResolver?.call() ?? true;
    if (!_isAppInForeground || !notificationsEnabled) {
      return;
    }
    _bannerController?.show(CompletionBannerType.timer);
  }

  void _completeTimer() {
    _runState = TimerRunState.completed;
    _timer?.cancel();
    _endTime = null;
    _cachedRemainingSeconds = 0;
    _cancelTimerNotification('complete');
    _notify();
    if (_isAppInForeground) {
      _audioService?.playCompletionCue();
    }
    _showCompletionBanner();
  }

  int _computeRemainingSeconds() {
    if (_runState == TimerRunState.running && _endTime != null) {
      final int delta = _endTime!.difference(_now()).inSeconds;
      return delta > 0 ? delta : 0;
    }
    return _cachedRemainingSeconds;
  }

  void _reconcileElapsedTime() {
    if (_runState != TimerRunState.running) {
      _notify();
      return;
    }
    if (_endTime == null) {
      return;
    }
    if (remainingSeconds <= 0) {
      _completeTimer();
    } else {
      _notify();
      _ensureTimer();
    }
  }

  void _notify() {
    notifyListeners();
  }

  DateTime _now() => _nowProvider();
}
