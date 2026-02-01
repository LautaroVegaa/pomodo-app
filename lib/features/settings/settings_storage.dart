import 'package:shared_preferences/shared_preferences.dart';

class ExperienceSettings {
  const ExperienceSettings({
    required this.hapticsEnabled,
    required this.soundsEnabled,
    required this.notificationsEnabled,
  });

  static const ExperienceSettings defaults = ExperienceSettings(
    hapticsEnabled: true,
    soundsEnabled: false,
    notificationsEnabled: true,
  );

  final bool hapticsEnabled;
  final bool soundsEnabled;
  final bool notificationsEnabled;

  ExperienceSettings copyWith({
    bool? hapticsEnabled,
    bool? soundsEnabled,
    bool? notificationsEnabled,
  }) {
    return ExperienceSettings(
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      soundsEnabled: soundsEnabled ?? this.soundsEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}

class SettingsStorage {
  static const String _hapticsKey = 'experience_haptics_enabled';
  static const String _soundsKey = 'experience_sounds_enabled';
  static const String _notificationsKey = 'experience_notifications_enabled';

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
    } catch (_) {
      // Persist errors are ignored to keep UX responsive.
    }
  }
}
