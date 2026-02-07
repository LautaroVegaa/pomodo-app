import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pomodo_app/features/stats/stats_controller.dart';
import 'package:pomodo_app/features/timer/timer_controller.dart';

import 'test_utils/stats_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TimerController stats integration', () {
    test('records configured minutes when timer completes', () {
      fakeAsync((async) {
        final stats = StatsController(storage: InMemoryStatsStorage());
        stats.initialize();
        async.flushMicrotasks();
        stats.applyUserScope(userUid: 'timer-complete');
        async.flushMicrotasks();
        final clock = TestClock();
        final controller = TimerController(
          initialMinutes: 10,
          statsController: stats,
          nowProvider: clock.now,
        );

        controller.start();
        clock.advance(async, const Duration(minutes: 10));

        expect(stats.lifetimeMinutes, 10);
        expect(stats.lifetimeSessions, 0);
      });
    });

    test('records elapsed whole minutes when stopped early', () {
      fakeAsync((async) {
        final stats = StatsController(storage: InMemoryStatsStorage());
        stats.initialize();
        async.flushMicrotasks();
        stats.applyUserScope(userUid: 'timer-stop');
        async.flushMicrotasks();
        final clock = TestClock();
        final controller = TimerController(
          initialMinutes: 20,
          statsController: stats,
          nowProvider: clock.now,
        );

        controller.start();
        clock.advance(async, const Duration(minutes: 7, seconds: 45));
        controller.stop();

        expect(stats.lifetimeMinutes, 7);
        expect(stats.lifetimeSessions, 0);
      });
    });
  });
}
