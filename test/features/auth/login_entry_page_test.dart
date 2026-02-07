import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomodo_app/app/auth_scope.dart';
import 'package:pomodo_app/features/auth/login_entry_page.dart';
import 'package:pomodo_app/services/auth/auth_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _guestDisabledKey = 'auth.guest_access_disabled';

/// Test-only controller that mimics the AuthController surface needed by LoginEntryPage
/// without starting any Firebase streams or platform work.
class _TestAuthController extends ChangeNotifier implements AuthController {
  String? _errorMessage;

  // Guest access is locked out for this test case.
  @override
  bool get canUseGuestAccess => false;

  // Exposed so UI can rebuild if it depends on guest generation changes.
  @override
  int get guestSessionGeneration => 0;

  @override
  bool get isReady => true;

  @override
  bool get isBusy => false;

  @override
  bool get isGuestSession => false;

  @override
  bool get hasFirebaseUser => false;

  @override
  bool get canAccessApp => false;

  @override
  bool get canSignOut => false;

  @override
  fa.User? get user => null;

  @override
  String? get errorMessage => _errorMessage;

  @override
  bool isProviderBusy(AuthProvider provider) => false;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signInWithApple() async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> continueWithoutAccount() async {
    _errorMessage = 'Guest mode is only for first-time users. Please sign in.';
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

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{_guestDisabledKey: true});
  });

  testWidgets('guest access button copy reflects lockout and errors on tap', (tester) async {
    final AuthController controller = _TestAuthController();
    addTearDown(controller.dispose);

    // Ensure the widget tree is torn down so no pending frames keep the runner alive.
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: AuthScope(
          controller: controller,
          child: const LoginEntryPage(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final Finder disabledButton = find.text('Guest access unavailable after signing in');
    expect(disabledButton, findsOneWidget);

    await tester.tap(disabledButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Guest mode is only for first-time users. Please sign in.'), findsOneWidget);
  });
}
