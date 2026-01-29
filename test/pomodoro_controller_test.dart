import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pomodo_app/features/pomodoro/pomodoro_controller.dart';
import 'package:pomodo_app/features/pomodoro/pomodoro_storage.dart';
import 'package:pomodo_app/features/stats/stats_controller.dart';
import 'package:pomodo_app/features/stats/stats_storage.dart';

class _FakePomodoroStorage extends PomodoroStorage {
  PomodoroConfig config = PomodoroConfig.defaults;

  @override
  Future<PomodoroConfig> loadConfig() async => config;

  @override
  Future<void> saveConfig(PomodoroConfig newConfig) async {
    config = newConfig;
  }
}

class _FakeStatsStorage extends StatsStorage {
  @override
  Future<Map<String, DailyStatRecord>> loadDailyStats() async => <String, DailyStatRecord>{};

  @override
  Future<void> saveDailyStats(Map<String, DailyStatRecord> data) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('PomodoroController', () {
    test('short break respects settings across cycles', () {
      fakeAsync((async) {
        final storage = _FakePomodoroStorage();
        final stats = StatsController(storage: _FakeStatsStorage());
        final controller = PomodoroController(
          storage: storage,
          statsController: stats,
        );
        controller.setFocusMinutes(5);
        controller.setBreakMinutes(1);
        controller.setLongBreakMinutes(2);
        controller.setLongBreakEveryCycles(8);

        controller.start();
        async.elapse(const Duration(minutes: 5));
        expect(controller.sessionType, SessionType.breakSession);
        expect(controller.totalSeconds, equals(60));

        async.elapse(const Duration(minutes: 1));
        expect(controller.sessionType, SessionType.focus);

        async.elapse(const Duration(minutes: 5));
        expect(controller.sessionType, SessionType.breakSession);
        expect(controller.totalSeconds, equals(60));
      });
    });

    test('long break state surfaces for display', () {
      fakeAsync((async) {
        final storage = _FakePomodoroStorage();
        final stats = StatsController(storage: _FakeStatsStorage());
        final controller = PomodoroController(
          storage: storage,
          statsController: stats,
        );
        controller.setFocusMinutes(5);
        controller.setBreakMinutes(1);
        controller.setLongBreakMinutes(5);
        controller.setLongBreakEveryCycles(2);

        controller.start();
        async.elapse(const Duration(minutes: 5));
        expect(controller.sessionType, SessionType.breakSession);
        expect(controller.isLongBreakSession, isFalse);

        async.elapse(const Duration(minutes: 1));
        async.elapse(const Duration(minutes: 5));
        expect(controller.sessionType, SessionType.breakSession);
        expect(controller.isLongBreakSession, isTrue);
        expect(controller.totalSeconds, equals(controller.longBreakMinutes * 60));
      });
    });
  });
}
