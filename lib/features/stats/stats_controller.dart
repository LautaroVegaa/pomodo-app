import 'dart:async';

import 'package:flutter/material.dart';

import 'stats_storage.dart';

class StatsController extends ChangeNotifier {
  StatsController({StatsStorage? storage})
      : _storage = storage ?? StatsStorage();

  final StatsStorage _storage;
  Future<void>? _initialization;
  Map<String, DailyStatRecord> _dailyRecords = <String, DailyStatRecord>{};
  int _streakDays = 0;

  Future<void> initialize() {
    return _initialization ??= _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final Map<String, DailyStatRecord> loaded =
          await _storage.loadDailyStats();
      if (_dailyRecords.isEmpty) {
        _dailyRecords = Map<String, DailyStatRecord>.from(loaded);
      } else {
        final Map<String, DailyStatRecord> pending =
            Map<String, DailyStatRecord>.from(_dailyRecords);
        _dailyRecords = Map<String, DailyStatRecord>.from(loaded)
          ..addAll(pending);
      }
      _recomputeStreak();
      notifyListeners();
    } catch (_) {
      // Keep defaults when load fails.
    }
  }

  void recordFocusCompletion({
    required DateTime completionTime,
    required int focusMinutes,
  }) {
    if (focusMinutes <= 0) {
      return;
    }
    final DateTime dateOnly = _dateOnly(completionTime);
    final String key = _keyForDate(dateOnly);
    final DailyStatRecord existing =
        _dailyRecords[key] ?? DailyStatRecord.empty;
    final DailyStatRecord updated = existing.copyWith(
      minutes: existing.minutes + focusMinutes,
      sessions: existing.sessions + 1,
    );
    _dailyRecords = Map<String, DailyStatRecord>.from(_dailyRecords)
      ..[key] = updated;
    _recomputeStreak();
    notifyListeners();
    unawaited(_persist());
  }

  int get todayFocusMinutes => _minutesForDate(DateTime.now());
  int get todaySessions => _sessionsForDate(DateTime.now());
  int get weeklyFocusMinutes => _sumForLastDays(7);
  int get monthlyFocusMinutes => _sumForCurrentMonth();
  int get lifetimeMinutes => _dailyRecords.values.fold(0, (sum, record) => sum + record.minutes);
  int get lifetimeSessions => _dailyRecords.values.fold(0, (sum, record) => sum + record.sessions);
  int get streakDays => _streakDays;

  int get averageSessionMinutes {
    final int sessions = lifetimeSessions;
    if (sessions == 0) return 0;
    return (lifetimeMinutes / sessions).round();
  }

  int _minutesForDate(DateTime date) {
    final String key = _keyForDate(_dateOnly(date));
    return _dailyRecords[key]?.minutes ?? 0;
  }

  int _sessionsForDate(DateTime date) {
    final String key = _keyForDate(_dateOnly(date));
    return _dailyRecords[key]?.sessions ?? 0;
  }

  int _sumForLastDays(int days) {
    final DateTime today = _dateOnly(DateTime.now());
    int total = 0;
    for (int offset = 0; offset < days; offset += 1) {
      final DateTime cursor = today.subtract(Duration(days: offset));
      total += _minutesForDate(cursor);
    }
    return total;
  }

  int _sumForCurrentMonth() {
    final DateTime today = _dateOnly(DateTime.now());
    final DateTime startOfMonth = DateTime(today.year, today.month, 1);
    int total = 0;
    DateTime cursor = startOfMonth;
    while (!cursor.isAfter(today) && cursor.month == startOfMonth.month) {
      total += _minutesForDate(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }
    return total;
  }

  void _recomputeStreak() {
    final DateTime today = _dateOnly(DateTime.now());
    int streak = 0;
    DateTime cursor = today;
    while (true) {
      final int minutes = _minutesForDate(cursor);
      if (minutes <= 0) {
        break;
      }
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    _streakDays = streak;
  }

  DateTime _dateOnly(DateTime source) {
    return DateTime(source.year, source.month, source.day);
  }

  String _keyForDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _persist() {
    return _storage.saveDailyStats(_dailyRecords);
  }
}
