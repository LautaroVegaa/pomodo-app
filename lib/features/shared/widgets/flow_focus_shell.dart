import 'package:flutter/material.dart';

/// Wraps feature pages to show a distraction-free card when the device is in
/// landscape, the session is running, and the feature is enabled in settings.
class FlowFocusShell extends StatelessWidget {
  const FlowFocusShell({
    super.key,
    required this.enabled,
    required this.isRunning,
    required this.childPortrait,
    required this.childFlowFocus,
  });

  final bool enabled;
  final bool isRunning;
  final Widget childPortrait;
  final Widget childFlowFocus;

  static bool isActive({
    required bool enabled,
    required bool isRunning,
    required Orientation orientation,
  }) {
    return enabled && isRunning && orientation == Orientation.landscape;
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final bool showFlowFocus = FlowFocusShell.isActive(
          enabled: enabled,
          isRunning: isRunning,
          orientation: orientation,
        );
        final Widget child = showFlowFocus
            ? SizedBox.expand(child: childFlowFocus)
            : childPortrait;
        return FlowFocusScope(isActive: showFlowFocus, child: child);
      },
    );
  }
}

class FlowFocusScope extends InheritedWidget {
  const FlowFocusScope({
    super.key,
    required this.isActive,
    required super.child,
  });

  final bool isActive;

  static bool of(BuildContext context) {
    final FlowFocusScope? scope =
        context.dependOnInheritedWidgetOfExactType<FlowFocusScope>();
    return scope?.isActive ?? false;
  }

  @override
  bool updateShouldNotify(FlowFocusScope oldWidget) =>
      oldWidget.isActive != isActive;
}
