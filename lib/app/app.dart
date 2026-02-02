import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../features/onboarding/editorial_onboarding_page.dart';
import '../features/settings/settings_controller.dart';
import '../features/stats/stats_controller.dart';
import '../services/app_blocking/app_blocking_controller.dart';
import '../services/app_blocking/block_coordinator.dart';
import '../services/completion_audio_service.dart';
import '../services/completion_banner_controller.dart';
import '../services/notification_service.dart';
import '../widgets/completion_banner_overlay.dart';
import 'app_blocking_scope.dart';
import 'app_theme.dart';
import 'pomodoro_scope.dart';
import 'settings_scope.dart';
import 'stats_scope.dart';
import 'tab_shell.dart';
import 'timer_scope.dart';
import 'stopwatch_scope.dart';

class PomodoApp extends StatefulWidget {
  const PomodoApp({super.key, required this.notificationService});

  final NotificationService notificationService;

  @override
  State<PomodoApp> createState() => _PomodoAppState();
}

class _PomodoAppState extends State<PomodoApp> {
  late final SettingsController _settingsController;
  late final StatsController _statsController;
  late final CompletionAudioService _audioService;
  late final CompletionBannerController _bannerController;
  late final AppBlockingController _appBlockingController;

  @override
  void initState() {
    super.initState();
    _settingsController = SettingsController(
      notificationService: widget.notificationService,
    );
    unawaited(_settingsController.initialize());
    _bannerController = CompletionBannerController();
    widget.notificationService.setNotificationsEnabledResolver(
      () => _settingsController.notificationsEnabled,
    );
    _audioService = CompletionAudioService(
      soundsEnabledResolver: () => _settingsController.soundsEnabled,
    );
    if (kDebugMode) {
      unawaited(_audioService.debugWarmupPlayback());
    }
    _statsController = StatsController();
    unawaited(_statsController.initialize());
    _appBlockingController = AppBlockingController();
    unawaited(_appBlockingController.initialize());
  }

  @override
  void dispose() {
    unawaited(_audioService.dispose());
    _statsController.dispose();
    _settingsController.dispose();
    _bannerController.dispose();
    _appBlockingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StatsScope(
      controller: _statsController,
      child: SettingsScope(
        controller: _settingsController,
        child: AppBlockingScope(
          controller: _appBlockingController,
          child: PomodoroScope(
            settingsController: _settingsController,
            statsController: _statsController,
            audioService: _audioService,
            notificationService: widget.notificationService,
            bannerController: _bannerController,
            child: TimerScope(
              notificationService: widget.notificationService,
              audioService: _audioService,
              settingsController: _settingsController,
              bannerController: _bannerController,
              child: StopwatchScope(
                child: AppBlockingBridge(
                  child: MaterialApp(
                    title: 'Pomodo',
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.darkTheme,
                    darkTheme: AppTheme.darkTheme,
                    themeMode: ThemeMode.dark,
                    builder: (context, child) => CompletionBannerOverlay(
                      controller: _bannerController,
                      child: child ?? const SizedBox.shrink(),
                    ),
                    home: const EditorialOnboardingPage(),
                    routes: {'/tabs': (context) => const TabShell()},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
