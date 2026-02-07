// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pomodo_app/app/app.dart';
import 'package:pomodo_app/app/app_theme.dart';
import 'package:pomodo_app/features/shared/widgets/app_bottom_nav.dart';
import 'package:pomodo_app/features/shared/widgets/flow_focus_shell.dart';
import 'package:pomodo_app/firebase_options.dart';
import 'package:pomodo_app/services/notification_service.dart';

const String _guestDisabledKey = 'auth.guest_access_disabled';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      _guestDisabledKey: false,
    });
  });

  setUpAll(() async {
    setupFirebaseCoreMocks();
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on FirebaseException catch (error) {
      if (error.code != 'duplicate-app') {
        rethrow;
      }
    }
  });

  testWidgets('Editorial onboarding advances through screens', (tester) async {
    final notificationService = NotificationService.test();
    await tester.pumpWidget(
      PomodoApp(
        notificationService: notificationService,
        startSignedIn: false,
        enableAudioWarmup: false,
      ),
    );

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

    final thirdArrow = find.byIcon(Icons.arrow_forward_rounded);
    await tester.tap(thirdArrow);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('How old are you?'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('What is your main goal with Pomodo?'), findsOneWidget);
    await tester.tap(find.text('Improve focus'));
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('What usually gets in your way?'), findsOneWidget);
    await tester.tap(find.text('Lack of focus'));
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('How much time do you spend on your phone daily?'), findsOneWidget);
    await tester.tap(find.text('2–4 hours'));
    await tester.pump();

    final startPomodoCta = find.text('Start Pomodo');
    expect(startPomodoCta, findsOneWidget);

    await tester.tap(startPomodoCta);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue without account'), findsOneWidget);

    await tester.tap(find.text('Continue without account'));
    await tester.pumpAndSettle();

    expect(find.text('Pomodō.'), findsOneWidget);
    expect(find.text('Focus'), findsWidgets);
    expect(find.text('25:00'), findsOneWidget);

    final homeScroll = find.byType(ListView).first;
    await tester.drag(homeScroll, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(
      find.text('Every time you switch apps, your focus pays the price.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();

    expect(find.text('Daily'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Consistency is built quietly.'), findsOneWidget);
  });

  testWidgets('Bottom navigation hides while Flow Focus is active', (tester) async {
    final binding = tester.binding;
    final Size originalSize = binding.window.physicalSize;
    final double originalRatio = binding.window.devicePixelRatio;

    Future<void> setSurface(Size size) async {
      binding.window.physicalSizeTestValue = size;
      binding.window.devicePixelRatioTestValue = 1.0;
      await tester.pump();
    }

    // Begin in portrait.
    await setSurface(const Size(800, 1200));

    addTearDown(() async {
      binding.window.physicalSizeTestValue = originalSize;
      binding.window.devicePixelRatioTestValue = originalRatio;
      binding.window.clearPhysicalSizeTestValue();
      binding.window.clearDevicePixelRatioTestValue();
      await tester.pump();
    });

    final ValueNotifier<bool> isRunning = ValueNotifier<bool>(false);
    addTearDown(isRunning.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        home: _FlowFocusHarness(isRunning: isRunning),
      ),
    );

    await tester.pump();
    expect(find.byType(AppBottomNav), findsOneWidget);

    // When running + portrait => nav still visible.
    isRunning.value = true;
    await tester.pump();
    expect(find.byType(AppBottomNav), findsOneWidget);

    // Landscape triggers Flow Focus -> nav hidden.
    await setSurface(const Size(1200, 800));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(AppBottomNav), findsNothing);

    // Back to portrait -> nav returns.
    await setSurface(const Size(800, 1200));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(AppBottomNav), findsOneWidget);
  });
}

class _FlowFocusHarness extends StatelessWidget {
  const _FlowFocusHarness({required this.isRunning});

  final ValueNotifier<bool> isRunning;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: isRunning,
      builder: (context, _) {
        final Orientation orientation = MediaQuery.of(context).orientation;
        final bool flowFocusActive = FlowFocusShell.isActive(
          enabled: true,
          isRunning: isRunning.value,
          orientation: orientation,
        );
        return Scaffold(
          body: FlowFocusShell(
            enabled: true,
            isRunning: isRunning.value,
            childPortrait: const Center(child: Text('Portrait view')),
            childFlowFocus: const Center(child: Text('Flow Focus view')),
          ),
          bottomNavigationBar: flowFocusActive
              ? null
              : const Padding(
                  padding: EdgeInsets.only(left: 24, right: 24, bottom: 12),
                  child: AppBottomNav(
                    selected: AppNavSection.focus,
                  ),
                ),
        );
      },
    );
  }
}
