import 'dart:async';

import 'package:flutter/material.dart';

import '../features/pomodoro/pomodoro_controller.dart';
import '../features/settings/settings_controller.dart';
import '../features/stats/stats_controller.dart';

class PomodoroScope extends StatefulWidget {
  const PomodoroScope({
    super.key,
    required this.child,
    required this.settingsController,
    required this.statsController,
  });

  final Widget child;
  final SettingsController settingsController;
  final StatsController statsController;

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
    final SettingsController settings = widget.settingsController;
    _controller = PomodoroController(
      hapticsEnabledResolver: () => settings.hapticsEnabled,
      soundsEnabledResolver: () => settings.soundsEnabled,
      statsController: widget.statsController,
    );
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
