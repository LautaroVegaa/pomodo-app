import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../features/onboarding/editorial_onboarding_page.dart';
import '../features/settings/settings_controller.dart';
import '../features/stats/stats_controller.dart';
import '../services/app_blocking/app_blocking_controller.dart';
import '../services/app_blocking/block_coordinator.dart';
import '../services/auth/auth_controller.dart';
import '../services/auth/auth_service.dart';
import '../services/completion_audio_service.dart';
import '../services/completion_banner_controller.dart';
import '../services/notification_service.dart';
import '../widgets/completion_banner_overlay.dart';
import 'app_blocking_scope.dart';
import 'app_theme.dart';
import 'auth_scope.dart';
import 'pomodoro_scope.dart';
import 'settings_scope.dart';
import 'stats_scope.dart';
import 'stopwatch_scope.dart';
import 'tab_shell.dart';
import 'timer_scope.dart';

class PomodoApp extends StatefulWidget {
  const PomodoApp({
    super.key,
    required this.notificationService,
    required this.startSignedIn,
  });

  final NotificationService notificationService;
  final bool startSignedIn;

  @override
  State<PomodoApp> createState() => _PomodoAppState();
}

class _PomodoAppState extends State<PomodoApp> {
  late final SettingsController _settingsController;
  late final StatsController _statsController;
  late final CompletionAudioService _audioService;
  late final CompletionBannerController _bannerController;
  late final AppBlockingController _appBlockingController;
  late final AuthController _authController;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _initialShellQueued = false;

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
    _authController = AuthController(authService: AuthService());
    unawaited(_authController.initialize());
    _initialShellQueued = widget.startSignedIn;
    if (widget.startSignedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _navigateToShell(clearStack: true));
    }
  }

  @override
  void dispose() {
    unawaited(_audioService.dispose());
    _statsController.dispose();
    _settingsController.dispose();
    _bannerController.dispose();
    _appBlockingController.dispose();
    _authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StatsScope(
      controller: _statsController,
      child: SettingsScope(
        controller: _settingsController,
        child: AuthScope(
          controller: _authController,
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
                      navigatorKey: _navigatorKey,
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
      ),
    );
  }

  void _navigateToShell({bool clearStack = false}) {
    if (!_initialShellQueued) {
      return;
    }
    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      return;
    }
    final route = MaterialPageRoute(builder: (_) => const TabShell());
    if (clearStack) {
      navigator.pushAndRemoveUntil(route, (_) => false);
    } else {
      navigator.pushReplacement(route);
    }
    _initialShellQueued = false;
  }
}
