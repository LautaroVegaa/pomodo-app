import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';

/// Shared blur used by Pomodoro, Timer, and Stopwatch cards.
List<BoxShadow> buildPrimaryCardBlur() {
  return [
    BoxShadow(
      color: AppColors.accentBlue.withValues(alpha: 0.22),
      blurRadius: 40,
      spreadRadius: 2,
      offset: const Offset(0, 18),
    ),
  ];
}
