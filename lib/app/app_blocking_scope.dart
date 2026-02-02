import 'package:flutter/material.dart';

import '../services/app_blocking/app_blocking_controller.dart';

class AppBlockingScope extends InheritedNotifier<AppBlockingController> {
  const AppBlockingScope({
    super.key,
    required this.controller,
    required super.child,
  }) : super(notifier: controller);

  final AppBlockingController controller;

  static AppBlockingController of(BuildContext context) {
    final AppBlockingScope? scope =
        context.dependOnInheritedWidgetOfExactType<AppBlockingScope>();
    assert(scope != null, 'AppBlockingScope.of() called with no AppBlockingScope');
    return scope!.controller;
  }
}
