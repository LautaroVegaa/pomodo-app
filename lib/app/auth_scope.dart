import 'package:flutter/widgets.dart';

import '../services/auth/auth_controller.dart';

class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({super.key, required AuthController controller, required super.child})
      : super(notifier: controller);

  static AuthController of(BuildContext context) {
    final AuthScope? scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope.of() called with no AuthScope in context');
    return scope!.notifier!;
  }
}
