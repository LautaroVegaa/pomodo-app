import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/notification_service.dart';
import 'settings_storage.dart';

class SettingsController extends ChangeNotifier {
  SettingsController({
    SettingsStorage? storage,
    NotificationService? notificationService,
  })  : _storage = storage ?? SettingsStorage(),
        _notificationService = notificationService;

  final SettingsStorage _storage;
  Future<void>? _initialization;
  final NotificationService? _notificationService;

  bool _hapticsEnabled = ExperienceSettings.defaults.hapticsEnabled;
  bool _soundsEnabled = ExperienceSettings.defaults.soundsEnabled;
  bool _notificationsEnabled = ExperienceSettings.defaults.notificationsEnabled;
  bool _flowFocusLandscapeEnabled =
      ExperienceSettings.defaults.flowFocusLandscapeEnabled;

  bool get hapticsEnabled => _hapticsEnabled;
  bool get soundsEnabled => _soundsEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get flowFocusLandscapeEnabled => _flowFocusLandscapeEnabled;

  Future<void> initialize() {
    return _initialization ??= _loadExperience();
  }

  Future<void> _loadExperience() async {
    try {
      final ExperienceSettings settings = await _storage.loadExperience();
      _hapticsEnabled = settings.hapticsEnabled;
      _soundsEnabled = settings.soundsEnabled;
      _notificationsEnabled = settings.notificationsEnabled;
      _flowFocusLandscapeEnabled = settings.flowFocusLandscapeEnabled;
      notifyListeners();
      if (_notificationsEnabled) {
        unawaited(_verifyNotificationPermissions());
      }
    } catch (_) {
      // Ignore load failures and keep defaults.
    }
  }

  void setHapticsEnabled(bool value) {
    if (_hapticsEnabled == value) return;
    _hapticsEnabled = value;
    notifyListeners();
    unawaited(_persist());
  }

  void setSoundsEnabled(bool value) {
    if (_soundsEnabled == value) return;
    _soundsEnabled = value;
    notifyListeners();
    unawaited(_persist());
  }

  void setNotificationsEnabled(bool value) {
    if (_notificationsEnabled == value) return;
    _notificationsEnabled = value;
    notifyListeners();
    if (!value) {
      _cancelScheduledNotifications();
    } else {
      unawaited(_verifyNotificationPermissions());
    }
    unawaited(_persist());
  }

  void setFlowFocusLandscapeEnabled(bool value) {
    if (_flowFocusLandscapeEnabled == value) {
      return;
    }
    _flowFocusLandscapeEnabled = value;
    notifyListeners();
    unawaited(_persist());
  }

  Future<void> _persist() {
    return _storage.saveExperience(
      ExperienceSettings(
        hapticsEnabled: _hapticsEnabled,
        soundsEnabled: _soundsEnabled,
        notificationsEnabled: _notificationsEnabled,
        flowFocusLandscapeEnabled: _flowFocusLandscapeEnabled,
      ),
    );
  }

  Future<void> _verifyNotificationPermissions() async {
    final bool granted =
        await (_notificationService?.ensurePermissionsGranted() ?? Future.value(true));
    if (!granted && _notificationsEnabled) {
      _notificationsEnabled = false;
      notifyListeners();
      _cancelScheduledNotifications();
      await _persist();
    }
  }

  void _cancelScheduledNotifications() {
    final Future<void>? cancelFuture =
        _notificationService?.cancelAllNotifications();
    if (cancelFuture != null) {
      unawaited(cancelFuture);
    }
  }
}
