import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconify_flutter/icons/dashicons.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:sawa/core/constants/app_colors.dart';
import 'package:sawa/core/constants/app_text_styles.dart';
import 'package:sawa/core/widgets/buttons/custom_elevated_button.dart';
import 'package:sawa/core/widgets/common/custom_padding.dart';
import 'package:sawa/core/widgets/common/custom_title.dart';
import 'package:sawa/core/widgets/common/description.dart';
import 'package:sawa/core/widgets/common/divider_row.dart';
import 'package:sawa/core/widgets/text_fields/custom_text_field.dart';
import 'package:sawa/features/auth/screens/forget_password_screen.dart';
import 'package:sawa/features/auth/screens/sign_up_screen.dart';
import 'package:sawa/features/auth/widgets/auth_action_row.dart';
import 'package:sawa/features/auth/widgets/social_media_logos.dart';
import 'package:sawa/features/child/screens/child_information_first_screen.dart';

class LogInScreen extends StatefulWidget {
  LogInScreen({super.key});

  @override
  State<LogInScreen> createState() => _LogInScreenState();
}

class _LogInScreenState extends State<LogInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool isChecked = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmailOrPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'من فضلك أدخل البريد الإلكتروني أو رقم الهاتف';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'من فضلك أدخل كلمة المرور';
    }
    if (value.length < 6) {
      return 'كلمة المرور يجب ألا تقل عن 6 أحرف';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // TODO: API Call
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChildInformationFirstScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('حدث خطأ، حاول مرة أخرى')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                  hint: 'البريد الإلكتروني أو رقم الهاتف',
                  icon: Dashicons.email_alt,
                  controller: _emailController,
                  validator: _validateEmailOrPhone,
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
                SocialMediaLogos(),
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
