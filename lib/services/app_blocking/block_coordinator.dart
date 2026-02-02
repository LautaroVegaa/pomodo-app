import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../app/app_blocking_scope.dart';
import '../../app/pomodoro_scope.dart';
import '../../app/stopwatch_scope.dart';
import '../../app/timer_scope.dart';
import '../../features/pomodoro/pomodoro_controller.dart';
import '../../features/stopwatch/stopwatch_controller.dart';
import '../../features/timer/timer_controller.dart';
import 'app_blocking_controller.dart';

class AppBlockingBridge extends StatefulWidget {
  const AppBlockingBridge({super.key, required this.child});

  final Widget child;

  @override
  State<AppBlockingBridge> createState() => _AppBlockingBridgeState();
}

class _AppBlockingBridgeState extends State<AppBlockingBridge> {
  AppBlockCoordinator? _coordinator;
  PomodoroController? _pomodoro;
  TimerController? _timer;
  StopwatchController? _stopwatch;
  AppBlockingController? _blocking;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final PomodoroController pomodoro = PomodoroScope.of(context);
    final TimerController timer = TimerScope.of(context);
    final StopwatchController stopwatch = StopwatchScope.of(context);
    final AppBlockingController blocking = AppBlockingScope.of(context);

    final bool controllerChanged =
        pomodoro != _pomodoro || timer != _timer || stopwatch != _stopwatch || blocking != _blocking;

    if (controllerChanged) {
      _coordinator?.dispose();
      _pomodoro = pomodoro;
      _timer = timer;
      _stopwatch = stopwatch;
      _blocking = blocking;
      _coordinator = AppBlockCoordinator(
        pomodoro: pomodoro,
        timer: timer,
        stopwatch: stopwatch,
        blocking: blocking,
      );
    }
  }

  @override
  void dispose() {
    _coordinator?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class AppBlockCoordinator {
  AppBlockCoordinator({
    required PomodoroController pomodoro,
    required TimerController timer,
    required StopwatchController stopwatch,
    required AppBlockingController blocking,
  })  : _pomodoro = pomodoro,
        _timer = timer,
        _stopwatch = stopwatch,
        _blocking = blocking {
    _pomodoro.addListener(_handleChange);
    _timer.addListener(_handleChange);
    _stopwatch.addListener(_handleChange);
    _blocking.addListener(_handleBlockingChanged);
    _scheduleEvaluation();
  }

  final PomodoroController _pomodoro;
  final TimerController _timer;
  final StopwatchController _stopwatch;
  final AppBlockingController _blocking;

  bool _isBlocking = false;
  bool _needsReapply = false;
  bool _disposed = false;
  Future<void>? _pendingWork;
  bool _recheckRequested = false;

  void dispose() {
    _disposed = true;
    _pomodoro.removeListener(_handleChange);
    _timer.removeListener(_handleChange);
    _stopwatch.removeListener(_handleChange);
    _blocking.removeListener(_handleBlockingChanged);
    unawaited(_blocking.clearBlock());
  }

  void _handleChange() {
    _scheduleEvaluation();
  }

  void _handleBlockingChanged() {
    _needsReapply = true;
    _scheduleEvaluation();
  }

  void _scheduleEvaluation() {
    if (_disposed) {
      return;
    }
    if (_pendingWork != null) {
      _recheckRequested = true;
      return;
    }
    final Future<void> future = _evaluate();
    _pendingWork = future;
    future.whenComplete(() {
      if (_pendingWork == future) {
        _pendingWork = null;
        if (_recheckRequested) {
          _recheckRequested = false;
          _scheduleEvaluation();
        }
      }
    });
  }

  Future<void> _evaluate() async {
    final bool shouldBlock = _shouldBlock();
    if (shouldBlock) {
      if (!_isBlocking || _needsReapply) {
        final bool applied = await _blocking.applyActiveSelection();
        _isBlocking = applied;
        _needsReapply = false;
      }
    } else {
      if (_isBlocking || _needsReapply) {
        await _blocking.clearBlock();
      }
      _isBlocking = false;
      _needsReapply = false;
    }
  }

  bool _shouldBlock() {
    final bool pomodoroBlocking = _pomodoro.sessionType == SessionType.focus &&
        (_pomodoro.runState == RunState.running || _pomodoro.runState == RunState.paused);
    final bool timerBlocking =
        _timer.runState == TimerRunState.running || _timer.runState == TimerRunState.paused;
    final bool stopwatchBlocking = _stopwatch.runState == StopwatchRunState.running;
    return pomodoroBlocking || timerBlocking || stopwatchBlocking;
  }
}
