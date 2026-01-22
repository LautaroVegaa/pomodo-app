import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class DailyStatRecord {
  const DailyStatRecord({required this.minutes, required this.sessions});

  static const DailyStatRecord empty = DailyStatRecord(minutes: 0, sessions: 0);

  final int minutes;
  final int sessions;

  DailyStatRecord copyWith({int? minutes, int? sessions}) {
    return DailyStatRecord(
      minutes: minutes ?? this.minutes,
      sessions: sessions ?? this.sessions,
    );
  }

  Map<String, dynamic> toJson() {
    return {'minutes': minutes, 'sessions': sessions};
  }

  factory DailyStatRecord.fromJson(Map<String, dynamic> json) {
    return DailyStatRecord(
      minutes: json['minutes'] is int ? json['minutes'] as int : 0,
      sessions: json['sessions'] is int ? json['sessions'] as int : 0,
    );
  }
}

class StatsStorage {
  static const String _dailyKey = 'study_stats_daily_records';

  Future<Map<String, DailyStatRecord>> loadDailyStats() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_dailyKey);
      if (raw == null || raw.isEmpty) {
        return <String, DailyStatRecord>{};
      }
      final Map<String, dynamic> decoded =
          jsonDecode(raw) as Map<String, dynamic>? ?? <String, dynamic>{};
      return decoded.map((key, value) {
        if (value is Map<String, dynamic>) {
          return MapEntry(key, DailyStatRecord.fromJson(value));
        }
        if (value is Map) {
          return MapEntry(
            key,
            DailyStatRecord.fromJson(Map<String, dynamic>.from(value)),
          );
        }
        return MapEntry(key, DailyStatRecord.empty);
      });
    } catch (_) {
      return <String, DailyStatRecord>{};
    }
  }

  Future<void> saveDailyStats(Map<String, DailyStatRecord> data) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final Map<String, Map<String, dynamic>> payload = data.map(
        (key, value) => MapEntry(key, value.toJson()),
      );
      await prefs.setString(_dailyKey, jsonEncode(payload));
    } catch (_) {
      // Persist errors are ignored to keep UX responsive.
    }
  }
}
