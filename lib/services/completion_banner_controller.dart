import 'dart:async';

import 'package:flutter/foundation.dart';

enum CompletionBannerType {
  focus,
  breakSession,
  longBreak,
  timer,
}

class CompletionBannerData {
  const CompletionBannerData({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}

class CompletionBannerController extends ChangeNotifier {
  CompletionBannerController();

  static const Duration _displayDuration = Duration(milliseconds: 2500);
  static const Duration animationDuration = Duration(milliseconds: 260);

  CompletionBannerData? _data;
  bool _visible = false;
  Timer? _hideTimer;

  CompletionBannerData? get data => _data;
  bool get isVisible => _visible && _data != null;

  void show(CompletionBannerType type) {
    _data = _dataFor(type);
    _visible = true;
    notifyListeners();
    _hideTimer?.cancel();
    _hideTimer = Timer(_displayDuration, () {
      _visible = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  CompletionBannerData? _dataFor(CompletionBannerType type) {
    switch (type) {
      case CompletionBannerType.focus:
        return const CompletionBannerData(
          title: 'Focus complete',
          subtitle: 'Time for a break.',
        );
      case CompletionBannerType.breakSession:
        return const CompletionBannerData(
          title: 'Break complete',
          subtitle: 'Back to focus.',
        );
      case CompletionBannerType.longBreak:
        return const CompletionBannerData(
          title: 'Long break complete',
          subtitle: 'Back to focus.',
        );
      case CompletionBannerType.timer:
        return const CompletionBannerData(
          title: 'Timer complete',
          subtitle: "Time's up.",
        );
    }
  }
}
