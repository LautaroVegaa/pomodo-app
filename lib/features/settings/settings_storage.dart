import 'package:shared_preferences/shared_preferences.dart';

class ExperienceSettings {
  const ExperienceSettings({
    required this.hapticsEnabled,
    required this.soundsEnabled,
    required this.notificationsEnabled,
    required this.flowFocusLandscapeEnabled,
    required this.pomodoroAutoStartEnabled,
  });

  static const ExperienceSettings defaults = ExperienceSettings(
    hapticsEnabled: true,
    soundsEnabled: false,
    notificationsEnabled: true,
    flowFocusLandscapeEnabled: true,
    pomodoroAutoStartEnabled: true,
  );

  final bool hapticsEnabled;
  final bool soundsEnabled;
  final bool notificationsEnabled;
  final bool flowFocusLandscapeEnabled;
  final bool pomodoroAutoStartEnabled;

  ExperienceSettings copyWith({
    bool? hapticsEnabled,
    bool? soundsEnabled,
    bool? notificationsEnabled,
    bool? flowFocusLandscapeEnabled,
    bool? pomodoroAutoStartEnabled,
  }) {
    return ExperienceSettings(
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      soundsEnabled: soundsEnabled ?? this.soundsEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      flowFocusLandscapeEnabled:
          flowFocusLandscapeEnabled ?? this.flowFocusLandscapeEnabled,
      pomodoroAutoStartEnabled:
          pomodoroAutoStartEnabled ?? this.pomodoroAutoStartEnabled,
    );
  }
}

class SettingsStorage {
  static const String _hapticsKey = 'experience_haptics_enabled';
  static const String _soundsKey = 'experience_sounds_enabled';
  static const String _notificationsKey = 'experience_notifications_enabled';
  static const String _flowFocusKey = 'experience_flow_focus_landscape_enabled';
  static const String _pomodoroAutoStartKey =
      'experience_pomodoro_auto_start_enabled';

  Future<ExperienceSettings> loadExperience() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return ExperienceSettings(
        hapticsEnabled:
            prefs.getBool(_hapticsKey) ?? ExperienceSettings.defaults.hapticsEnabled,
        soundsEnabled:
            prefs.getBool(_soundsKey) ?? ExperienceSettings.defaults.soundsEnabled,
        notificationsEnabled:
            prefs.getBool(_notificationsKey) ??
            ExperienceSettings.defaults.notificationsEnabled,
        flowFocusLandscapeEnabled:
            prefs.getBool(_flowFocusKey) ??
            ExperienceSettings.defaults.flowFocusLandscapeEnabled,
        pomodoroAutoStartEnabled:
            prefs.getBool(_pomodoroAutoStartKey) ??
            ExperienceSettings.defaults.pomodoroAutoStartEnabled,
      );
    } catch (_) {
      return ExperienceSettings.defaults;
    }
  }

  Future<void> saveExperience(ExperienceSettings settings) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hapticsKey, settings.hapticsEnabled);
      await prefs.setBool(_soundsKey, settings.soundsEnabled);
      await prefs.setBool(_notificationsKey, settings.notificationsEnabled);
      await prefs.setBool(_flowFocusKey, settings.flowFocusLandscapeEnabled);
      await prefs.setBool(_pomodoroAutoStartKey, settings.pomodoroAutoStartEnabled);
    } catch (_) {
      // Persist errors are ignored to keep UX responsive.
    }
  }
}
