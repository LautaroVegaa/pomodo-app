import 'package:flutter/material.dart';

import '../features/stats/stats_controller.dart';
import '../features/stopwatch/stopwatch_controller.dart';

class StopwatchScope extends StatefulWidget {
  const StopwatchScope({super.key, required this.child, required this.statsController});

  final Widget child;
  final StatsController statsController;

  static StopwatchController of(BuildContext context) {
    final _StopwatchInherited? inherited =
        context.dependOnInheritedWidgetOfExactType<_StopwatchInherited>();
    assert(inherited != null, 'StopwatchScope.of() called with no StopwatchScope');
    return inherited!.controller;
  }

  @override
  State<StopwatchScope> createState() => _StopwatchScopeState();
}

class _StopwatchScopeState extends State<StopwatchScope>
    with WidgetsBindingObserver {
  late final StopwatchController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = StopwatchController(
      onFocusRecorded: _recordStopwatchSession,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _controller.handleLifecycleChange(state);
  }

  @override
  Widget build(BuildContext context) {
    return _StopwatchInherited(controller: _controller, child: widget.child);
  }

  void _recordStopwatchSession(Duration elapsed) {
    final int minutes = elapsed.inMinutes;
    if (minutes <= 0) {
      return;
    }
    debugPrint(
      '[StatsDebug] StopwatchController#${_controller.hashCode} recordFocusCompletion '
      'minutes=$minutes',
    );
    widget.statsController.recordFocusCompletion(
      completionTime: DateTime.now(),
      focusMinutes: minutes,
      countSession: false,
      includeMinutes: true,
    );
  }
}

class _StopwatchInherited extends InheritedNotifier<StopwatchController> {
  const _StopwatchInherited({required this.controller, required super.child})
      : super(notifier: controller);

  final StopwatchController controller;
}
