import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSelectionSummary {
  const AppSelectionSummary({this.applications = 0, this.categories = 0});

  final int applications;
  final int categories;

  bool get hasSelection => applications > 0 || categories > 0;

  AppSelectionSummary copyWith({int? applications, int? categories}) {
    return AppSelectionSummary(
      applications: applications ?? this.applications,
      categories: categories ?? this.categories,
    );
  }

  factory AppSelectionSummary.fromMap(Map<dynamic, dynamic>? data) {
    if (data == null) {
      return const AppSelectionSummary();
    }
    return AppSelectionSummary(
      applications: (data['applications'] as num?)?.toInt() ?? 0,
      categories: (data['categories'] as num?)?.toInt() ?? 0,
    );
  }
}

class AppBlockingController extends ChangeNotifier {
  AppBlockingController({MethodChannel? channel, TargetPlatform? debugPlatformOverride})
      : _channel = channel ?? const MethodChannel(_channelName),
        _debugPlatformOverride = debugPlatformOverride;

  static const String _channelName = 'pomodo/app_blocking';
  static const String _guidanceSeenKey = 'app_blocking_guidance_seen';

  final MethodChannel _channel;
  final TargetPlatform? _debugPlatformOverride;

  Future<void>? _initialization;
  bool _authorized = false;
  bool _isBusy = false;
  AppSelectionSummary _selectionSummary = const AppSelectionSummary();
  bool _hasSeenGuidance = false;
  Future<void>? _guidanceLoad;

  bool get isAuthorized => _authorized;
  bool get isBusy => _isBusy;
  bool get isSupported => _isIosTarget;
  bool get hasActiveSelection => _selectionSummary.hasSelection;
  bool get requiresAuthorization => _isIosTarget && !_authorized;
  AppSelectionSummary get selectionSummary => _selectionSummary;
  bool get hasSeenGuidance => _hasSeenGuidance;

  bool get _isIosTarget {
    if (kIsWeb) return false;
    if (_debugPlatformOverride != null) {
      return _debugPlatformOverride == TargetPlatform.iOS;
    }
    return defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> initialize() {
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    await ensureGuidanceStateLoaded();
    if (!_isIosTarget) {
      return;
    }
    await _invokeSafely<void>('clearAllOnStartup');
    await refreshState();
  }

  Future<void> ensureGuidanceStateLoaded() {
    return _guidanceLoad ??= _loadGuidanceState();
  }

  Future<void> _loadGuidanceState() async {
    bool seen = false;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      seen = prefs.getBool(_guidanceSeenKey) ?? false;
    } catch (_) {
      seen = false;
    }
    if (_hasSeenGuidance != seen) {
      _hasSeenGuidance = seen;
      notifyListeners();
    } else {
      _hasSeenGuidance = seen;
    }
  }

  Future<void> refreshState() async {
    if (!_isIosTarget) {
      return;
    }
    final bool authorized = await _invokeSafely<bool>('getAuthorizationStatus') ?? false;
    final Map<dynamic, dynamic>? payload =
        await _invokeSafely<Map<dynamic, dynamic>>('getSelectionSummary');
    _authorized = authorized;
    _applySummaryPayload(payload);
    notifyListeners();
  }

  Future<void> requestAuthorization() async {
    if (!_isIosTarget) {
      return;
    }
    await _withBusy(() async {
      final bool granted = await _invokeSafely<bool>('requestAuthorization') ?? false;
      if (granted) {
        _authorized = true;
      }
      await refreshState();
    });
  }

  Future<void> presentPicker() async {
    if (!_isIosTarget || !_authorized) {
      return;
    }
    await _withBusy(() async {
      final Map<dynamic, dynamic>? payload =
          await _invokeSafely<Map<dynamic, dynamic>>('presentPicker');
      if (payload != null) {
        _applySummaryPayload(payload);
        notifyListeners();
      }
    });
  }

  Future<void> markGuidanceSeen() async {
    if (_hasSeenGuidance) {
      return;
    }
    _hasSeenGuidance = true;
    notifyListeners();
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_guidanceSeenKey, true);
    } catch (_) {
      // Ignore persistence failures; guidance will reappear if needed.
    }
  }

  Future<bool> applyActiveSelection() async {
    if (!_isIosTarget) {
      return false;
    }
    if (!_authorized || !hasActiveSelection) {
      await clearBlock();
      return false;
    }
    final bool applied = await _invokeSafely<bool>('applyBlock') ?? false;
    if (!applied) {
      await clearBlock();
    }
    return applied;
  }

  Future<void> clearBlock() {
    if (!_isIosTarget) {
      return Future.value();
    }
    return _invokeSafely<void>('clearBlock');
  }

  Future<T?> _invokeSafely<T>(String method, [Map<String, dynamic>? arguments]) async {
    if (!_isIosTarget) {
      return null;
    }
    try {
      final T? result = await _channel.invokeMethod<T>(method, arguments);
      return result;
    } catch (error) {
      debugPrint('[AppBlockingController] $method failed: $error');
      return null;
    }
  }

  void _applySummaryPayload(Map<dynamic, dynamic>? payload) {
    if (payload == null) {
      _selectionSummary = const AppSelectionSummary();
      return;
    }
    final Map<dynamic, dynamic>? summaryMap =
        (payload['custom'] as Map<dynamic, dynamic>?) ??
        (payload['selection'] as Map<dynamic, dynamic>?);
    _selectionSummary = AppSelectionSummary.fromMap(summaryMap);
  }

  Future<void> _withBusy(Future<void> Function() operation) async {
    if (_isBusy) {
      return;
    }
    _isBusy = true;
    notifyListeners();
    try {
      await operation();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }
}
