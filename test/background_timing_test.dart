import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pomodo_app/features/pomodoro/pomodoro_controller.dart';
import 'package:pomodo_app/features/pomodoro/pomodoro_storage.dart';
import 'package:pomodo_app/features/stopwatch/stopwatch_controller.dart';
import 'package:pomodo_app/features/timer/timer_controller.dart';
import 'package:pomodo_app/services/completion_banner_controller.dart';

void main() {
  group('Background timing correctness', () {
    test('PomodoroController keeps accurate time when app resumes after 20s', () {
      final clock = _TestClock();
      final controller = PomodoroController(
        storage: _FakePomodoroStorage(),
        bannerController: CompletionBannerController(),
        notificationsEnabledResolver: () => true,
        nowProvider: clock.now,
      )..setFocusMinutes(5);

      controller.start();
      controller.handleLifecycleChange(AppLifecycleState.paused);
      clock.advance(const Duration(seconds: 20));
      controller.handleLifecycleChange(AppLifecycleState.resumed);

      expect(controller.remainingSeconds, (5 * 60) - 20);
      controller.dispose();
    });

    test('TimerController keeps accurate time when app resumes after 20s', () {
      final clock = _TestClock();
      final controller = TimerController(
        initialMinutes: 5,
        bannerController: CompletionBannerController(),
        notificationsEnabledResolver: () => true,
        nowProvider: clock.now,
      );

      controller.start();
      controller.handleLifecycleChange(AppLifecycleState.paused);
      clock.advance(const Duration(seconds: 20));
      controller.handleLifecycleChange(AppLifecycleState.resumed);

      expect(controller.remainingSeconds, (5 * 60) - 20);
      controller.dispose();
    });

    test('StopwatchController elapsed time advances while backgrounded 20s', () {
      final clock = _TestClock();
      final controller = StopwatchController(nowProvider: clock.now);

      controller.start();
      controller.handleLifecycleChange(AppLifecycleState.paused);
      clock.advance(const Duration(seconds: 20));
      controller.handleLifecycleChange(AppLifecycleState.resumed);

      expect(controller.elapsed.inSeconds, 20);
      controller.dispose();
    });
  });
}

class _FakePomodoroStorage extends PomodoroStorage {
  PomodoroConfig _config = PomodoroConfig.defaults;

  @override
  Future<PomodoroConfig> loadConfig() async => _config;

  @override
  Future<void> saveConfig(PomodoroConfig config) async {
    _config = config;
  }
}

class _TestClock {
  _TestClock() : _current = DateTime(2024, 1, 1, 0, 0, 0);

  DateTime _current;

  DateTime now() => _current;

  void advance(Duration delta) {
    _current = _current.add(delta);
  }
}
