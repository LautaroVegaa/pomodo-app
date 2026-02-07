import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';

enum AuthProvider { apple, google }

class AuthController extends ChangeNotifier {
  AuthController({required AuthService authService}) : _authService = authService;

  final AuthService _authService;
  StreamSubscription<User?>? _authSubscription;
  static const String _guestAccessDisabledKey = 'auth.guest_access_disabled';

  User? _user;
  bool _guestSession = false;
  bool _isBusy = false;
  AuthProvider? _activeProvider;
  bool _initialized = false;
  String? _errorMessage;
  int _guestSessionGeneration = 0;
  bool _guestPrefsLoaded = false;
  bool _guestAccessDisabled = false;

  bool get isReady => _initialized;
  bool get isBusy => _isBusy;
  bool get isGuestSession => _guestSession;
  bool get hasFirebaseUser => _user != null;
  bool get canAccessApp => _guestSession || _user != null;
  bool get canSignOut => _user != null;
  bool get canUseGuestAccess => !_guestAccessDisabled;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  int get guestSessionGeneration => _guestSessionGeneration;

  bool isProviderBusy(AuthProvider provider) => _isBusy && _activeProvider == provider;

  Future<void> initialize() async {
    await _ensureGuestPrefsLoaded();
    if (_initialized) {
      return;
    }
    _authSubscription = _authService.authStateChanges.listen(_handleAuthStateChanged);
  }

  Future<void> signInWithGoogle() => _runAuthFlow(AuthProvider.google, _authService.signInWithGoogle);

  Future<void> signInWithApple() => _runAuthFlow(AuthProvider.apple, _authService.signInWithApple);

  Future<void> continueWithoutAccount() async {
    await _ensureGuestPrefsLoaded();
    if (_guestAccessDisabled) {
      _guestSession = false;
      _errorMessage = 'Guest mode is only for first-time users. Please sign in.';
      notifyListeners();
      return;
    }
    debugPrint('[AuthController] Entering guest session');
    _guestSession = true;
    _user = null;
    _initialized = true;
    _errorMessage = null;
    _guestSessionGeneration += 1;
    notifyListeners();
  }

  Future<void> signOut() async {
    debugPrint('[AuthController] Signing out');
    _guestSession = false;
    _errorMessage = null;
    try {
      await _authService.signOut();
      _user = null;
    } on AuthFailure catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to sign out. Please try again.';
    } finally {
      notifyListeners();
    }
  }

  Future<void> _runAuthFlow(
    AuthProvider provider,
    Future<UserCredential> Function() operation,
  ) async {
    if (_isBusy) {
      return;
    }
    _errorMessage = null;
    _isBusy = true;
    _activeProvider = provider;
    notifyListeners();
    try {
      await operation();
    } on AuthFailure catch (error) {
      if (!_isCancellation(error.code)) {
        _errorMessage = error.message;
      }
    } catch (_) {
      _errorMessage = 'Unable to sign in. Please try again.';
    } finally {
      _isBusy = false;
      _activeProvider = null;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }
    _errorMessage = null;
    notifyListeners();
  }

  bool _isCancellation(String code) => code.endsWith('canceled');

  void _handleAuthStateChanged(User? user) {
    debugPrint('[AuthController] Auth state change. user=${user?.uid ?? 'none'}');
    _user = user;
    if (user != null) {
      _guestSession = false;
      _freezeGuestAccess();
    }
    _initialized = true;
    notifyListeners();
  }

  void _freezeGuestAccess() {
    if (_guestAccessDisabled) {
      return;
    }
    _guestAccessDisabled = true;
    unawaited(_persistGuestPrefs());
  }

  Future<void> _ensureGuestPrefsLoaded() {
    if (_guestPrefsLoaded) {
      return Future<void>.value();
    }
    return _loadGuestPrefs();
  }

  Future<void> _loadGuestPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _guestAccessDisabled = prefs.getBool(_guestAccessDisabledKey) ?? false;
    _guestPrefsLoaded = true;
  }

  Future<void> _persistGuestPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestAccessDisabledKey, _guestAccessDisabled);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
