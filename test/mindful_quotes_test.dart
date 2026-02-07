import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pomodo_app/app/app_theme.dart';
import 'package:pomodo_app/app/quote_scope.dart';
import 'package:pomodo_app/app/settings_scope.dart';
import 'package:pomodo_app/app/stopwatch_scope.dart';
import 'package:pomodo_app/app/timer_scope.dart';
import 'package:pomodo_app/features/pomodoro/pomodoro_controller.dart';
import 'package:pomodo_app/features/quotes/pomodoro_quote_phase_tracker.dart';
import 'package:pomodo_app/features/quotes/quote_rotation_controller.dart';
import 'package:pomodo_app/features/settings/settings_controller.dart';
import 'package:pomodo_app/features/settings/settings_storage.dart';
import 'package:pomodo_app/features/shared/widgets/animated_progress_bar.dart';
import 'package:pomodo_app/features/shared/widgets/quote_block.dart';
import 'package:pomodo_app/features/stopwatch/stopwatch_page.dart';
import 'package:pomodo_app/features/timer/timer_page.dart';
import 'package:pomodo_app/features/stats/stats_controller.dart';
import 'package:pomodo_app/services/completion_audio_service.dart';
import 'package:pomodo_app/services/completion_banner_controller.dart';
import 'package:pomodo_app/services/notification_service.dart';

import 'test_utils/stats_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('Mindful quotes surfaces', () {
    testWidgets('Timer screen renders quote block', (tester) async {
      _ensureLargeSurface(tester);
      final quoteController = QuoteRotationController(quotes: _testQuotes);
      addTearDown(quoteController.dispose);
      await _pumpTimerPage(tester, quoteController);
      expect(find.byType(QuoteBlock), findsOneWidget);
      expect(find.text('Quote 1'), findsOneWidget);
    });

    testWidgets('Stopwatch screen renders quote block', (tester) async {
      _ensureLargeSurface(tester);
      final quoteController = QuoteRotationController(quotes: _testQuotes);
      addTearDown(quoteController.dispose);
      await _pumpStopwatchPage(tester, quoteController);
      expect(find.byType(QuoteBlock), findsOneWidget);
      expect(find.text('Quote 1'), findsOneWidget);
    });

    testWidgets('Pomodoro quote rotates on each session phase change', (tester) async {
      final quoteController = QuoteRotationController(quotes: _testQuotes);
      addTearDown(quoteController.dispose);
      final ValueNotifier<_PomodoroPhaseState> phase =
          ValueNotifier<_PomodoroPhaseState>(const _PomodoroPhaseState(
        type: SessionType.focus,
        isLongBreak: false,
      ));
      addTearDown(phase.dispose);

      await tester.pumpWidget(
        QuoteScope(
          controller: quoteController,
          child: MaterialApp(
            home: Scaffold(
              body: _PomodoroQuoteHarness(phase: phase),
            ),
          ),
        ),
      );

      expect(find.text('Quote 1'), findsOneWidget);

      phase.value = const _PomodoroPhaseState(
        type: SessionType.breakSession,
        isLongBreak: false,
      );
      await _pumpForQuoteUpdate(tester);
      expect(find.text('Quote 2'), findsOneWidget);

      phase.value = const _PomodoroPhaseState(
        type: SessionType.breakSession,
        isLongBreak: true,
      );
      await _pumpForQuoteUpdate(tester);
      expect(find.text('Quote 3'), findsOneWidget);

      phase.value = const _PomodoroPhaseState(
        type: SessionType.focus,
        isLongBreak: false,
      );
      await _pumpForQuoteUpdate(tester);
      expect(find.text('Quote 4'), findsOneWidget);
    });

    testWidgets('Timer quote rotates with each new start', (tester) async {
      _ensureLargeSurface(tester);
      final quoteController = QuoteRotationController(quotes: _testQuotes);
      addTearDown(quoteController.dispose);
      await _pumpTimerPage(tester, quoteController);

      Finder playFinder() => find.byIcon(Icons.play_arrow_rounded).first;
      final Finder stopFinder = find.byIcon(Icons.stop_rounded).first;

      await tester.tap(playFinder());
      await tester.pump();
      expect(find.text('Quote 2'), findsOneWidget);

      await tester.tap(stopFinder);
      await tester.pump();

      await tester.tap(playFinder());
      await tester.pump();
      expect(find.text('Quote 3'), findsOneWidget);
    });

    testWidgets('Stopwatch quote rotates with each new start', (tester) async {
      _ensureLargeSurface(tester);
      final quoteController = QuoteRotationController(quotes: _testQuotes);
      addTearDown(quoteController.dispose);
      await _pumpStopwatchPage(tester, quoteController);

      Finder playFinder() => find.byIcon(Icons.play_arrow_rounded).first;
      final Finder stopFinder = find.byIcon(Icons.stop_rounded).first;

      await tester.tap(playFinder());
      await tester.pump();
      expect(find.text('Quote 2'), findsOneWidget);

      await tester.tap(stopFinder);
      await tester.pump();

      await tester.tap(playFinder());
      await tester.pump();
      expect(find.text('Quote 3'), findsOneWidget);
    });

    testWidgets('Flow Focus hides quotes and avoids overflow', (tester) async {
      final binding = tester.binding;
      final Size originalSize = binding.window.physicalSize;
      final double originalRatio = binding.window.devicePixelRatio;

      Future<void> setSurface(Size size) async {
        binding.window.physicalSizeTestValue = size;
        binding.window.devicePixelRatioTestValue = 1.0;
        await tester.pump();
      }

      addTearDown(() async {
        binding.window.physicalSizeTestValue = originalSize;
        binding.window.devicePixelRatioTestValue = originalRatio;
        binding.window.clearPhysicalSizeTestValue();
        binding.window.clearDevicePixelRatioTestValue();
        await tester.pump();
      });

      await setSurface(const Size(800, 1200));

      final List<FlutterErrorDetails> flutterErrors = <FlutterErrorDetails>[];
      final FlutterExceptionHandler? originalHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        flutterErrors.add(details);
        originalHandler?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalHandler);

      final quoteController = QuoteRotationController(quotes: _testQuotes);
      addTearDown(quoteController.dispose);
      await _pumpTimerPage(tester, quoteController);

      final Finder playFinder = find.byIcon(Icons.play_arrow_rounded).first;
      await tester.tap(playFinder);
      await tester.pump();
      expect(find.text('Quote 2'), findsOneWidget);

      await setSurface(const Size(1200, 800));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Quote 2'), findsNothing);

      await setSurface(const Size(800, 1200));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Quote 2'), findsOneWidget);

      final bool hasOverflowError = flutterErrors.any(
        (details) => details.exceptionAsString().contains('RenderFlex overflowed'),
      );
      expect(hasOverflowError, isFalse);
    });
  });

  group('Progress indicator visibility', () {
    testWidgets('Stopwatch omits animated progress bar', (tester) async {
      _ensureLargeSurface(tester);
      final quoteController = QuoteRotationController(quotes: _testQuotes);
      addTearDown(quoteController.dispose);
      await _pumpStopwatchPage(tester, quoteController);

      expect(find.text('00:00'), findsOneWidget);
      expect(find.byType(AnimatedProgressBar), findsNothing);
    });

    testWidgets('Timer retains animated progress bar', (tester) async {
      _ensureLargeSurface(tester);
      final quoteController = QuoteRotationController(quotes: _testQuotes);
      addTearDown(quoteController.dispose);
      await _pumpTimerPage(tester, quoteController);

      expect(find.byType(AnimatedProgressBar), findsOneWidget);
    });
  });
}

const List<String> _testQuotes = <String>['Quote 1', 'Quote 2', 'Quote 3', 'Quote 4'];

Future<void> _pumpTimerPage(
  WidgetTester tester,
  QuoteRotationController quoteController,
) async {
  final notificationService = NotificationService.test();
  final settingsController = SettingsController(
    storage: InMemorySettingsStorage(),
    notificationService: notificationService,
  );
  final statsController = StatsController(storage: InMemoryStatsStorage());
  final bannerController = CompletionBannerController();
  final completionAudio = _FakeCompletionAudioService();

  await settingsController.initialize();
  await statsController.initialize();

  addTearDown(() async {
    bannerController.dispose();
    statsController.dispose();
    settingsController.dispose();
    await completionAudio.dispose();
  });

  await tester.pumpWidget(
    QuoteScope(
      controller: quoteController,
      child: SettingsScope(
        controller: settingsController,
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: TimerScope(
            audioService: completionAudio,
            notificationService: notificationService,
            settingsController: settingsController,
            bannerController: bannerController,
            statsController: statsController,
            child: const TimerPage(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpStopwatchPage(
  WidgetTester tester,
  QuoteRotationController quoteController,
) async {
  final settingsController = SettingsController(
    storage: InMemorySettingsStorage(),
    notificationService: NotificationService.test(),
  );
  final statsController = StatsController(storage: InMemoryStatsStorage());

  await settingsController.initialize();
  await statsController.initialize();

  addTearDown(() {
    statsController.dispose();
    settingsController.dispose();
  });

  await tester.pumpWidget(
    QuoteScope(
      controller: quoteController,
      child: SettingsScope(
        controller: settingsController,
        child: StopwatchScope(
          statsController: statsController,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const StopwatchPage(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void _ensureLargeSurface(WidgetTester tester) {
  final binding = tester.binding;
  final Size originalSize = binding.window.physicalSize;
  final double originalRatio = binding.window.devicePixelRatio;
  binding.window.physicalSizeTestValue = const Size(1080, 1920);
  binding.window.devicePixelRatioTestValue = 1.0;
  addTearDown(() async {
    binding.window.physicalSizeTestValue = originalSize;
    binding.window.devicePixelRatioTestValue = originalRatio;
    binding.window.clearPhysicalSizeTestValue();
    binding.window.clearDevicePixelRatioTestValue();
    await tester.pump();
  });
}

Future<void> _pumpForQuoteUpdate(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

class _FakeCompletionAudioService implements CompletionAudioService {
  @override
  Future<void> debugWarmupPlayback() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<void> playCompletionCue() async {}
}

class _PomodoroQuoteHarness extends StatefulWidget {
  const _PomodoroQuoteHarness({required this.phase});

  final ValueNotifier<_PomodoroPhaseState> phase;

  @override
  State<_PomodoroQuoteHarness> createState() => _PomodoroQuoteHarnessState();
}

class _PomodoroQuoteHarnessState extends State<_PomodoroQuoteHarness> {
  final PomodoroQuotePhaseTracker _tracker = PomodoroQuotePhaseTracker();

  @override
  Widget build(BuildContext context) {
    final QuoteRotationController quoteController = QuoteScope.of(context);
    return ValueListenableBuilder<_PomodoroPhaseState>(
      valueListenable: widget.phase,
      builder: (context, state, _) {
        if (_tracker.shouldRotate(state.type, state.isLongBreak)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              quoteController.rotate(reason: 'pomodoro_session_change');
            }
          });
        }
        return const QuoteBlock();
      },
    );
  }
}

class _PomodoroPhaseState {
  const _PomodoroPhaseState({
    required this.type,
    required this.isLongBreak,
  });

  final SessionType type;
  final bool isLongBreak;
}

class InMemorySettingsStorage extends SettingsStorage {
  ExperienceSettings _settings = ExperienceSettings.defaults;

  @override
  Future<ExperienceSettings> loadExperience() async => _settings;

  @override
  Future<void> saveExperience(ExperienceSettings settings) async {
    _settings = settings;
  }
}
