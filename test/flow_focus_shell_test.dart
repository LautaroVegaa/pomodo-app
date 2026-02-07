import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pomodo_app/features/shared/widgets/flow_focus_shell.dart';

void main() {
  void addWindowCleanup(WidgetTester tester) {
    final Size originalSize = tester.binding.window.physicalSize;
    final double originalRatio = tester.binding.window.devicePixelRatio;
    addTearDown(() async {
      tester.binding.window.physicalSizeTestValue = originalSize;
      tester.binding.window.devicePixelRatioTestValue = originalRatio;
      await tester.pump();
    });
  }

  Future<void> setSurfaceSize(WidgetTester tester, Size size) async {
    tester.binding.window.physicalSizeTestValue = size;
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    await tester.pump();
  }

  Widget buildSubject({required bool enabled, required bool isRunning}) {
    return MaterialApp(
      home: FlowFocusShell(
        enabled: enabled,
        isRunning: isRunning,
        childPortrait: Column(
          children: const [
            Text('Header'),
            Text('Controls'),
          ],
        ),
        childFlowFocus: const Center(child: Text('FocusCard')),
      ),
    );
  }

  testWidgets('landscape idle sessions stay on portrait layout', (tester) async {
    addWindowCleanup(tester);

    await setSurfaceSize(tester, const Size(1200, 800));
    await tester.pumpWidget(buildSubject(enabled: true, isRunning: false));

    expect(find.text('Header'), findsOneWidget);
    expect(find.text('FocusCard'), findsNothing);
  });

  testWidgets('running sessions enter Flow Focus only in landscape when enabled',
      (tester) async {
    addWindowCleanup(tester);

    await setSurfaceSize(tester, const Size(800, 1200));
    await tester.pumpWidget(buildSubject(enabled: true, isRunning: true));
    expect(find.text('Header'), findsOneWidget);
    expect(find.text('FocusCard'), findsNothing);

    await setSurfaceSize(tester, const Size(1200, 800));
    await tester.pump();
    expect(find.text('FocusCard'), findsOneWidget);
    expect(find.text('Header'), findsNothing);
  });

  testWidgets('disabled toggle prevents Flow Focus even when running', (tester) async {
    addWindowCleanup(tester);

    await setSurfaceSize(tester, const Size(1200, 800));
    await tester.pumpWidget(buildSubject(enabled: false, isRunning: true));

    expect(find.text('Header'), findsOneWidget);
    expect(find.text('FocusCard'), findsNothing);
  });

  testWidgets('returning to portrait exits Flow Focus immediately', (tester) async {
    addWindowCleanup(tester);

    await setSurfaceSize(tester, const Size(1200, 800));
    await tester.pumpWidget(buildSubject(enabled: true, isRunning: true));
    expect(find.text('FocusCard'), findsOneWidget);
    expect(find.text('Header'), findsNothing);

    await setSurfaceSize(tester, const Size(800, 1200));
    await tester.pump();
    expect(find.text('Header'), findsOneWidget);
    expect(find.text('FocusCard'), findsNothing);
  });
}
