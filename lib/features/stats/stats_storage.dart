import 'dart:convert';
import 'dart:math';

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
  static const String _dailyKeyPrefix = 'study_stats_daily_records__';
  static const String _legacyDailyKey = 'study_stats_daily_records';
  static const String _installIdKey = 'study_stats_install_id';
  static const String _guestKeyPrefix = 'guest:';
  static const String _userKeyPrefix = 'user:';
  static const String _pendingKeyPrefix = 'study_stats_pending_focus__';

  Future<Map<String, DailyStatRecord>> loadDailyStats(String userKey) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String? raw = prefs.getString(_scopedKey(userKey));
      if (raw == null && userKey.startsWith(_guestKeyPrefix)) {
        raw = prefs.getString(_legacyDailyKey);
        if (raw != null) {
          await prefs.setString(_scopedKey(userKey), raw);
          await prefs.remove(_legacyDailyKey);
        }
      }
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

  Future<void> saveDailyStats(String userKey, Map<String, DailyStatRecord> data) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final Map<String, Map<String, dynamic>> payload = data.map(
        (key, value) => MapEntry(key, value.toJson()),
      );
      await prefs.setString(_scopedKey(userKey), jsonEncode(payload));
    } catch (_) {
      // Persist errors are ignored to keep UX responsive.
    }
  }

  Future<Map<String, int>> loadPendingFocusSeconds(String userKey) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_pendingKey(userKey));
      if (raw == null || raw.isEmpty) {
        return <String, int>{};
      }
      final Map<String, dynamic> decoded =
          jsonDecode(raw) as Map<String, dynamic>? ?? <String, dynamic>{};
      return decoded.map((key, value) {
        if (value is int) {
          return MapEntry(key, value.clamp(0, 59));
        }
        if (value is num) {
          return MapEntry(key, value.toInt().clamp(0, 59));
        }
        return MapEntry(key, 0);
      }).map((key, value) => MapEntry(key, value.toInt()))
        ..removeWhere((_, seconds) => seconds <= 0);
    } catch (_) {
      return <String, int>{};
    }
  }

  Future<void> savePendingFocusSeconds(String userKey, Map<String, int> pending) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (pending.isEmpty) {
        await prefs.remove(_pendingKey(userKey));
        return;
      }
      final Map<String, int> sanitized = pending.map(
        (key, value) => MapEntry(key, value.clamp(0, 59).toInt()),
      );
      await prefs.setString(_pendingKey(userKey), jsonEncode(sanitized));
    } catch (_) {
      // Ignore persistence errors for pending seconds as well.
    }
  }

  Future<String> resolveGuestUserKey() async {
    final String installId = await _ensureInstallId();
    return '$_guestKeyPrefix$installId';
  }

  String userKeyForUid(String uid) => '$_userKeyPrefix$uid';

  Future<String> _ensureInstallId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? existing = prefs.getString(_installIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final String generated = _generateInstallId();
    await prefs.setString(_installIdKey, generated);
    return generated;
  }

  String _generateInstallId() {
    const String alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final Random random = Random();
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < 24; i += 1) {
      buffer.write(alphabet[random.nextInt(alphabet.length)]);
    }
    return buffer.toString();
  }

  String _scopedKey(String userKey) => '$_dailyKeyPrefix$userKey';

  String _pendingKey(String userKey) => '$_pendingKeyPrefix$userKey';
}
