import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconify_flutter/icons/dashicons.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:sawa/constants.dart';
import 'package:sawa/core/errors/api_exception.dart';
import 'package:sawa/core/services/auth_service.dart';
import 'package:sawa/screens/log_in_screen.dart';
import 'package:sawa/screens/otp_verification_screen.dart';
import 'package:sawa/widgets/auth_action_row.dart';
import 'package:sawa/widgets/back_icon.dart';
import 'package:sawa/widgets/custom_app_bar.dart';
import 'package:sawa/widgets/custom_elevated_button.dart';
import 'package:sawa/widgets/custom_padding.dart';
import 'package:sawa/widgets/simi_bold_title.dart';
import 'package:sawa/widgets/custom_text_field.dart';
import 'package:sawa/widgets/custom_title.dart';
import 'package:sawa/widgets/description.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'من فضلك أدخل البريد الإلكتروني';
    }
    final email = value.trim();
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'صيغة البريد الإلكتروني غير صحيحة';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'من فضلك أدخل رقم الهاتف';
    }
    return null;
  }

  Future<void> _handleSendCode() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();

    setState(() => _isLoading = true);

    try {
      final result = await AuthService().forgotPassword(email);

      if (!mounted) return;

      if (result.isWrongPlatform) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message.isNotEmpty
                  ? result.message
                  : 'هذا الحساب مسجل على لوحة تحكم الطبيب.\nلاستعادة كلمة المرور، يرجى استخدام لوحة تحكم الطبيب.',
            ),
            backgroundColor: Colors.amber.shade900,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'تسجيل الدخول',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LogInScreen()),
                );
              },
            ),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message.isNotEmpty
                ? result.message
                : 'إذا كان البريد الإلكتروني مسجلاً، سيتم إرسال رمز التحقق.',
          ),
          backgroundColor: AppColors.primaryColor,
          duration: const Duration(seconds: 4),
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(email: email),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.firstErrorMessage),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء إرسال رمز التحقق، يرجى المحاولة مرة أخرى'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: CustomAppBar(leading: BackIcon()),
      body: SingleChildScrollView(
        child: CustomPadding(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Center(
                  child: CustomTitle(
                    title: 'إعادة تعيين كلمة المرور',
                    fontSize: 23,
                  ),
                ),
                SizedBox(height: 12.h),
                Center(
                  child: Description(
                    text: 'أدخل بريدك الإلكتروني أو رقم الجوال لاستعادة حسابك',
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 56.h),
                Align(
                  alignment: AlignmentGeometry.centerRight,
                  child: SimiBoldTitle(
                    title: 'البريد الإلكتروني',
                    fontSize: 14,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 4.0.r, top: 8.0.r),
                  child: CustomTextField(
                    hint: 'البريد الإلكتروني',
                    icon: Dashicons.email_alt,
                    controller: _emailController,
                    validator: _validateEmail,
                  ),
                ),
                SizedBox(height: 16.h),
                Align(
                  alignment: AlignmentGeometry.centerRight,
                  child: SimiBoldTitle(title: 'رقم الهاتف', fontSize: 14),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 4.0.r, top: 8.0.r),
                  child: CustomTextField(
                    hint: 'رقم الهاتف',
                    icon: Mdi.phone,
                    isPhone: true,
                    controller: _phoneController,
                    validator: _validatePhone,
                  ),
                ),
                SizedBox(height: 30.h),
                CustomElevatedButton(
                  title: 'إرسال رمز التحقق',
                  isLoading: _isLoading,
                  onPressed: _handleSendCode,
                ),
                Padding(
                  padding: EdgeInsets.only(top: 12.0.r),
                  child: Align(
                    alignment: AlignmentGeometry.center,
                    child: SimiBoldTitle(title: 'أو طريقة أخرى', fontSize: 12),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.r),
                  child: AuthActionRow(
                    question: ' تذكرت كلمة المرور؟',
                    linkText: 'تسجيل الدخول',
                    targetScreen: LogInScreen(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
