import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'stats_storage.dart';

class StatsController extends ChangeNotifier {
  StatsController({StatsStorage? storage, DateTime Function()? nowProvider})
      : _storage = storage ?? StatsStorage(),
        _nowProvider = nowProvider ?? DateTime.now;

  final StatsStorage _storage;
  final DateTime Function() _nowProvider;
  Future<void>? _initialization;
  Map<String, DailyStatRecord> _dailyRecords = <String, DailyStatRecord>{};
  int _streakDays = 0;
  String? _activeUserKey;
  String? _guestUserKey;
  final Map<String, int> _pendingFocusSeconds = <String, int>{};
  DateTime? _lastPersistTime;
  static const Duration _persistInterval = Duration(seconds: 30);

  @visibleForTesting
  String? get debugActiveUserKey => _activeUserKey;

  Future<void> initialize() {
    return _initialization ??= _initializeDefaultScope();
  }

  Future<void> _initializeDefaultScope() async {
    final String guestKey = await _ensureGuestKey();
    await _switchToUserKey(guestKey);
  }

  Future<void> applyUserScope({String? userUid}) async {
    await initialize();
    final String guestKey = await _ensureGuestKey();
    final String targetKey =
        userUid != null ? _storage.userKeyForUid(userUid) : guestKey;
    if (_activeUserKey == targetKey) {
      return;
    }
    await _persist();
    if (userUid != null) {
      await _mergeGuestIntoUserIfNeeded(
        guestKey: guestKey,
        userKey: targetKey,
      );
    }
    await _switchToUserKey(targetKey);
  }

  Future<void> _mergeGuestIntoUserIfNeeded({
    required String guestKey,
    required String userKey,
  }) async {
    final Map<String, DailyStatRecord> guestData =
        await _storage.loadDailyStats(guestKey);
    if (guestData.isEmpty) {
      return;
    }
    final Map<String, DailyStatRecord> userData =
        await _storage.loadDailyStats(userKey);
    if (userData.isNotEmpty) {
      return;
    }
    await _storage.saveDailyStats(userKey, guestData);
    final Map<String, int> guestPending =
        await _storage.loadPendingFocusSeconds(guestKey);
    if (guestPending.isNotEmpty) {
      await _storage.savePendingFocusSeconds(userKey, guestPending);
    }
  }

  Future<void> _switchToUserKey(String userKey) async {
    try {
      final Map<String, DailyStatRecord> loaded =
          await _storage.loadDailyStats(userKey);
      final Map<String, int> pending =
          await _storage.loadPendingFocusSeconds(userKey);
      _activeUserKey = userKey;
      _dailyRecords = Map<String, DailyStatRecord>.from(loaded);
      _pendingFocusSeconds
        ..clear()
        ..addAll(pending);
      _lastPersistTime = null;
      _recomputeStreak();
      notifyListeners();
    } catch (_) {
      // Keep previous data to avoid wiping stats if storage fails.
    }
  }

  Future<String> _ensureGuestKey() async {
    if (_guestUserKey != null) {
      return _guestUserKey!;
    }
    final String key = await _storage.resolveGuestUserKey();
    _guestUserKey = key;
    return key;
  }

  void recordFocusCompletion({
    required DateTime completionTime,
    required int focusMinutes,
    bool countSession = true,
    bool includeMinutes = true,
  }) {
    if (focusMinutes <= 0) {
      return;
    }
    if (_activeUserKey == null) {
      return;
    }
    final DateTime dateOnly = _dateOnly(completionTime);
    final String key = _keyForDate(dateOnly);
    final DailyStatRecord existing =
        _dailyRecords[key] ?? DailyStatRecord.empty;
    final DailyStatRecord updated = existing.copyWith(
      minutes: existing.minutes + (includeMinutes ? focusMinutes : 0),
      sessions: existing.sessions + (countSession ? 1 : 0),
    );
    _dailyRecords = Map<String, DailyStatRecord>.from(_dailyRecords)
      ..[key] = updated;
    _recomputeStreak();
    notifyListeners();
    unawaited(_persist());
  }

  void recordFocusElapsedSeconds(int deltaSeconds, {DateTime? referenceTime}) {
    if (deltaSeconds <= 0 || _activeUserKey == null) {
      return;
    }
    final DateTime timestamp = referenceTime ?? _nowProvider();
    final String key = _keyForDate(_dateOnly(timestamp));
    final int updatedSeconds = (_pendingFocusSeconds[key] ?? 0) + deltaSeconds;
    final int minutesToAdd = updatedSeconds ~/ 60;
    final int remainder = updatedSeconds % 60;
    if (minutesToAdd > 0) {
      if (remainder > 0) {
        _pendingFocusSeconds[key] = remainder;
      } else {
        _pendingFocusSeconds.remove(key);
      }
      final DailyStatRecord existing =
          _dailyRecords[key] ?? DailyStatRecord.empty;
      final DailyStatRecord updated = existing.copyWith(
        minutes: existing.minutes + minutesToAdd,
      );
      _dailyRecords = Map<String, DailyStatRecord>.from(_dailyRecords)
        ..[key] = updated;
      _recomputeStreak();
      notifyListeners();
    } else {
      if (updatedSeconds > 0) {
        _pendingFocusSeconds[key] = updatedSeconds;
      } else {
        _pendingFocusSeconds.remove(key);
      }
    }
    unawaited(_maybePersistElapsed(referenceTime: timestamp));
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
    final String? key = _activeUserKey;
    if (key == null) {
      return Future<void>.value();
    }
    return Future.wait<void>([
      _storage.saveDailyStats(key, _dailyRecords),
      _storage.savePendingFocusSeconds(key, _pendingFocusSeconds),
    ]);
  }

  @visibleForTesting
  Future<void> flushForTesting() => _persist();

  Future<void> flushElapsedFocus() {
    return _maybePersistElapsed(force: true);
  }

  Future<void> _maybePersistElapsed({bool force = false, DateTime? referenceTime}) {
    final DateTime now = referenceTime ?? _nowProvider();
    if (!force &&
        _lastPersistTime != null &&
        now.difference(_lastPersistTime!) < _persistInterval) {
      return Future<void>.value();
    }
    _lastPersistTime = now;
    return _persist();
  }
}
