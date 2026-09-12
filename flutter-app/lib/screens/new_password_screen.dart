import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ci.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:sawa/app_colors.dart';
import 'package:sawa/screens/reset_screen.dart';
import 'package:sawa/widgets/back_icon.dart';
import 'package:sawa/widgets/custom_app_bar.dart';
import 'package:sawa/widgets/custom_elevated_button.dart';
import 'package:sawa/widgets/custom_padding.dart';
import 'package:sawa/widgets/custom_text_field.dart';
import 'package:sawa/widgets/custom_title.dart';
import 'package:sawa/widgets/description.dart';
import 'package:sawa/widgets/simi_bold_title.dart';

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  bool _hasLowercase = false;
  bool _hasUppercase = false;
  bool _hasDigit = false;
  bool _hasSpecialChar = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkPasswordRequirements);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_checkPasswordRequirements);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkPasswordRequirements() {
    final value = _passwordController.text;
    setState(() {
      _hasLowercase = RegExp(r'[a-z]').hasMatch(value);
      _hasUppercase = RegExp(r'[A-Z]').hasMatch(value);
      _hasDigit = RegExp(r'[0-9]').hasMatch(value);
      _hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=]').hasMatch(value);
    });
  }

  bool get _allRequirementsMet =>
      _hasLowercase && _hasUppercase && _hasDigit && _hasSpecialChar;

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'من فضلك أدخل كلمة المرور';
    }
    if (!_allRequirementsMet) {
      return 'كلمة المرور لا تحقق جميع المتطلبات';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'من فضلك أعد إدخال كلمة المرور';
    }
    if (value != _passwordController.text) {
      return 'كلمتا المرور غير متطابقتين';
    }
    return null;
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // TODO: API Call
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ResetScreen()),
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

  Widget _buildRequirementRow({required String label, required bool isMet}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Align(
        alignment: AlignmentGeometry.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.rtl,
          children: [
            Container(
              width: 18.w,
              height: 18.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isMet
                      ? AppColors.primaryColor
                      : AppColors.secondaryColor,
                  width: 2,
                ),
                color: Colors.transparent,
              ),
              child: isMet
                  ? Iconify(
                      Ci.check,
                      size: 12.sp,
                      color: AppColors.primaryColor,
                    )
                  : null,
            ),
            SizedBox(width: 8.w),
            Description(text: label, fontSize: 12),
          ],
        ),
      ),
    );
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
                  child: CustomTitle(title: 'كلمة مرور جديدة', fontSize: 23),
                ),
                SizedBox(height: 12.h),
                Center(
                  child: Description(
                    text: 'يرجى إدخال كلمة مرور قوية وجديدة لحسابك',
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 56.h),
                Align(
                  alignment: AlignmentGeometry.centerRight,
                  child: SimiBoldTitle(
                    title: 'كلمة المرور الجديدة',
                    fontSize: 14,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 4.0.r, top: 8.0.r),
                  child: CustomTextField(
                    hint: 'أدخل كلمة المرور الجديدة',
                    isPassword: true,
                    icon: Mdi.lock,
                    controller: _passwordController,
                    validator: _validatePassword,
                  ),
                ),
                SizedBox(height: 16.h),
                Align(
                  alignment: AlignmentGeometry.centerRight,
                  child: SimiBoldTitle(
                    title: 'تأكيد كلمة المرور',
                    fontSize: 14,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 4.0.r, top: 8.0.r),
                  child: CustomTextField(
                    hint: 'أعد إدخال كلمة المرور',
                    isPassword: true,
                    icon: Mdi.lock,
                    controller: _confirmPasswordController,
                    validator: _validateConfirmPassword,
                  ),
                ),
                SizedBox(height: 20.h),
                Align(
                  alignment: AlignmentGeometry.centerRight,
                  child: SimiBoldTitle(
                    title: 'متطلبات كلمة المرور:',
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 8.h),
                _buildRequirementRow(
                  label: 'حرف صغير واحد على الأقل (a-z)',
                  isMet: _hasLowercase,
                ),
                _buildRequirementRow(
                  label: 'حرف كبير واحد على الأقل (A-Z)',
                  isMet: _hasUppercase,
                ),
                _buildRequirementRow(
                  label: 'رقم واحد على الأقل (0-9)',
                  isMet: _hasDigit,
                ),
                _buildRequirementRow(
                  label: 'رمز خاص واحد على الأقل (!, @, #)',
                  isMet: _hasSpecialChar,
                ),
                SizedBox(height: 35.h),
                CustomElevatedButton(
                  title: 'إعادة تعيين كلمة المرور',
                  isLoading: _isLoading,
                  onPressed: _handleResetPassword,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
