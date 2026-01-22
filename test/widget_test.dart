// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pomodo_app/app/app.dart';

void main() {
  testWidgets('Editorial onboarding advances through screens', (tester) async {
    await tester.pumpWidget(const PomodoApp());

    expect(
      find.textContaining('Your attention', findRichText: true),
      findsOneWidget,
    );

    final arrowFinder = find.byIcon(Icons.arrow_forward_rounded);
    expect(arrowFinder, findsOneWidget);

    await tester.tap(arrowFinder);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Pomodo brings you', findRichText: true),
      findsOneWidget,
    );

    final arrowFinderSecond = find.byIcon(Icons.arrow_forward_rounded);
    await tester.tap(arrowFinderSecond);
    await tester.pumpAndSettle();

    final startButton = find.text('Start Pomodo');
    expect(startButton, findsOneWidget);

    await tester.tap(startButton);
    await tester.pumpAndSettle();

    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue without account'), findsOneWidget);

    await tester.tap(find.text('Continue with Apple'));
    await tester.pumpAndSettle();

    expect(find.text('Pomodō.'), findsOneWidget);
    expect(find.text('Focus'), findsWidgets);
    expect(find.text('25:00'), findsOneWidget);
    expect(
      find.textContaining('El foco es un músculo'),
      findsOneWidget,
    );

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();

    expect(find.text('Daily'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Consistency is built quietly.'), findsOneWidget);
  });
}
