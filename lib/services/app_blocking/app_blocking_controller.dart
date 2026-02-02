import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum AppBlockingMode {
  recommended,
  custom;

  static AppBlockingMode fromString(String? value) {
    final String normalized = value?.toLowerCase().trim() ?? '';
    switch (normalized) {
      case 'recommended':
        return AppBlockingMode.recommended;
      case 'custom':
        return AppBlockingMode.custom;
      case 'pomodoro':
      case 'timer':
      case 'stopwatch':
        return AppBlockingMode.recommended;
      default:
        return AppBlockingMode.recommended;
    }
  }

  String toWire() => name;
}

extension AppBlockingModeLabel on AppBlockingMode {
  String get label => switch (this) {
        AppBlockingMode.recommended => 'Recommended',
        AppBlockingMode.custom => 'Custom',
      };
}

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

  final MethodChannel _channel;
  final TargetPlatform? _debugPlatformOverride;

  Future<void>? _initialization;
  bool _authorized = false;
  bool _isBusy = false;
  AppBlockingMode _mode = AppBlockingMode.recommended;
  AppSelectionSummary _recommendedSummary = const AppSelectionSummary();
  AppSelectionSummary _customSummary = const AppSelectionSummary();

  bool get isAuthorized => _authorized;
  AppBlockingMode get mode => _mode;
  bool get isBusy => _isBusy;
  bool get isSupported => _isIosTarget;
  bool get hasActiveSelection => _activeSummary.hasSelection;
  bool get requiresAuthorization => _isIosTarget && !_authorized;
  AppSelectionSummary get recommendedSummary => _recommendedSummary;
  AppSelectionSummary get customSummary => _customSummary;

  AppSelectionSummary get _activeSummary =>
      _mode == AppBlockingMode.recommended ? _recommendedSummary : _customSummary;

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
    if (!_isIosTarget) {
      return;
    }
    await _invokeSafely<void>('clearAllOnStartup');
    await refreshState();
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

  Future<void> setMode(AppBlockingMode mode) async {
    if (_mode == mode) {
      return;
    }
    _mode = mode;
    notifyListeners();
    if (!_isIosTarget) {
      return;
    }
    await _invokeSafely<void>('setBlockingMode', {'mode': mode.toWire()});
  }

  Future<void> presentPicker() async {
    if (!_isIosTarget || !_authorized) {
      return;
    }
    await _withBusy(() async {
        final Map<dynamic, dynamic>? payload = await _invokeSafely<Map<dynamic, dynamic>>(
          'presentPicker',
          {
            'mode': _mode.toWire(),
            'prefillRecommended': _mode == AppBlockingMode.recommended,
          },
        );
      if (payload != null) {
        _applySummaryPayload(payload);
        notifyListeners();
      }
    });
  }

  Future<bool> applyActiveSelection() async {
    if (!_isIosTarget) {
      return false;
    }
    if (!_authorized || !hasActiveSelection) {
      await clearBlock();
      return false;
    }
    final bool applied = await _invokeSafely<bool>(
      'applyBlock',
      {'mode': _mode.toWire()},
        ) ??
        false;
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
      _recommendedSummary = const AppSelectionSummary();
      _customSummary = const AppSelectionSummary();
      _mode = AppBlockingMode.recommended;
      return;
    }
    _recommendedSummary =
      AppSelectionSummary.fromMap(payload['recommended'] as Map<dynamic, dynamic>?);
    _customSummary = AppSelectionSummary.fromMap(payload['custom'] as Map<dynamic, dynamic>?);
    _mode = AppBlockingMode.fromString(payload['mode'] as String?);
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
