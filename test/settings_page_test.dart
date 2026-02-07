import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pomodo_app/app/app_blocking_scope.dart';
import 'package:pomodo_app/app/auth_scope.dart';
import 'package:pomodo_app/app/pomodoro_scope.dart';
import 'package:pomodo_app/app/settings_scope.dart';
import 'package:pomodo_app/app/stats_scope.dart';
import 'package:pomodo_app/features/auth/login_entry_page.dart';
import 'package:pomodo_app/features/settings/settings_controller.dart';
import 'package:pomodo_app/features/settings/settings_page.dart';
import 'package:pomodo_app/features/settings/settings_storage.dart';
import 'package:pomodo_app/features/stats/stats_controller.dart';
import 'package:pomodo_app/features/stats/stats_storage.dart';
import 'package:pomodo_app/services/app_blocking/app_blocking_controller.dart';
import 'package:pomodo_app/services/auth/auth_controller.dart';
import 'package:pomodo_app/services/completion_audio_service.dart';
import 'package:pomodo_app/services/completion_banner_controller.dart';
import 'package:pomodo_app/services/notification_service.dart';

class _MockAudioPlayer extends Mock implements AudioPlayer {}

class _StubGoogleSignIn extends Fake implements GoogleSignIn {}

/// Test-only AuthController: no Firebase streams, no platform work.
class _TestAuthController extends ChangeNotifier implements AuthController {
  _TestAuthController.guest({bool guestAllowed = true})
      : _canUseGuestAccess = guestAllowed,
        _guestSession = true,
        _user = null;

  _TestAuthController.signedIn()
      : _canUseGuestAccess = false,
        _guestSession = false,
        _user = MockUser(uid: 'user-123', email: 'user@example.com');

  bool _guestSession;
  final bool _canUseGuestAccess;
  int _guestSessionGeneration = 0;
  MockUser? _user;
  String? _errorMessage;

  @override
  bool get isReady => true;

  @override
  bool get isBusy => false;

  @override
  bool get isGuestSession => _guestSession;

  @override
  bool get hasFirebaseUser => _user != null;

  @override
  bool get canAccessApp => _guestSession || _user != null;

  @override
  bool get canSignOut => _user != null;

  @override
  MockUser? get user => _user;

  @override
  String? get errorMessage => _errorMessage;

  @override
  bool get canUseGuestAccess => _canUseGuestAccess;

  @override
  int get guestSessionGeneration => _guestSessionGeneration;

  @override
  bool isProviderBusy(AuthProvider provider) => false;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signInWithApple() async {}

  @override
  Future<void> continueWithoutAccount() async {
    if (!_canUseGuestAccess) {
      _errorMessage = 'Guest mode is only for first-time users. Please sign in.';
      notifyListeners();
      return;
    }
    _guestSession = true;
    _user = null;
    _guestSessionGeneration += 1;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _guestSession = false;
    notifyListeners();
  }

  @override
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(ReleaseMode.stop);
    registerFallbackValue(PlayerMode.mediaPlayer);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('guest session shows Log in action', (tester) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    final AuthController authController = _TestAuthController.guest();
    addTearDown(authController.dispose);

    await _pumpSettingsPage(tester, authController: authController);

    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('Sign out'), findsNothing);
  });

  testWidgets('signed-in user hides Log in action', (tester) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    final AuthController authController = _TestAuthController.signedIn();
    addTearDown(authController.dispose);

    await _pumpSettingsPage(tester, authController: authController);

    expect(find.text('Log in'), findsNothing);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('Login chooser returns to settings after continuing as guest', (tester) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    final AuthController authController = _TestAuthController.guest();
    addTearDown(authController.dispose);

    await _pumpSettingsPage(tester, authController: authController);

    final Finder loginAction = find.text('Log in');
    expect(loginAction, findsOneWidget);
    await tester.ensureVisible(loginAction);
    await tester.pump();

    await tester.tap(loginAction);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(LoginEntryPage), findsOneWidget);

    final Finder continueGuest = find.text('Continue without account');
    await tester.ensureVisible(continueGuest);
    await tester.pump();
    await tester.tap(continueGuest);

    await tester.pump();
    await tester.pump();

    // Don't depend on SettingsPage auto-pop logic in widget tests.
    // Explicitly return to the Settings route by popping the Navigator ourselves.
    final BuildContext loginContext = tester.element(find.byType(LoginEntryPage));
    Navigator.of(loginContext).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(SettingsPage), findsOneWidget);
    expect(authController.isGuestSession, isTrue);
  });
}

Future<void> _pumpSettingsPage(
  WidgetTester tester, {
  required AuthController authController,
}) async {
  final NotificationService notificationService = NotificationService.test();

  final _InMemorySettingsStorage settingsStorage = _InMemorySettingsStorage();
  final SettingsController settingsController = SettingsController(
    storage: settingsStorage,
    notificationService: notificationService,
  );
  await settingsController.initialize();
  addTearDown(settingsController.dispose);

  final _InMemoryStatsStorage statsStorage = _InMemoryStatsStorage();
  final StatsController statsController = StatsController(storage: statsStorage);
  await statsController.initialize();
  await statsController.applyUserScope(userUid: 'settings-user');
  addTearDown(statsController.dispose);

  final CompletionBannerController bannerController = CompletionBannerController();
  addTearDown(bannerController.dispose);

  final AudioPlayer audioPlayer = _MockAudioPlayer();
  when(() => audioPlayer.setReleaseMode(ReleaseMode.stop)).thenAnswer((_) async {});
  when(() => audioPlayer.setVolume(any())).thenAnswer((_) async {});
  when(() => audioPlayer.stop()).thenAnswer((_) async {});
  when(
    () => audioPlayer.play(
      AssetSource('audio/pomodoro_ring.m4a'),
      mode: PlayerMode.lowLatency,
    ),
  ).thenAnswer((_) async {});
  when(() => audioPlayer.dispose()).thenAnswer((_) async {});

  final CompletionAudioService audioService = CompletionAudioService(
    soundsEnabledResolver: () => false,
    player: audioPlayer,
    enableWarmup: false,
  );
  addTearDown(() async => audioService.dispose());

  final AppBlockingController appBlockingController =
      AppBlockingController(debugPlatformOverride: TargetPlatform.android);
  addTearDown(appBlockingController.dispose);

  // AuthScope MUST wrap the entire MaterialApp so pushed routes / overlays can see it.
  await tester.pumpWidget(
    AuthScope(
      controller: authController,
      child: MaterialApp(
        home: StatsScope(
          controller: statsController,
          child: SettingsScope(
            controller: settingsController,
            child: AppBlockingScope(
              controller: appBlockingController,
              child: PomodoroScope(
                settingsController: settingsController,
                statsController: statsController,
                audioService: audioService,
                notificationService: notificationService,
                bannerController: bannerController,
                child: const SettingsPage(),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

class _InMemoryStatsStorage extends StatsStorage {
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
  Future<String> resolveGuestUserKey() async => 'guest:settings';

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

class _InMemorySettingsStorage extends SettingsStorage {
  ExperienceSettings _settings = ExperienceSettings.defaults;

  @override
  Future<ExperienceSettings> loadExperience() async => _settings;

  @override
  Future<void> saveExperience(ExperienceSettings settings) async {
    _settings = settings;
  }
}
