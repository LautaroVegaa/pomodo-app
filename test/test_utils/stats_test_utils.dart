import 'package:fake_async/fake_async.dart';

import 'package:pomodo_app/features/stats/stats_storage.dart';

class InMemoryStatsStorage extends StatsStorage {
  final Map<String, Map<String, DailyStatRecord>> _records = <String, Map<String, DailyStatRecord>>{};
  final Map<String, Map<String, int>> _pending = <String, Map<String, int>>{};

  @override
  Future<Map<String, DailyStatRecord>> loadDailyStats(String userKey) async {
    return Map<String, DailyStatRecord>.from(_records[userKey] ?? <String, DailyStatRecord>{});
  }

  @override
  Future<void> saveDailyStats(String userKey, Map<String, DailyStatRecord> data) async {
    _records[userKey] = Map<String, DailyStatRecord>.from(data);
  }

  @override
  Future<String> resolveGuestUserKey() async => 'guest:test';

  @override
  Future<Map<String, int>> loadPendingFocusSeconds(String userKey) async {
    return Map<String, int>.from(_pending[userKey] ?? <String, int>{});
  }

  @override
  Future<void> savePendingFocusSeconds(String userKey, Map<String, int> pending) async {
    if (pending.isEmpty) {
      _pending.remove(userKey);
      return;
    }
    _pending[userKey] = Map<String, int>.from(pending);
  }
}

class TestClock {
  TestClock({DateTime? initial}) : _current = initial ?? DateTime(2024, 1, 1);

  DateTime _current;

  DateTime now() => _current;

  void advance(FakeAsync async, Duration delta) {
    final int wholeSeconds = delta.inSeconds;
    for (int i = 0; i < wholeSeconds; i += 1) {
      _step(async, const Duration(seconds: 1));
    }
    final Duration remainder = delta - Duration(seconds: wholeSeconds);
    if (remainder > Duration.zero) {
      _step(async, remainder);
    }
  }

  void _step(FakeAsync async, Duration step) {
    _current = _current.add(step);
    async.elapse(step);
  }
}
