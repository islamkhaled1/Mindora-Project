import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ci.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:sawa/constants.dart';
import 'package:sawa/screens/child_information_second_screen.dart';
import 'package:sawa/widgets/custom_elevated_button.dart';
import 'package:sawa/widgets/custom_image_picker.dart';
import 'package:sawa/widgets/custom_padding.dart';
import 'package:sawa/widgets/custom_text_field.dart';
import 'package:sawa/widgets/custom_title.dart';
import 'package:iconify_flutter/icons/ant_design.dart';
import 'package:sawa/widgets/cutom_date_field.dart';
import 'package:sawa/widgets/description.dart';
import 'package:sawa/widgets/simi_bold_title.dart';
import 'package:iconify_flutter/icons/zmdi.dart';
import 'package:iconify_flutter/icons/healthicons.dart';

class ChildInformationFirstScreen extends StatefulWidget {
  ChildInformationFirstScreen({super.key});

  @override
  State<ChildInformationFirstScreen> createState() =>
      _ChildInformationFirstScreenState();
}

class _ChildInformationFirstScreenState
    extends State<ChildInformationFirstScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _additionalInfoController = TextEditingController();

  String? selectedGender = 'male';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    _diagnosisController.dispose();
    _additionalInfoController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'من فضلك أدخل اسم الطفل';
    }
    return null;
  }

  String? _validateBirthDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'من فضلك اختر تاريخ الميلاد';
    }
    return null;
  }

  String? _validateDiagnosis(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'من فضلك أدخل تشخيص الحالة';
    }
    return null;
  }

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // TODO: API Call
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChildInformationSecondScreen()),
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
      body: CustomPadding(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(height: 36.h),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Iconify(
                        AntDesign.heart_fill,
                        size: 38.sp,
                        color: AppColors.primaryColor,
                      ),
                      SizedBox(width: 8.w),
                      CustomTitle(
                        title: 'خلّينا نتعرّف على طفلك',
                        fontSize: 20,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8.h),
                Description(
                  text: 'تساعدنا هذه المعلومات\n على تخصيص تجربة مناسبة لطفلك.',
                  fontSize: 13,
                ),
                SizedBox(height: 24.h),

                CustomImagePicker(defaultImage: 'assets/images/kid_image.png'),
                SizedBox(height: 16.h),
                Align(
                  alignment: AlignmentGeometry.centerRight,
                  child: SimiBoldTitle(
                    title: 'اسم الطفل بالكامل',
                    fontSize: 12,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 4.0.r, top: 8.0.r),
                  child: CustomTextField(
                    hint: 'أدخل اسم الطفل',
                    icon: Mdi.account,
                    height: 50,
                    controller: _nameController,
                    validator: _validateName,
                  ),
                ),
                SizedBox(height: 4.h),
                Align(
                  alignment: AlignmentGeometry.centerRight,
                  child: SimiBoldTitle(title: 'تاريخ الميلاد', fontSize: 12),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 4.0.r, top: 8.0.r),
                  child: CustomDateField(
                    hint: 'اختر تاريخ الميلاد',
                    prefixIcon: Iconify(
                      Zmdi.cake,
                      color: AppColors.primaryColor,
                      size: 25.sp,
                    ),
                    height: 50,
                    controller: _birthDateController,
                    validator: _validateBirthDate,
                  ),
                ),
                SizedBox(height: 4.h),
                Align(
                  alignment: AlignmentGeometry.centerRight,
                  child: SimiBoldTitle(title: 'التشخيص', fontSize: 12),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 4.0.r, top: 8.0.r),
                  child: CustomTextField(
                    hint: 'أدخل تشخيص الحالة',
                    icon: Healthicons.stethoscope,
                    height: 50,
                    controller: _diagnosisController,
                    validator: _validateDiagnosis,
                    maxLines: 3,
                  ),
                ),
                SizedBox(height: 4.h),
                Align(
                  alignment: AlignmentGeometry.centerRight,
                  child: SimiBoldTitle(title: 'جنس الطفل', fontSize: 12),
                ),

                Padding(
                  padding: EdgeInsets.only(top: 10.0.r),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end, // RTL for Arabic
                    children: [
                      _buildRadioOption(
                        label: 'بنت',
                        value: 'female',
                        isSelected: selectedGender == 'female',
                      ),
                      SizedBox(width: 40.w),
                      _buildRadioOption(
                        label: 'ولد',
                        value: 'male',
                        isSelected: selectedGender == 'male',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),

                Align(
                  alignment: AlignmentGeometry.centerRight,
                  child: SimiBoldTitle(
                    title: 'معلومات إضافية (اختياري)',
                    fontSize: 12,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 4.0.r, top: 8.0.r),
                  child: CustomTextField(
                    hint: 'اكتب أي معلومات مهمة عن طفلك',
                    prefixIcon: Healthicons.i_note_action,
                    height: 50,
                    controller: _additionalInfoController,
                    maxLines: 3,
                  ),
                ),
                SizedBox(height: 12.h),
                CustomElevatedButton(
                  title: 'متابعة',
                  isLoading: _isLoading,
                  onPressed: _handleContinue,
                  width: 165,
                  height: 40,
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRadioOption({
    required String label,
    required String value,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedGender = value;
        });
      },
      child: Row(
        textDirection: TextDirection.rtl, // RTL for Arabic text
        children: [
          Container(
            width: 17.w,
            height: 17.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryColor, width: 2),
              color: isSelected ? AppColors.primaryColor : Colors.transparent,
            ),
            child: isSelected
                ? Iconify(Ci.check, size: 16.sp, color: Colors.white)
                : null,
          ),
          SizedBox(width: 8.w),
          SimiBoldTitle(title: label, fontSize: 12),
        ],
      ),
    );
  }
}
