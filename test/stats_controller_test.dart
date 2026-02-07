import 'package:flutter_test/flutter_test.dart';

import 'package:pomodo_app/features/stats/stats_controller.dart';
import 'package:pomodo_app/features/stats/stats_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('guest stats merge into first-time user accounts', () async {
    final _InMemoryStatsStorage storage = _InMemoryStatsStorage();
    final StatsController controller = StatsController(storage: storage);

    await controller.initialize();
    controller.recordFocusCompletion(
      completionTime: DateTime(2024, 1, 1, 9),
      focusMinutes: 30,
    );
    await controller.flushForTesting();

    await controller.applyUserScope(userUid: 'user-123');

    expect(controller.lifetimeMinutes, 30);
    final Map<String, DailyStatRecord> userData =
        await storage.loadDailyStats(storage.userKeyForUid('user-123'));
    expect(userData['2024-01-01']?.minutes, 30);
  });

  test('guest stats remain separate when user already has data', () async {
    final _InMemoryStatsStorage storage = _InMemoryStatsStorage();
    final StatsController controller = StatsController(storage: storage);

    await controller.initialize();
    controller.recordFocusCompletion(
      completionTime: DateTime(2024, 1, 2, 10),
      focusMinutes: 25,
    );
    await controller.flushForTesting();

    final String userKey = storage.userKeyForUid('user-existing');
    await storage.saveDailyStats(userKey, <String, DailyStatRecord>{
      '2024-01-05': const DailyStatRecord(minutes: 50, sessions: 2),
    });

    await controller.applyUserScope(userUid: 'user-existing');

    expect(controller.lifetimeMinutes, 50);
    expect(controller.lifetimeSessions, 2);

    final Map<String, DailyStatRecord> guestData =
        await storage.loadDailyStats(await storage.resolveGuestUserKey());
    expect(guestData['2024-01-02']?.minutes, 25);
  });

  test('switching between users keeps stats isolated', () async {
    final _InMemoryStatsStorage storage = _InMemoryStatsStorage();
    final StatsController controller = StatsController(storage: storage);

    await controller.initialize();

    await controller.applyUserScope(userUid: 'user-a');
    controller.recordFocusCompletion(
      completionTime: DateTime(2024, 1, 3, 8),
      focusMinutes: 40,
    );
    await controller.flushForTesting();

    await controller.applyUserScope(userUid: 'user-b');
    controller.recordFocusCompletion(
      completionTime: DateTime(2024, 1, 4, 8),
      focusMinutes: 10,
    );
    await controller.flushForTesting();

    await controller.applyUserScope(userUid: 'user-a');
    expect(controller.lifetimeMinutes, 40);
    expect(controller.lifetimeSessions, 1);

    await controller.applyUserScope(userUid: 'user-b');
    expect(controller.lifetimeMinutes, 10);
    expect(controller.lifetimeSessions, 1);
  });

  test('stats persist across controller restarts per user scope', () async {
    final _InMemoryStatsStorage storage = _InMemoryStatsStorage();
    final StatsController controller = StatsController(storage: storage);

    await controller.initialize();
    await controller.applyUserScope(userUid: 'user-persist');
    controller.recordFocusCompletion(
      completionTime: DateTime(2024, 1, 6, 7),
      focusMinutes: 35,
    );
    await controller.flushForTesting();

    final StatsController restored = StatsController(storage: storage);
    await restored.initialize();
    await restored.applyUserScope(userUid: 'user-persist');

    expect(restored.lifetimeMinutes, 35);
    expect(restored.lifetimeSessions, 1);
  });

  test('elapsed focus seconds accrue minutes without adding sessions', () async {
    final _InMemoryStatsStorage storage = _InMemoryStatsStorage();
    final DateTime base = DateTime(2024, 1, 10, 9);
    final StatsController controller = StatsController(
      storage: storage,
      nowProvider: () => base,
    );
    await controller.initialize();
    await controller.applyUserScope(userUid: 'user-elapsed');

    controller.recordFocusElapsedSeconds(30, referenceTime: base);
    expect(controller.lifetimeMinutes, 0);
    controller.recordFocusElapsedSeconds(
      30,
      referenceTime: base.add(const Duration(seconds: 30)),
    );
    expect(controller.lifetimeMinutes, 1);
    expect(controller.lifetimeSessions, 0);

    controller.recordFocusCompletion(
      completionTime: base.add(const Duration(minutes: 5)),
      focusMinutes: 5,
      includeMinutes: false,
    );
    expect(controller.lifetimeMinutes, 1);
    expect(controller.lifetimeSessions, 1);
  });

  test('persistence is throttled while session runs', () async {
    final _InMemoryStatsStorage storage = _InMemoryStatsStorage();
    DateTime clock = DateTime(2024, 1, 11, 9);
    final StatsController controller = StatsController(
      storage: storage,
      nowProvider: () => clock,
    );
    await controller.initialize();
    await controller.applyUserScope(userUid: 'user-throttle');
    final int baselineSaves = storage.dailySaveCalls;

    controller.recordFocusElapsedSeconds(60, referenceTime: clock);
    await Future<void>.delayed(Duration.zero);
    expect(storage.dailySaveCalls, baselineSaves + 1);

    clock = clock.add(const Duration(seconds: 10));
    controller.recordFocusElapsedSeconds(60, referenceTime: clock);
    await Future<void>.delayed(Duration.zero);
    expect(storage.dailySaveCalls, baselineSaves + 1);

    clock = clock.add(const Duration(seconds: 40));
    controller.recordFocusElapsedSeconds(60, referenceTime: clock);
    await Future<void>.delayed(Duration.zero);
    expect(storage.dailySaveCalls, baselineSaves + 2);
  });
}

class _InMemoryStatsStorage extends StatsStorage {
  final Map<String, Map<String, DailyStatRecord>> _records = <String, Map<String, DailyStatRecord>>{};
  final Map<String, Map<String, int>> _pending = <String, Map<String, int>>{};
  String guestKey = 'guest:test';
  int dailySaveCalls = 0;

  @override
  Future<Map<String, DailyStatRecord>> loadDailyStats(String userKey) async {
    return Map<String, DailyStatRecord>.from(_records[userKey] ?? <String, DailyStatRecord>{});
  }

  @override
  Future<void> saveDailyStats(String userKey, Map<String, DailyStatRecord> data) async {
    dailySaveCalls += 1;
    _records[userKey] = Map<String, DailyStatRecord>.from(data);
  }

  @override
  Future<String> resolveGuestUserKey() async => guestKey;

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
