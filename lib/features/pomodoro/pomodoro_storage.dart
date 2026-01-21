import 'package:shared_preferences/shared_preferences.dart';

class PomodoroConfig {
  const PomodoroConfig({
    required this.focusMinutes,
    required this.breakMinutes,
    required this.longBreakMinutes,
    required this.longBreakEveryCycles,
  });

  static const PomodoroConfig defaults = PomodoroConfig(
    focusMinutes: 25,
    breakMinutes: 5,
    longBreakMinutes: 15,
    longBreakEveryCycles: 4,
  );

  final int focusMinutes;
  final int breakMinutes;
  final int longBreakMinutes;
  final int longBreakEveryCycles;

  PomodoroConfig copyWith({
    int? focusMinutes,
    int? breakMinutes,
    int? longBreakMinutes,
    int? longBreakEveryCycles,
  }) {
    return PomodoroConfig(
      focusMinutes: focusMinutes ?? this.focusMinutes,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      longBreakEveryCycles:
          longBreakEveryCycles ?? this.longBreakEveryCycles,
    );
  }
}

class PomodoroStorage {
  static const String _focusKey = 'focus_minutes';
  static const String _breakKey = 'break_minutes';
  static const String _longBreakKey = 'long_break_minutes';
  static const String _longBreakEveryKey = 'long_break_every_cycles';

  Future<PomodoroConfig> loadConfig() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return PomodoroConfig(
        focusMinutes:
            prefs.getInt(_focusKey) ?? PomodoroConfig.defaults.focusMinutes,
        breakMinutes:
            prefs.getInt(_breakKey) ?? PomodoroConfig.defaults.breakMinutes,
        longBreakMinutes:
            prefs.getInt(_longBreakKey) ?? PomodoroConfig.defaults.longBreakMinutes,
        longBreakEveryCycles: prefs.getInt(_longBreakEveryKey) ??
            PomodoroConfig.defaults.longBreakEveryCycles,
      );
    } catch (_) {
      return PomodoroConfig.defaults;
    }
  }

  Future<void> saveConfig(PomodoroConfig config) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_focusKey, config.focusMinutes);
      await prefs.setInt(_breakKey, config.breakMinutes);
      await prefs.setInt(_longBreakKey, config.longBreakMinutes);
      await prefs.setInt(_longBreakEveryKey, config.longBreakEveryCycles);
    } catch (_) {
      // Ignore persistence failures.
    }
  }
}
