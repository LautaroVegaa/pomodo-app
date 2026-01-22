import 'package:flutter/material.dart';

import '../features/stats/stats_controller.dart';

class StatsScope extends InheritedNotifier<StatsController> {
  const StatsScope({
    super.key,
    required this.controller,
    required super.child,
  }) : super(notifier: controller);

  final StatsController controller;

  static StatsController of(BuildContext context) {
    final StatsScope? scope =
        context.dependOnInheritedWidgetOfExactType<StatsScope>();
    assert(scope != null, 'StatsScope.of() called with no StatsScope');
    return scope!.controller;
  }
}
