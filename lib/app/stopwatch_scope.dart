import 'package:flutter/material.dart';

import '../features/stopwatch/stopwatch_controller.dart';

class StopwatchScope extends StatefulWidget {
  const StopwatchScope({super.key, required this.child});

  final Widget child;

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
    _controller = StopwatchController();
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
}

class _StopwatchInherited extends InheritedNotifier<StopwatchController> {
  const _StopwatchInherited({required this.controller, required super.child})
      : super(notifier: controller);

  final StopwatchController controller;
}
