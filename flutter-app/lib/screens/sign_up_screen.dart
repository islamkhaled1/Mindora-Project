import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconify_flutter/icons/dashicons.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:sawa/app_text_styles.dart';
import 'package:sawa/app_colors.dart';
import 'package:sawa/screens/child_information_first_screen.dart';
import 'package:sawa/widgets/back_icon.dart';
import 'package:sawa/widgets/custom_app_bar.dart';
import 'package:sawa/widgets/custom_elevated_button.dart';
import 'package:sawa/widgets/custom_padding.dart';
import 'package:sawa/widgets/custom_text_field.dart';
import 'package:sawa/widgets/custom_title.dart';
import 'package:sawa/widgets/description.dart';

class SignUpScreen extends StatefulWidget {
  SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedDialCode = '+20';
  bool isChecked = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'من فضلك أدخل الاسم الكامل';
    }
    return null;
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

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'من فضلك أدخل رقم الهاتف';
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

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'من فضلك أكد كلمة المرور';
    }
    if (value != _passwordController.text) {
      return 'كلمة المرور غير متطابقة';
    }
    return null;
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!isChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب الموافقة على الشروط والأحكام وسياسة الخصوصية'),
        ),
      );
      return;
    }

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: CustomAppBar(leading: BackIcon()),
      body: CustomPadding(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Center(
                  child: CustomTitle(title: 'إنشاء حساب جديد', fontSize: 23),
                ),
                SizedBox(height: 12.h),
                Center(
                  child: Description(
                    text: 'أنشئ حسابًا لبدء رحلتكم معنا',
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 56.h),
                CustomTextField(
                  hint: 'الاسم الكامل',
                  icon: Mdi.account,
                  controller: _nameController,
                  validator: _validateName,
                ),
                SizedBox(height: 10.h),
                CustomTextField(
                  hint: 'البريد الإلكتروني',
                  icon: Dashicons.email_alt,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                SizedBox(height: 10.h),
                CustomTextField(
                  hint: 'رقم الهاتف',
                  icon: Mdi.phone,
                  isPhone: true,
                  controller: _phoneController,
                  onCountryChanged: (country) {
                    _selectedDialCode = country.dialCode ?? '+20';
                  },
                  validator: _validatePhone,
                ),
                SizedBox(height: 10.h),
                CustomTextField(
                  hint: 'كلمة المرور',
                  icon: Mdi.lock,
                  isPassword: true,
                  controller: _passwordController,
                  validator: _validatePassword,
                ),
                SizedBox(height: 10.h),
                CustomTextField(
                  hint: 'تأكيد كلمة المرور',
                  icon: Mdi.lock,
                  isPassword: true,
                  controller: _confirmPasswordController,
                  validator: _validateConfirmPassword,
                ),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
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
                    Text(
                      'الشروط والأحكام و سياسة الخصوصية ',
                      style: AppTextStyles.font400Regular.copyWith(
                        fontSize: 12,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    Text(
                      'أوافق على',
                      style: AppTextStyles.font400Regular.copyWith(
                        fontSize: 12,
                        color: AppColors.secondaryColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 19.h),
                CustomElevatedButton(
                  title: 'إنشاء حساب',
                  isLoading: _isLoading,
                  onPressed: _handleSignUp,
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
