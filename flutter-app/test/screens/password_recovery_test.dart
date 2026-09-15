import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/core/constants/api_endpoints.dart';
import 'package:sawa/screens/change_password_screen.dart';
import 'package:sawa/screens/forget_password_screen.dart';
import 'package:sawa/screens/new_password_screen.dart';
import 'package:sawa/screens/otp_verification_screen.dart';

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

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  group('Password Recovery Endpoints Constants Tests', () {
    test('ApiEndpoints defines all required password recovery routes', () {
      expect(ApiEndpoints.forgotPassword, equals('/api/auth/forgot-password'));
      expect(ApiEndpoints.verifyOtp, equals('/api/auth/verify-otp'));
      expect(ApiEndpoints.resetPassword, equals('/api/auth/reset-password'));
      expect(ApiEndpoints.changePassword, equals('/api/auth/change-password'));
    });
  });

  group('Password Recovery Screens Widget Tests', () {
    testWidgets('ForgetPasswordScreen renders email input and submit button', (tester) async {
      setPhoneSize(tester);
      await tester.pumpWidget(createTestApp(const ForgetPasswordScreen()));
      await tester.pumpAndSettle();

      expect(find.text('إعادة تعيين كلمة المرور'), findsOneWidget);
      expect(find.text('البريد الإلكتروني'), findsWidgets);
      expect(find.text('إرسال رمز التحقق'), findsOneWidget);
    });

    testWidgets('OtpVerificationScreen displays user email and 6-digit pin prompt', (tester) async {
      setPhoneSize(tester);
      const testEmail = 'doctor@mindora.com';
      await tester.pumpWidget(createTestApp(const OtpVerificationScreen(email: testEmail)));
      await tester.pumpAndSettle();

      expect(find.text('تحقق من صندوق الوارد'), findsOneWidget);
      expect(find.text(testEmail), findsOneWidget);
      expect(find.text('تأكيد'), findsOneWidget);
    });

    testWidgets('NewPasswordScreen renders new password fields and requirements', (tester) async {
      setPhoneSize(tester);
      await tester.pumpWidget(createTestApp(const NewPasswordScreen(resetToken: 'test-token-123')));
      await tester.pumpAndSettle();

      expect(find.text('كلمة مرور جديدة'), findsOneWidget);
      expect(find.text('كلمة المرور الجديدة'), findsOneWidget);
      expect(find.text('تأكيد كلمة المرور'), findsOneWidget);
      expect(find.text('متطلبات كلمة المرور:'), findsOneWidget);
      expect(find.text('إعادة تعيين كلمة المرور'), findsOneWidget);
    });

    testWidgets('ChangePasswordScreen renders current and new password fields', (tester) async {
      setPhoneSize(tester);
      await tester.pumpWidget(createTestApp(const ChangePasswordScreen()));
      await tester.pumpAndSettle();

      expect(find.text('تغيير كلمة المرور'), findsOneWidget);
      expect(find.text('كلمة المرور الحالية'), findsOneWidget);
      expect(find.text('كلمة المرور الجديدة'), findsOneWidget);
      expect(find.text('تأكيد كلمة المرور الجديدة'), findsOneWidget);
      expect(find.text('تحديث كلمة المرور'), findsOneWidget);
    });
  });
}
