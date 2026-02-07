import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pomodo_app/services/auth/auth_controller.dart';
import 'package:pomodo_app/services/auth/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAuthService extends Mock implements AuthService {}

const String _guestDisabledKey = 'auth.guest_access_disabled';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('guest mode disables permanently after first login', () async {
    final _MockAuthService authService = _MockAuthService();
    final StreamController<User?> authChanges = StreamController<User?>.broadcast();
    when(() => authService.authStateChanges).thenAnswer((_) => authChanges.stream);
    when(() => authService.signOut()).thenAnswer((_) async {});

    final AuthController controller = AuthController(authService: authService);
    addTearDown(() async => authChanges.close());
    addTearDown(controller.dispose);

    await controller.initialize();
    authChanges.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(controller.canUseGuestAccess, isTrue);

    final MockUser user = MockUser(uid: 'user-123');
    authChanges.add(user);
    await Future<void>.delayed(Duration.zero);

    expect(controller.canUseGuestAccess, isFalse);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(_guestDisabledKey), isTrue);

    final _MockAuthService restoredService = _MockAuthService();
    final StreamController<User?> restoredStream = StreamController<User?>.broadcast();
    when(() => restoredService.authStateChanges).thenAnswer((_) => restoredStream.stream);
    when(() => restoredService.signOut()).thenAnswer((_) async {});

    final AuthController restored = AuthController(authService: restoredService);
    addTearDown(() async => restoredStream.close());
    addTearDown(restored.dispose);

    await restored.initialize();
    restoredStream.add(null);
    await Future<void>.delayed(Duration.zero);

    expect(restored.canUseGuestAccess, isFalse);
  });

  test('guest session request is rejected after login history', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{_guestDisabledKey: true});

    final _MockAuthService authService = _MockAuthService();
    final StreamController<User?> authChanges = StreamController<User?>.broadcast();
    when(() => authService.authStateChanges).thenAnswer((_) => authChanges.stream);

    final AuthController controller = AuthController(authService: authService);
    addTearDown(() async => authChanges.close());
    addTearDown(controller.dispose);

    await controller.initialize();
    authChanges.add(null);
    await Future<void>.delayed(Duration.zero);

    await controller.continueWithoutAccount();

    expect(controller.isGuestSession, isFalse);
    expect(controller.errorMessage, 'Guest mode is only for first-time users. Please sign in.');
  });
}
