import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService({bool Function()? notificationsEnabledResolver})
      : _plugin = FlutterLocalNotificationsPlugin(),
        _notificationsEnabledResolver = notificationsEnabledResolver;

  NotificationService.test()
      : _plugin = null,
        _notificationsEnabledResolver = null;

  final FlutterLocalNotificationsPlugin? _plugin;
  bool Function()? _notificationsEnabledResolver;
  bool _permissionsGranted = false;
  bool _permissionWarningLogged = false;

  static const String _channelId = 'pomodo_session_channel';
  static const String _channelName = 'Pomodo Sessions';
  static const String _channelDescription =
      'Alerts you when Pomodo focus and break sessions finish.';
  static const int _sessionNotificationId = 1001;
  static const int _timerNotificationId = 1002;

  void setNotificationsEnabledResolver(bool Function() resolver) {
    _notificationsEnabledResolver = resolver;
  }

  Future<void> initialize() async {
    final FlutterLocalNotificationsPlugin? plugin = _plugin;
    if (plugin == null) {
      return;
    }

    final (
      initSettings: darwinInitSettings,
      notificationDetails: _,
    ) = configureIOSNotifications();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinInitSettings,
      macOS: darwinInitSettings,
    );

    await plugin.initialize(initSettings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );

    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _permissionsGranted = await _requestPermissions(plugin);
    _log('Permissions granted: $_permissionsGranted');
  }

  Future<void> scheduleSessionCompletionNotification({
    required DateTime scheduledTime,
    required bool isFocusSession,
  }) async {
    await _scheduleNotification(
      id: _sessionNotificationId,
      scheduledTime: scheduledTime,
      title: isFocusSession ? 'Focus complete' : 'Break complete',
      body: isFocusSession ? 'Time for a break.' : 'Back to focus.',
      payload: isFocusSession ? 'focus_complete' : 'break_complete',
      debugLabel: isFocusSession ? 'focus' : 'break',
    );
  }

  Future<void> cancelScheduledSessionNotification() async {
    await _cancelScheduledNotification(
      id: _sessionNotificationId,
      debugLabel: 'pomodoro',
    );
  }

  Future<void> scheduleTimerCompletionNotification({
    required DateTime scheduledTime,
  }) async {
    await _scheduleNotification(
      id: _timerNotificationId,
      scheduledTime: scheduledTime,
      title: 'Timer done',
      body: 'Your session is complete.',
      payload: 'timer_complete',
      debugLabel: 'timer',
    );
  }

  Future<void> cancelScheduledTimerNotification() async {
    await _cancelScheduledNotification(id: _timerNotificationId, debugLabel: 'timer');
  }

  ({
    DarwinInitializationSettings initSettings,
    DarwinNotificationDetails notificationDetails,
  }) configureIOSNotifications() {
    const DarwinInitializationSettings initSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const DarwinNotificationDetails notificationDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return (initSettings: initSettings, notificationDetails: notificationDetails);
  }

  Future<void> _scheduleNotification({
    required int id,
    required DateTime scheduledTime,
    required String title,
    required String body,
    required String payload,
    required String debugLabel,
  }) async {
    if (!_areNotificationsEnabled) {
      _log('Notifications disabled; skipping $debugLabel notification schedule.');
      return;
    }
    final FlutterLocalNotificationsPlugin? plugin = _plugin;
    if (plugin == null) {
      _log('Plugin unavailable; cannot schedule $debugLabel notification.');
      return;
    }
    if (scheduledTime.isBefore(DateTime.now())) {
      _log('Skipping $debugLabel notification; scheduled time $scheduledTime is in the past.');
      return;
    }
    if (!await _ensurePermissions(plugin)) {
      _log('Permissions missing; skipping $debugLabel notification schedule.');
      return;
    }

    final tz.TZDateTime tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
    final (
      initSettings: _,
      notificationDetails: darwinDetails,
    ) = configureIOSNotifications();

    final NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
      ),
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await plugin.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
    _log('Scheduled $debugLabel notification (id: $id) for $scheduledTime.');
  }

  Future<void> cancelAllNotifications() async {
    await _cancelScheduledNotification(
      id: _sessionNotificationId,
      debugLabel: 'pomodoro',
    );
    await _cancelScheduledNotification(
      id: _timerNotificationId,
      debugLabel: 'timer',
    );
  }

  Future<bool> ensurePermissionsGranted() async {
    final FlutterLocalNotificationsPlugin? plugin = _plugin;
    if (plugin == null) {
      return true;
    }
    return _ensurePermissions(plugin);
  }

  Future<void> _cancelScheduledNotification({
    required int id,
    required String debugLabel,
  }) async {
    final FlutterLocalNotificationsPlugin? plugin = _plugin;
    if (plugin == null) {
      _log('Plugin unavailable; cannot cancel $debugLabel notification.');
      return;
    }
    await plugin.cancel(id);
    _log('Canceled $debugLabel notification (id: $id).');
  }

  Future<bool> _ensurePermissions(FlutterLocalNotificationsPlugin plugin) async {
    if (_permissionsGranted) {
      return true;
    }
    _permissionsGranted = await _requestPermissions(plugin);
    return _permissionsGranted;
  }

  Future<bool> _requestPermissions(FlutterLocalNotificationsPlugin plugin) async {
    bool granted = true;

    if (!kIsWeb && Platform.isIOS) {
      final IOSFlutterLocalNotificationsPlugin? iosPlugin = plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      final bool iosGranted = await iosPlugin?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          true;
      granted = granted && iosGranted;
    }

    if (!kIsWeb && Platform.isMacOS) {
      final MacOSFlutterLocalNotificationsPlugin? macPlugin = plugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>();
      final bool macGranted = await macPlugin?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          true;
      granted = granted && macGranted;
    }

    if (!kIsWeb && Platform.isAndroid) {
      final PermissionStatus status = await Permission.notification.status;
      if (status.isGranted) {
        granted = granted && true;
      } else if (status.isPermanentlyDenied || status.isRestricted) {
        _log(
          'Android notification permission is ${status.name}; user must enable it in system settings.',
        );
        granted = false;
      } else {
        final PermissionStatus result = await Permission.notification.request();
        granted = granted && result.isGranted;
      }
    }

    if (!granted && !_permissionWarningLogged) {
      _log('Notification permissions denied.');
      _permissionWarningLogged = true;
    }

    return granted;
  }

  void _log(String message) {
    debugPrint('[NotificationService] $message');
  }

  bool get _areNotificationsEnabled {
    return _notificationsEnabledResolver?.call() ?? true;
  }
}
