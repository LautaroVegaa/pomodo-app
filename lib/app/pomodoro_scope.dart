import 'dart:async';

import 'package:flutter/material.dart';

import '../features/pomodoro/pomodoro_controller.dart';

class PomodoroScope extends StatefulWidget {
  const PomodoroScope({super.key, required this.child});

  final Widget child;

  static PomodoroController of(BuildContext context) {
    final _PomodoroInherited? inherited = context
        .dependOnInheritedWidgetOfExactType<_PomodoroInherited>();
    assert(
      inherited != null,
      'PomodoroScope.of() called with no PomodoroScope in context',
    );
    return inherited!.controller;
  }

  @override
  State<PomodoroScope> createState() => _PomodoroScopeState();
}

class _PomodoroScopeState extends State<PomodoroScope>
    with WidgetsBindingObserver {
  late final PomodoroController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = PomodoroController();
    unawaited(_controller.initialize());
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
    return _PomodoroInherited(controller: _controller, child: widget.child);
  }
}

class _PomodoroInherited extends InheritedNotifier<PomodoroController> {
  const _PomodoroInherited({required this.controller, required super.child})
    : super(notifier: controller);

  final PomodoroController controller;
}
