import 'dart:async';

import 'package:flutter/material.dart';

import 'settings_storage.dart';

class SettingsController extends ChangeNotifier {
  SettingsController({SettingsStorage? storage})
      : _storage = storage ?? SettingsStorage();

  final SettingsStorage _storage;
  Future<void>? _initialization;

  bool _hapticsEnabled = ExperienceSettings.defaults.hapticsEnabled;
  bool _soundsEnabled = ExperienceSettings.defaults.soundsEnabled;

  bool get hapticsEnabled => _hapticsEnabled;
  bool get soundsEnabled => _soundsEnabled;

  Future<void> initialize() {
    return _initialization ??= _loadExperience();
  }

  Future<void> _loadExperience() async {
    try {
      final ExperienceSettings settings = await _storage.loadExperience();
      _hapticsEnabled = settings.hapticsEnabled;
      _soundsEnabled = settings.soundsEnabled;
      notifyListeners();
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

  Future<void> _persist() {
    return _storage.saveExperience(
      ExperienceSettings(
        hapticsEnabled: _hapticsEnabled,
        soundsEnabled: _soundsEnabled,
      ),
    );
  }
}
