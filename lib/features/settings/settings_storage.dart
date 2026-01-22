import 'package:shared_preferences/shared_preferences.dart';

class ExperienceSettings {
  const ExperienceSettings({
    required this.hapticsEnabled,
    required this.soundsEnabled,
  });

  static const ExperienceSettings defaults = ExperienceSettings(
    hapticsEnabled: true,
    soundsEnabled: false,
  );

  final bool hapticsEnabled;
  final bool soundsEnabled;

  ExperienceSettings copyWith({
    bool? hapticsEnabled,
    bool? soundsEnabled,
  }) {
    return ExperienceSettings(
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      soundsEnabled: soundsEnabled ?? this.soundsEnabled,
    );
  }
}

class SettingsStorage {
  static const String _hapticsKey = 'experience_haptics_enabled';
  static const String _soundsKey = 'experience_sounds_enabled';

  Future<ExperienceSettings> loadExperience() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return ExperienceSettings(
        hapticsEnabled:
            prefs.getBool(_hapticsKey) ?? ExperienceSettings.defaults.hapticsEnabled,
        soundsEnabled:
            prefs.getBool(_soundsKey) ?? ExperienceSettings.defaults.soundsEnabled,
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
    } catch (_) {
      // Persist errors are ignored to keep UX responsive.
    }
  }
}
