import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Lightweight domain exception used to bubble up user-friendly errors.
class AuthFailure implements Exception {
  const AuthFailure(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'AuthFailure($code): $message';
}

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  bool _googleInitialized = false;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<UserCredential> signInWithGoogle() async {
    debugPrint('[AuthService] Starting Google sign-in');
    try {
      await _ensureGoogleInitialized();
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      if (idToken == null) {
        throw const AuthFailure('google-missing-token', 'Missing Google ID token.');
      }
      final String? accessToken = await _fetchAccessToken(googleUser);
      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );
      final result = await _firebaseAuth.signInWithCredential(credential);
      debugPrint('[AuthService] Google sign-in complete for ${result.user?.uid ?? 'unknown user'}');
      return result;
    } on AuthFailure {
      rethrow;
    } on GoogleSignInException catch (error) {
      debugPrint('[AuthService] GoogleSignInException: ${error.code.name}');
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthFailure('google-canceled', 'Sign-in was canceled.');
      }
      throw AuthFailure(
        'google-${error.code.name.toLowerCase()}',
        error.description ?? 'Unable to sign in with Google.',
      );
    } on FirebaseAuthException catch (error) {
      debugPrint('[AuthService] FirebaseAuthException (google): ${error.code}');
      throw AuthFailure(error.code, error.message ?? 'Unable to sign in with Google.');
    } catch (error) {
      debugPrint('[AuthService] Unknown Google sign-in error: $error');
      throw const AuthFailure('google-error', 'Unable to sign in with Google.');
    }
  }

  Future<UserCredential> signInWithApple() async {
    debugPrint('[AuthService] Starting Apple sign-in');
    try {
      final String rawNonce = _generateNonce();
      final String hashedNonce = _sha256OfString(rawNonce);
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
      final String? identityToken = appleCredential.identityToken;
      if (identityToken == null) {
        throw const AuthFailure('apple-missing-token', 'Missing Apple identity token.');
      }
      final String authorizationCode = appleCredential.authorizationCode;
      if (authorizationCode.isEmpty) {
        throw const AuthFailure(
          'apple-missing-auth-code',
          'Missing Apple authorization code.',
        );
      }
      final credential = OAuthProvider('apple.com').credential(
        idToken: identityToken,
        accessToken: authorizationCode,
        rawNonce: rawNonce,
      );
      final result = await _firebaseAuth.signInWithCredential(credential);
      debugPrint('[AuthService] Apple sign-in complete for ${result.user?.uid ?? 'unknown user'}');
      return result;
    } on SignInWithAppleAuthorizationException catch (error) {
      debugPrint('[AuthService] Apple authorization exception: ${error.code.name}');
      if (error.code == AuthorizationErrorCode.canceled) {
        throw const AuthFailure('apple-canceled', 'Sign-in was canceled.');
      }
      throw AuthFailure('apple-${error.code.name.toLowerCase()}', 'Apple sign-in failed.');
    } on FirebaseAuthException catch (error) {
      debugPrint('[AuthService] FirebaseAuthException (apple): ${error.code}');
      throw AuthFailure(error.code, error.message ?? 'Unable to sign in with Apple.');
    } catch (error) {
      debugPrint('[AuthService] Unknown Apple sign-in error: $error');
      throw const AuthFailure('apple-error', 'Unable to sign in with Apple.');
    }
  }

  Future<void> signOut() async {
    debugPrint('[AuthService] Signing out current user');
    await Future.wait<dynamic>([
      _signOutGoogle(),
      _firebaseAuth.signOut(),
    ]);
  }

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) {
      return;
    }
    await _googleSignIn.initialize();
    _googleInitialized = true;
  }

  Future<void> _signOutGoogle() async {
    try {
      await _ensureGoogleInitialized();
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore sign-out issues; Firebase sign-out will proceed regardless.
    }
  }

  Future<String?> _fetchAccessToken(GoogleSignInAccount account) async {
    try {
      final GoogleSignInClientAuthorization? authorization =
          await account.authorizationClient.authorizationForScopes(const <String>['email']);
      return authorization?.accessToken;
    } catch (error) {
      debugPrint('[AuthService] Unable to fetch Google access token: $error');
      return null;
    }
  }

  String _generateNonce([int length = 32]) {
    const String charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final Random random = Random.secure();
    return List<String>.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256OfString(String input) {
    final List<int> bytes = utf8.encode(input);
    final Digest digest = sha256.convert(bytes);
    return digest.toString();
  }
}
