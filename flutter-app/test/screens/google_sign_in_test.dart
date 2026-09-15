import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/core/constants/api_endpoints.dart';
import 'package:sawa/core/errors/api_exception.dart';
import 'package:sawa/core/models/auth_response_model.dart';
import 'package:sawa/core/services/auth_service.dart';
import 'package:sawa/core/services/google_sign_in_service.dart';
import 'package:sawa/core/state/auth_state.dart';
import 'package:sawa/screens/log_in_screen.dart';

void setPhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget createTestApp(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, _) => MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: child,
      ),
    ),
  );
}

class FakeGoogleSignInProvider implements IGoogleSignInProvider {
  final Future<String?> Function()? onSignIn;
  int callCount = 0;

  FakeGoogleSignInProvider({this.onSignIn});

  @override
  Future<String?> signInAndGetIdToken() async {
    callCount++;
    if (onSignIn != null) {
      return onSignIn!();
    }
    return 'fake_id_token_123';
  }

  @override
  Future<void> signOut() async {}
}

class FakeAuthService extends AuthService {
  final Future<AuthResponseModel> Function(String idToken)? onLoginWithGoogle;

  FakeAuthService({this.onLoginWithGoogle});

  @override
  Future<AuthResponseModel> loginWithGoogle(String idToken) async {
    if (onLoginWithGoogle != null) {
      return onLoginWithGoogle!(idToken);
    }
    return AuthResponseModel(
      token: 'fake_jwt_token',
      expiresAtUtc: DateTime.now().add(const Duration(hours: 1)),
      user: const AuthUserModel(
        id: 'user-123',
        email: 'parent@mindora.com',
        fullName: 'Parent Google',
        role: 'Parent',
        profileId: 'profile-123',
      ),
    );
  }
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('Google Sign-In Constants & Contract', () {
    test('ApiEndpoints.googleLogin is /api/auth/google', () {
      expect(ApiEndpoints.googleLogin, equals('/api/auth/google'));
    });
  });

  group('Google Sign-In Widget & Interaction Tests', () {
    testWidgets('LogInScreen renders Google sign-in button', (tester) async {
      setPhoneSize(tester);
      await tester.pumpWidget(createTestApp(LogInScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('google_sign_in_button')), findsOneWidget);
    });

    testWidgets('User cancellation does not show an error snackbar', (tester) async {
      setPhoneSize(tester);

      final fakeProvider = FakeGoogleSignInProvider(
        onSignIn: () async => null, // null simulates user cancelling account picker
      );

      await tester.pumpWidget(createTestApp(LogInScreen(googleSignInProvider: fakeProvider)));
      await tester.pumpAndSettle();

      final googleBtn = find.byKey(const Key('google_sign_in_button'));
      expect(googleBtn, findsOneWidget);

      await tester.tap(googleBtn);
      await tester.pumpAndSettle();

      expect(fakeProvider.callCount, equals(1));
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('Doctor account conflict displays localized platform error', (tester) async {
      setPhoneSize(tester);

      final fakeAuthService = FakeAuthService(
        onLoginWithGoogle: (token) async {
          throw const ApiException(
            statusCode: 409,
            message: 'هذا الحساب مسجل بالفعل على لوحة تحكم الطبيب.',
          );
        },
      );

      final customAuthState = AuthState(authService: fakeAuthService);

      // Use custom state by testing loginWithGoogle directly
      expect(
        () => customAuthState.loginWithGoogle('doctor_id_token'),
        throwsA(isA<ApiException>().having(
          (e) => e.firstErrorMessage,
          'message',
          'هذا الحساب مسجل بالفعل على لوحة تحكم الطبيب.',
        )),
      );
    });

    testWidgets('Duplicate tap prevention while signing in', (tester) async {
      setPhoneSize(tester);

      final completer = Completer<String?>();
      final fakeProvider = FakeGoogleSignInProvider(
        onSignIn: () => completer.future,
      );

      await tester.pumpWidget(createTestApp(LogInScreen(googleSignInProvider: fakeProvider)));
      await tester.pumpAndSettle();

      final googleBtn = find.byKey(const Key('google_sign_in_button'));
      expect(googleBtn, findsOneWidget);

      // First tap begins sign-in
      await tester.tap(googleBtn);
      await tester.pump(); // Start async execution, _isLoading is now true

      // Second tap while still in-flight
      await tester.tap(googleBtn);
      await tester.pump();

      // Third tap
      await tester.tap(googleBtn);
      await tester.pump();

      // Call count should remain 1 because _isLoading guards subsequent taps
      expect(fakeProvider.callCount, equals(1));

      // Finish the in-flight future with cancellation
      completer.complete(null);
      await tester.pumpAndSettle();
    });

    testWidgets('AuthState.loginWithGoogle establishes session', (tester) async {
      final fakeAuthService = FakeAuthService();
      final authState = AuthState(authService: fakeAuthService);

      expect(authState.isAuthenticated, isFalse);
      expect(authState.currentUser, isNull);

      final response = await authState.loginWithGoogle('valid_token');

      expect(authState.isAuthenticated, isTrue);
      expect(authState.currentUser, isNotNull);
      expect(authState.currentUser!.email, equals('parent@mindora.com'));
      expect(authState.currentUser!.role, equals('Parent'));
      expect(response.token, equals('fake_jwt_token'));
    });

    testWidgets('Tapping Facebook button shows "متاح في التحديث القادم" and remains on Login screen', (tester) async {
      setPhoneSize(tester);
      await tester.pumpWidget(createTestApp(LogInScreen()));
      await tester.pumpAndSettle();

      final fbBtn = find.byKey(const Key('facebook_sign_in_button'));
      expect(fbBtn, findsOneWidget);

      await tester.tap(fbBtn);
      await tester.pump();

      expect(find.text('متاح في التحديث القادم'), findsOneWidget);
      expect(find.byType(LogInScreen), findsOneWidget);
    });

    testWidgets('Tapping Apple button shows "متاح في التحديث القادم" and remains on Login screen', (tester) async {
      setPhoneSize(tester);
      await tester.pumpWidget(createTestApp(LogInScreen()));
      await tester.pumpAndSettle();

      final appleBtn = find.byKey(const Key('apple_sign_in_button'));
      expect(appleBtn, findsOneWidget);

      await tester.tap(appleBtn);
      await tester.pump();

      expect(find.text('متاح في التحديث القادم'), findsOneWidget);
      expect(find.byType(LogInScreen), findsOneWidget);
    });
  });
}
