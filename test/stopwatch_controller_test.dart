import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pomodo_app/features/stats/stats_controller.dart';
import 'package:pomodo_app/features/stopwatch/stopwatch_controller.dart';

import 'test_utils/stats_test_utils.dart';

void main() {
  test('invokes callback when reset after at least one minute', () {
    DateTime currentTime = DateTime(2024, 1, 1, 10, 0, 0);
    final List<Duration> recorded = <Duration>[];
    final StopwatchController controller = StopwatchController(
      nowProvider: () => currentTime,
      onFocusRecorded: recorded.add,
    );

    controller.start();
    currentTime = currentTime.add(const Duration(minutes: 1, seconds: 30));
    controller.reset();

    expect(recorded, hasLength(1));
    expect(recorded.first.inMinutes, 1);
  });

  test('does not record sessions shorter than one minute', () {
    DateTime currentTime = DateTime(2024, 1, 1, 11, 0, 0);
    final List<Duration> recorded = <Duration>[];
    final StopwatchController controller = StopwatchController(
      nowProvider: () => currentTime,
      onFocusRecorded: recorded.add,
    );

    controller.start();
    currentTime = currentTime.add(const Duration(seconds: 45));
    controller.reset();

    expect(recorded, isEmpty);
  });

  test('records stats minutes without sessions when reset', () {
    fakeAsync((async) {
      final stats = StatsController(storage: InMemoryStatsStorage());
      stats.initialize();
      async.flushMicrotasks();
      stats.applyUserScope(userUid: 'stopwatch');
      async.flushMicrotasks();
      final clock = TestClock();
      final StopwatchController controller = StopwatchController(
        nowProvider: clock.now,
        onFocusRecorded: (elapsed) {
          final int minutes = elapsed.inMinutes;
          if (minutes <= 0) {
            return;
          }
          stats.recordFocusCompletion(
            completionTime: clock.now(),
            focusMinutes: minutes,
            countSession: false,
            includeMinutes: true,
          );
        },
      );

      controller.start();
      clock.advance(async, const Duration(minutes: 3, seconds: 20));
      controller.reset();

      expect(stats.lifetimeMinutes, 3);
      expect(stats.lifetimeSessions, 0);
    });
  });
}
