import 'dart:async';

import 'package:flutter/material.dart';

enum StopwatchRunState { idle, running, paused }

class StopwatchController extends ChangeNotifier {
  StopwatchController();

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
    _lastStartTime = DateTime.now();
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
    _lastStartTime = DateTime.now();
    _runState = StopwatchRunState.running;
    _startTicker();
    notifyListeners();
  }

  void reset() {
    _ticker?.cancel();
    _elapsed = Duration.zero;
    _lastStartTime = null;
    _runState = StopwatchRunState.idle;
    notifyListeners();
  }

  void handleLifecycleChange(AppLifecycleState state) {
    if (_runState != StopwatchRunState.running) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _elapsed = _currentElapsed();
      _lastStartTime = DateTime.now();
    }
    if (state == AppLifecycleState.resumed) {
      _elapsed = _currentElapsed();
      _lastStartTime = DateTime.now();
      _startTicker();
      notifyListeners();
    }
  }

  Duration _currentElapsed() {
    if (_lastStartTime == null) {
      return _elapsed;
    }
    final Duration delta = DateTime.now().difference(_lastStartTime!);
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

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
