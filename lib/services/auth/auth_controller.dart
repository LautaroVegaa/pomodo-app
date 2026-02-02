import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'auth_service.dart';

enum AuthProvider { apple, google }

class AuthController extends ChangeNotifier {
  AuthController({required AuthService authService}) : _authService = authService;

  final AuthService _authService;
  StreamSubscription<User?>? _authSubscription;

  User? _user;
  bool _guestSession = false;
  bool _isBusy = false;
  AuthProvider? _activeProvider;
  bool _initialized = false;

  bool get isReady => _initialized;
  bool get isBusy => _isBusy;
  bool get isGuestSession => _guestSession;
  bool get hasFirebaseUser => _user != null;
  bool get canAccessApp => _guestSession || _user != null;
  bool get canSignOut => _guestSession || _user != null;
  User? get user => _user;

  bool isProviderBusy(AuthProvider provider) => _isBusy && _activeProvider == provider;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _authSubscription = _authService.authStateChanges.listen((user) {
      debugPrint('[AuthController] Auth state change. user=${user?.uid ?? 'none'}');
      _user = user;
      if (user != null) {
        _guestSession = false;
      }
      _initialized = true;
      notifyListeners();
    });
  }

  Future<void> signInWithGoogle() => _runAuthFlow(AuthProvider.google, _authService.signInWithGoogle);

  Future<void> signInWithApple() => _runAuthFlow(AuthProvider.apple, _authService.signInWithApple);

  Future<void> continueWithoutAccount() async {
    debugPrint('[AuthController] Entering guest session');
    _guestSession = true;
    _user = null;
    _initialized = true;
    notifyListeners();
  }

  Future<void> signOut() async {
    debugPrint('[AuthController] Signing out');
    _guestSession = false;
    await _authService.signOut();
    notifyListeners();
  }

  Future<void> _runAuthFlow(
    AuthProvider provider,
    Future<UserCredential> Function() operation,
  ) async {
    if (_isBusy) {
      return;
    }
    _isBusy = true;
    _activeProvider = provider;
    notifyListeners();
    try {
      await operation();
    } on AuthFailure {
      rethrow;
    } finally {
      _isBusy = false;
      _activeProvider = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
