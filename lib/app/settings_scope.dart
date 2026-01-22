import 'package:flutter/material.dart';

import '../features/settings/settings_controller.dart';

class SettingsScope extends InheritedNotifier<SettingsController> {
  const SettingsScope({
    super.key,
    required this.controller,
    required super.child,
  }) : super(notifier: controller);

  final SettingsController controller;

  static SettingsController of(BuildContext context) {
    final SettingsScope? scope =
        context.dependOnInheritedWidgetOfExactType<SettingsScope>();
    assert(scope != null, 'SettingsScope.of() called with no SettingsScope');
    return scope!.controller;
  }
}
