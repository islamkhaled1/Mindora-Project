import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconify_flutter/icons/dashicons.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:sawa/app_text_styles.dart';
import 'package:sawa/app_colors.dart';
import 'package:sawa/screens/child_information_first_screen.dart';
import 'package:sawa/screens/forget_password_screen.dart';
import 'package:sawa/screens/home_screen.dart';
import 'package:sawa/screens/sign_up_screen.dart';
import 'package:sawa/screens/verify_email_screen.dart';
import '../core/storage/secure_storage_service.dart';
import 'package:sawa/widgets/auth_action_row.dart';
import 'package:sawa/widgets/custom_elevated_button.dart';
import 'package:sawa/widgets/custom_padding.dart';
import 'package:sawa/widgets/custom_text_field.dart';
import 'package:sawa/widgets/custom_title.dart';
import 'package:sawa/widgets/description.dart';
import 'package:sawa/widgets/divider_row.dart';
import 'package:sawa/widgets/social_media_logos.dart';

import '../core/errors/api_exception.dart';
import '../core/models/auth_requests.dart';
import '../core/state/auth_state.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';

import '../core/services/google_sign_in_service.dart';

class LogInScreen extends StatefulWidget {
  final IGoogleSignInProvider? googleSignInProvider;

  LogInScreen({super.key, this.googleSignInProvider});

  @override
  State<LogInScreen> createState() => _LogInScreenState();
}

class _LogInScreenState extends State<LogInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(
    text: kDebugMode ? 'parent@mindora.com' : '',
  );
  final _passwordController = TextEditingController(
    text: kDebugMode ? 'Parent123!' : '',
  );

  bool isChecked = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _emailController.text = 'parent@mindora.com';
      _passwordController.text = 'Parent123!';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'من فضلك أدخل البريد الإلكتروني';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'صيغة البريد الإلكتروني غير صحيحة';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'من فضلك أدخل كلمة المرور';
    }
    if (value.length < 8) {
      return 'كلمة المرور يجب ألا تقل عن 8 أحرف';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final request = LoginRequest(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await AuthState.instance.login(request);

      var activeChildId = await SecureStorageService().getActiveChildId();
      try {
        final res = await ApiClient().get(ApiEndpoints.children);
        if (res.data is List && (res.data as List).isNotEmpty) {
          final validIds = (res.data as List)
              .map((c) => c['id']?.toString() ?? c['Id']?.toString())
              .whereType<String>()
              .toList();
          if (activeChildId == null || !validIds.contains(activeChildId)) {
            activeChildId = validIds.first;
            await SecureStorageService().saveActiveChildId(activeChildId);
          }
        } else {
          activeChildId = null;
          await SecureStorageService().clearActiveChildId();
        }
      } catch (_) {}

      if (!mounted) return;
      if (activeChildId != null && activeChildId.trim().isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChildInformationFirstScreen()),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 403 || e.firstErrorMessage.contains('تأكيد البريد') || e.firstErrorMessage.contains('تأكيد حسابك')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.firstErrorMessage),
            backgroundColor: Colors.orange.shade800,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'تأكيد الحساب',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VerifyEmailScreen(
                      email: _emailController.text.trim(),
                    ),
                  ),
                );
              },
            ),
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.firstErrorMessage),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ في تسجيل الدخول، يرجى المحاولة مرة أخرى'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final googleProvider = widget.googleSignInProvider ?? GoogleSignInProvider();
      final idToken = await googleProvider.signInAndGetIdToken();

      if (idToken == null || idToken.trim().isEmpty) {
        // User closed or cancelled account picker
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      await AuthState.instance.loginWithGoogle(idToken);

      var activeChildId = await SecureStorageService().getActiveChildId();
      try {
        final res = await ApiClient().get(ApiEndpoints.children);
        if (res.data is List && (res.data as List).isNotEmpty) {
          final validIds = (res.data as List)
              .map((c) => c['id']?.toString() ?? c['Id']?.toString())
              .whereType<String>()
              .toList();
          if (activeChildId == null || !validIds.contains(activeChildId)) {
            activeChildId = validIds.first;
            await SecureStorageService().saveActiveChildId(activeChildId);
          }
        } else {
          activeChildId = null;
          await SecureStorageService().clearActiveChildId();
        }
      } catch (_) {}

      if (!mounted) return;
      if (activeChildId != null && activeChildId.trim().isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ChildInformationFirstScreen()),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.firstErrorMessage),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء تسجيل الدخول باستخدام Google'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showComingSoonMessage() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('متاح في التحديث القادم'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: CustomPadding(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(height: 70.h),
                Center(child: CustomTitle(title: 'خطوات صغيرة', fontSize: 23)),
                SizedBox(height: 12.h),
                Center(
                  child: Description(
                    text: '💜 معًا، كل خطوة مهمة',
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 45.h),
                Center(
                  child: CustomTitle(title: 'مرحبًا بعودتك', fontSize: 23),
                ),
                SizedBox(height: 12.h),
                Center(
                  child: Description(
                    text: 'سجّل الدخول لمتابعة رحلتكم',
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 25.h),
                CustomTextField(
                  hint: 'البريد الإلكتروني',
                  icon: Dashicons.email_alt,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                SizedBox(height: 10.h),
                CustomTextField(
                  hint: 'كلمة المرور',
                  icon: Mdi.lock,
                  isPassword: true,
                  controller: _passwordController,
                  validator: _validatePassword,
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ForgetPasswordScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'نسيت كلمة المرور؟',
                        style: AppTextStyles.font400Regular.copyWith(
                          fontSize: 12,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'تذكرني',
                          style: AppTextStyles.font400Regular.copyWith(
                            fontSize: 12,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        Checkbox(
                          activeColor: AppColors.primaryColor,
                          side: BorderSide(color: AppColors.primaryColor),
                          value: isChecked,
                          onChanged: (bool? value) {
                            setState(() {
                              isChecked = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 19.h),
                CustomElevatedButton(
                  title: 'تسجيل الدخول',
                  isLoading: _isLoading,
                  onPressed: _handleLogin,
                ),
                SizedBox(height: 35.h),
                DividerRow(text: 'أو سجّل الدخول باستخدام'),
                SizedBox(height: 12.h),
                SocialMediaLogos(
                  onGoogleTap: _isLoading ? null : _handleGoogleSignIn,
                  onFacebookTap: _isLoading ? null : _showComingSoonMessage,
                  onAppleTap: _isLoading ? null : _showComingSoonMessage,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.r),
                  child: AuthActionRow(
                    linkText: 'سجّل الآن ',
                    question: 'ليس لديك حساب؟',
                    targetScreen: SignUpScreen(),
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
