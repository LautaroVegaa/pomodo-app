import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pomodo_app/features/pomodoro/pomodoro_controller.dart';
import 'package:pomodo_app/features/pomodoro/pomodoro_storage.dart';
import 'package:pomodo_app/features/settings/settings_controller.dart';
import 'package:pomodo_app/features/settings/settings_storage.dart';
import 'package:pomodo_app/features/timer/timer_controller.dart';
import 'package:pomodo_app/services/completion_banner_controller.dart';
import 'package:pomodo_app/services/notification_service.dart';

void main() {
  group('Notification workflows', () {
    test('Pomodoro schedules and cancels notifications through lifecycle changes', () {
      final spy = _SpyNotificationService();
      final clock = _TestClock();
      final controller = PomodoroController(
        storage: _FakePomodoroStorage(),
        notificationService: spy,
        bannerController: CompletionBannerController(),
        notificationsEnabledResolver: () => true,
        nowProvider: clock.now,
      )..setFocusMinutes(5);

      controller.start();
      expect(spy.sessionSchedules, greaterThanOrEqualTo(1));

      controller.handleLifecycleChange(AppLifecycleState.paused);
      expect(spy.sessionSchedules, 2);

      controller.handleLifecycleChange(AppLifecycleState.resumed);
      expect(spy.sessionCancels, greaterThanOrEqualTo(1));
      controller.dispose();
    });

    test('Timer schedules completion notification and cancels on stop', () {
      final spy = _SpyNotificationService();
      final clock = _TestClock();
      final controller = TimerController(
        initialMinutes: 5,
        notificationService: spy,
        bannerController: CompletionBannerController(),
        notificationsEnabledResolver: () => true,
        nowProvider: clock.now,
      );

      controller.start();
      expect(spy.timerSchedules, greaterThanOrEqualTo(1));

      controller.stop();
      expect(spy.timerCancels, greaterThanOrEqualTo(1));
      controller.dispose();
    });

    test('Notifications disabled skip scheduling attempts', () {
      final spy = _SpyNotificationService()..notificationsAllowed = false;
      spy.setNotificationsEnabledResolver(() => false);
      final clock = _TestClock();
      final controller = PomodoroController(
        storage: _FakePomodoroStorage(),
        notificationService: spy,
        bannerController: CompletionBannerController(),
        notificationsEnabledResolver: () => false,
        nowProvider: clock.now,
      )..setFocusMinutes(5);

      controller.start();
      expect(spy.sessionSchedules, 0);
      controller.dispose();
    });

    test('Settings toggle cancels pending notifications and re-checks permissions', () async {
      final spy = _SpyNotificationService();
      final controller = SettingsController(
        storage: _FakeSettingsStorage(),
        notificationService: spy,
      );

      await controller.initialize();
      controller.setNotificationsEnabled(false);
      expect(spy.cancelAllCount, 1);

      controller.setNotificationsEnabled(true);
      await Future<void>.delayed(Duration.zero);
      expect(spy.permissionsEnsured, isTrue);
    });
  });
}

class _SpyNotificationService extends NotificationService {
  _SpyNotificationService() : super.test();

  bool notificationsAllowed = true;
  int sessionSchedules = 0;
  int timerSchedules = 0;
  int sessionCancels = 0;
  int timerCancels = 0;
  int cancelAllCount = 0;
  bool permissionsEnsured = false;
  bool Function()? _resolver;

  @override
  void setNotificationsEnabledResolver(bool Function() resolver) {
    _resolver = resolver;
  }

  bool get _notificationsEnabled => _resolver?.call() ?? notificationsAllowed;

  @override
  Future<void> scheduleSessionCompletionNotification({
    required DateTime scheduledTime,
    required bool isFocusSession,
  }) async {
    if (!_notificationsEnabled) return;
    sessionSchedules += 1;
  }

  @override
  Future<void> cancelScheduledSessionNotification() async {
    sessionCancels += 1;
  }

  @override
  Future<void> scheduleTimerCompletionNotification({
    required DateTime scheduledTime,
  }) async {
    if (!_notificationsEnabled) return;
    timerSchedules += 1;
  }

  @override
  Future<void> cancelScheduledTimerNotification() async {
    timerCancels += 1;
  }

  @override
  Future<void> cancelAllNotifications() async {
    cancelAllCount += 1;
  }

  @override
  Future<bool> ensurePermissionsGranted() async {
    permissionsEnsured = true;
    return true;
  }
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

class _FakeSettingsStorage extends SettingsStorage {
  ExperienceSettings _settings = ExperienceSettings.defaults;

  @override
  Future<ExperienceSettings> loadExperience() async => _settings;

  @override
  Future<void> saveExperience(ExperienceSettings settings) async {
    _settings = settings;
  }
}

class _TestClock {
  _TestClock() : _current = DateTime(2024, 1, 1);

  final DateTime _current;

  DateTime now() => _current;
}
