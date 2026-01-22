import 'dart:async';

import 'package:flutter/material.dart';

import '../features/onboarding/editorial_onboarding_page.dart';
import '../features/settings/settings_controller.dart';
import '../features/stats/stats_controller.dart';
import 'app_theme.dart';
import 'pomodoro_scope.dart';
import 'settings_scope.dart';
import 'stats_scope.dart';

class PomodoApp extends StatefulWidget {
  const PomodoApp({super.key});

  @override
  State<PomodoApp> createState() => _PomodoAppState();
}

class _PomodoAppState extends State<PomodoApp> {
  late final SettingsController _settingsController;
  late final StatsController _statsController;

  @override
  void initState() {
    super.initState();
    _settingsController = SettingsController();
    unawaited(_settingsController.initialize());
    _statsController = StatsController();
    unawaited(_statsController.initialize());
  }

  @override
  void dispose() {
    _statsController.dispose();
    _settingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StatsScope(
      controller: _statsController,
      child: SettingsScope(
        controller: _settingsController,
        child: PomodoroScope(
          settingsController: _settingsController,
          statsController: _statsController,
          child: MaterialApp(
            title: 'Pomodo',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: const EditorialOnboardingPage(),
          ),
        ),
      ),
    );
  }
}
