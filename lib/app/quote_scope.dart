import 'package:flutter/material.dart';

import '../features/quotes/quote_rotation_controller.dart';

class QuoteScope extends InheritedNotifier<QuoteRotationController> {
  const QuoteScope({
    super.key,
    required this.controller,
    required super.child,
  }) : super(notifier: controller);

  final QuoteRotationController controller;

  static QuoteRotationController of(BuildContext context) {
    final QuoteScope? scope =
        context.dependOnInheritedWidgetOfExactType<QuoteScope>();
    assert(scope != null, 'QuoteScope.of() called with no QuoteScope');
    return scope!.controller;
  }
}
