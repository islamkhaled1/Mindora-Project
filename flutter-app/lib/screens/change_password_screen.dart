import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ci.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:sawa/constants.dart';
import 'package:sawa/core/errors/api_exception.dart';
import 'package:sawa/core/services/auth_service.dart';
import 'package:sawa/widgets/back_icon.dart';
import 'package:sawa/widgets/custom_app_bar.dart';
import 'package:sawa/widgets/custom_elevated_button.dart';
import 'package:sawa/widgets/custom_padding.dart';
import 'package:sawa/widgets/custom_text_field.dart';
import 'package:sawa/widgets/custom_title.dart';
import 'package:sawa/widgets/description.dart';
import 'package:sawa/widgets/simi_bold_title.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  bool _hasLowercase = false;
  bool _hasUppercase = false;
  bool _hasDigit = false;
  bool _hasSpecialChar = false;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_checkPasswordRequirements);
  }

  @override
  void dispose() {
    _newPasswordController.removeListener(_checkPasswordRequirements);
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkPasswordRequirements() {
    final value = _newPasswordController.text;
    setState(() {
      _hasLowercase = RegExp(r'[a-z]').hasMatch(value);
      _hasUppercase = RegExp(r'[A-Z]').hasMatch(value);
      _hasDigit = RegExp(r'[0-9]').hasMatch(value);
      _hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=]').hasMatch(value);
    });
  }

  bool get _allRequirementsMet =>
      _hasLowercase &&
      _hasUppercase &&
      _hasDigit &&
      _hasSpecialChar &&
      _newPasswordController.text.length >= 8;

  String? _validateCurrentPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'من فضلك أدخل كلمة المرور الحالية';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'من فضلك أدخل كلمة المرور الجديدة';
    }
    if (value.length < 8) {
      return 'كلمة المرور يجب ألا تقل عن 8 أحرف';
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
    if (value != _newPasswordController.text) {
      return 'كلمتا المرور غير متطابقتين';
    }
    return null;
  }

  Future<void> _handleChangePassword() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final message = await AuthService().changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message.isNotEmpty ? message : 'تم تغيير كلمة المرور بنجاح.'),
          backgroundColor: AppColors.primaryColor,
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.pop(context);
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
          content: Text('حدث خطأ أثناء تغيير كلمة المرور، يرجى التحقق من البيانات.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                  color: isMet ? AppColors.primaryColor : AppColors.secondaryColor,
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
            Flexible(child: Description(text: label, fontSize: 12)),
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
                  child: CustomTitle(title: 'تغيير كلمة المرور', fontSize: 23),
                ),
                SizedBox(height: 12.h),
                Center(
                  child: Description(
                    text: 'أدخل كلمة المرور الحالية وكلمة المرور الجديدة لتحديث حسابك',
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 40.h),
                Align(
                  alignment: AlignmentGeometry.centerRight,
                  child: SimiBoldTitle(
                    title: 'كلمة المرور الحالية',
                    fontSize: 14,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 4.0.r, top: 8.0.r),
                  child: CustomTextField(
                    hint: 'أدخل كلمة المرور الحالية',
                    isPassword: true,
                    icon: Mdi.lock,
                    controller: _currentPasswordController,
                    validator: _validateCurrentPassword,
                  ),
                ),
                SizedBox(height: 16.h),
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
                    controller: _newPasswordController,
                    validator: _validateNewPassword,
                  ),
                ),
                SizedBox(height: 16.h),
                Align(
                  alignment: AlignmentGeometry.centerRight,
                  child: SimiBoldTitle(
                    title: 'تأكيد كلمة المرور الجديدة',
                    fontSize: 14,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 4.0.r, top: 8.0.r),
                  child: CustomTextField(
                    hint: 'أعد إدخال كلمة المرور الجديدة',
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
                  label: '8 أحرف على الأقل',
                  isMet: _newPasswordController.text.length >= 8,
                ),
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
                  title: 'تحديث كلمة المرور',
                  isLoading: _isLoading,
                  onPressed: _handleChangePassword,
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
