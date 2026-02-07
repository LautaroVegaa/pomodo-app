import 'dart:async';

import 'package:flutter/material.dart';

enum StopwatchRunState { idle, running, paused }

class StopwatchController extends ChangeNotifier {
  StopwatchController({DateTime Function()? nowProvider, void Function(Duration elapsed)? onFocusRecorded})
      : _nowProvider = nowProvider ?? DateTime.now,
        _onFocusRecorded = onFocusRecorded;

  final DateTime Function() _nowProvider;
  final void Function(Duration elapsed)? _onFocusRecorded;
  StopwatchRunState _runState = StopwatchRunState.idle;
  Duration _elapsed = Duration.zero;
  DateTime? _lastStartTime;
  Timer? _ticker;

  StopwatchRunState get runState => _runState;
  Duration get elapsed => _elapsed;

  String get formattedElapsed {
    final Duration current = _currentElapsed();
    if (current.inHours >= 1) {
      final String hours = current.inHours.toString().padLeft(2, '0');
      final String minutes = (current.inMinutes % 60).toString().padLeft(2, '0');
      final String seconds = (current.inSeconds % 60).toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }
    final String minutes = current.inMinutes.toString().padLeft(2, '0');
    final String seconds = (current.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  bool get isRunning => _runState == StopwatchRunState.running;
  bool get isPaused => _runState == StopwatchRunState.paused;

  void start() {
    if (_runState == StopwatchRunState.running) return;
    if (_runState == StopwatchRunState.idle) {
      _elapsed = Duration.zero;
    }
    _lastStartTime = _now();
    _runState = StopwatchRunState.running;
    _startTicker();
    notifyListeners();
  }

  void pause() {
    if (_runState != StopwatchRunState.running) return;
    _elapsed = _currentElapsed();
    _lastStartTime = null;
    _runState = StopwatchRunState.paused;
    _ticker?.cancel();
    notifyListeners();
  }

  void resume() {
    if (_runState != StopwatchRunState.paused) return;
    _lastStartTime = _now();
    _runState = StopwatchRunState.running;
    _startTicker();
    notifyListeners();
  }

  void reset() {
    final Duration completed = _currentElapsed();
    final bool shouldRecord =
        _runState != StopwatchRunState.idle && completed.inMinutes > 0;
    _ticker?.cancel();
    _elapsed = Duration.zero;
    _lastStartTime = null;
    _runState = StopwatchRunState.idle;
    notifyListeners();
    final void Function(Duration elapsed)? callback = _onFocusRecorded;
    if (shouldRecord && callback != null) {
      callback(completed);
    }
  }

  void handleLifecycleChange(AppLifecycleState state) {
    if (_runState != StopwatchRunState.running) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _elapsed = _currentElapsed();
      _lastStartTime = _now();
    }
    if (state == AppLifecycleState.resumed) {
      _elapsed = _currentElapsed();
      _lastStartTime = _now();
      _startTicker();
      notifyListeners();
    }
  }

  Duration _currentElapsed() {
    final DateTime? lastStart = _lastStartTime;
    if (lastStart == null) {
      return _elapsed;
    }
    final Duration delta = _now().difference(lastStart);
    return _elapsed + delta;
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_runState != StopwatchRunState.running) {
        _ticker?.cancel();
        return;
      }
      notifyListeners();
    });
  }

  DateTime _now() => _nowProvider();

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
