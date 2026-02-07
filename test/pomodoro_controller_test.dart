import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pomodo_app/features/pomodoro/pomodoro_controller.dart';
import 'package:pomodo_app/features/pomodoro/pomodoro_storage.dart';
import 'package:pomodo_app/features/stats/stats_controller.dart';

import 'test_utils/stats_test_utils.dart';

class _FakePomodoroStorage extends PomodoroStorage {
  PomodoroConfig config = PomodoroConfig.defaults;

  @override
  Future<PomodoroConfig> loadConfig() async => config;

  @override
  Future<void> saveConfig(PomodoroConfig newConfig) async {
    config = newConfig;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('PomodoroController', () {
    test('short break respects settings across cycles', () {
      fakeAsync((async) {
        final storage = _FakePomodoroStorage();
        final stats = StatsController(storage: InMemoryStatsStorage());
        final clock = _TestClock();
        final controller = PomodoroController(
          storage: storage,
          statsController: stats,
          nowProvider: clock.now,
        );
        controller.setFocusMinutes(5);
        controller.setBreakMinutes(1);
        controller.setLongBreakMinutes(2);
        controller.setLongBreakEveryCycles(8);

        controller.start();
        clock.advance(async, const Duration(minutes: 5));
        expect(controller.sessionType, SessionType.breakSession);
        expect(controller.totalSeconds, equals(60));

        clock.advance(async, const Duration(minutes: 1));
        expect(controller.sessionType, SessionType.focus);

        clock.advance(async, const Duration(minutes: 5));
        expect(controller.sessionType, SessionType.breakSession);
        expect(controller.totalSeconds, equals(60));
      });
    });

    test('long break state surfaces for display', () {
      fakeAsync((async) {
        final storage = _FakePomodoroStorage();
        final stats = StatsController(storage: InMemoryStatsStorage());
        final clock = _TestClock();
        final controller = PomodoroController(
          storage: storage,
          statsController: stats,
          nowProvider: clock.now,
        );
        controller.setFocusMinutes(5);
        controller.setBreakMinutes(1);
        controller.setLongBreakMinutes(5);
        controller.setLongBreakEveryCycles(2);

        controller.start();
        clock.advance(async, const Duration(minutes: 5));
        expect(controller.sessionType, SessionType.breakSession);
        expect(controller.isLongBreakSession, isFalse);

        clock.advance(async, const Duration(minutes: 1));
        clock.advance(async, const Duration(minutes: 5));
        expect(controller.sessionType, SessionType.breakSession);
        expect(controller.isLongBreakSession, isTrue);
        expect(controller.totalSeconds, equals(controller.longBreakMinutes * 60));
      });
    });

    test('focus stats update while timer runs and ignore breaks', () {
      fakeAsync((async) {
        final storage = _FakePomodoroStorage();
        final stats = StatsController(storage: InMemoryStatsStorage());
        stats.initialize();
        async.flushMicrotasks();
        stats.applyUserScope(userUid: 'user-live');
        async.flushMicrotasks();
        expect(stats.debugActiveUserKey, isNotNull);
        final clock = _TestClock();
        final controller = PomodoroController(
          storage: storage,
          statsController: stats,
          nowProvider: clock.now,
        );
        controller.setFocusMinutes(5);
        controller.setBreakMinutes(1);

        controller.start();
        clock.advance(async, const Duration(minutes: 1));
        expect(stats.lifetimeMinutes, 1);
        expect(stats.lifetimeSessions, 0);

        clock.advance(async, const Duration(minutes: 1));
        expect(stats.lifetimeMinutes, 2);
        expect(stats.lifetimeSessions, 0);

        clock.advance(async, const Duration(minutes: 3));
        expect(stats.lifetimeMinutes, 5);
        expect(stats.lifetimeSessions, 1);
        expect(controller.sessionType, SessionType.breakSession);

        clock.advance(async, const Duration(minutes: 1));
        expect(stats.lifetimeMinutes, 5);
        expect(stats.lifetimeSessions, 1);
      });
    });
  });
}

typedef _TestClock = TestClock;
