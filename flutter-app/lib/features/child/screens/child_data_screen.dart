import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:sawa/core/constants/app_colors.dart';
import 'package:sawa/core/constants/app_icons.dart';
import 'package:sawa/core/widgets/buttons/custom_elevated_button.dart';
import 'package:sawa/core/widgets/common/custom_padding.dart';
import 'package:sawa/core/widgets/common/custom_title.dart';
import 'package:sawa/core/widgets/common/simi_bold_title.dart';
import 'package:sawa/core/widgets/icons/image_circle_avatar.dart';
import 'package:sawa/core/widgets/navigation/back_icon.dart';
import 'package:sawa/core/widgets/navigation/custom_app_bar.dart';
import 'package:sawa/core/widgets/text_fields/custom_text_field.dart';
import 'package:sawa/core/widgets/text_fields/cutom_date_field.dart';

class ChildDataScreen extends StatefulWidget {
  const ChildDataScreen({super.key});

  @override
  State<ChildDataScreen> createState() => _ChildDataScreenState();
}

class _ChildDataScreenState extends State<ChildDataScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  bool _isSaving = false;

  // TODO: replace with real child data (from API / state management)
  final String childImage = 'assets/images/kid_image.png';

  late final TextEditingController _nameController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _diagnosisController;
  late final TextEditingController _supportLevelController;
  late final TextEditingController _healthNotesController;
  String _gender = 'male';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'عمر أحمد محمد');
    _birthDateController = TextEditingController(text: '20 مارس 2020');
    _diagnosisController = TextEditingController(text: 'متلازمة داون');
    _supportLevelController = TextEditingController(text: 'دعم متوسط');
    _healthNotesController = TextEditingController(text: 'لا توجد ملاحظات');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    _diagnosisController.dispose();
    _supportLevelController.dispose();
    _healthNotesController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value) {
    if (!_isEditing) return null;
    if (value == null || value.trim().isEmpty) {
      return 'هذا الحقل مطلوب';
    }
    return null;
  }

  Future<void> _onButtonPressed() async {
    if (!_isEditing) {
      setState(() => _isEditing = true);
      return;
    }

    // Currently editing -> validate & save.
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      // TODO: call API to persist the updated child data.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() {
        _isEditing = false;
        _isSaving = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حفظ التغييرات بنجاح')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        leading: BackIcon(),
        title: CustomTitle(
          title: _isEditing ? 'تعديل بيانات الطفل' : 'بيانات الطفل',
          fontSize: 24,
        ),
      ),
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: CustomPadding(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(height: 16.h),
                  ImageCircleAvatar(image: childImage, radius: 60.r),
                  SizedBox(height: 28.h),

                  _fieldLabel('اسم الطفل بالكامل'),
                  Padding(
                    padding: EdgeInsets.only(bottom: 4.0.r, top: 8.0.r),
                    child: CustomTextField(
                      hint: 'أدخل اسم الطفل',
                      prefixIcon: Mdi.account,
                      height: 50,
                      isEnabled: _isEditing,
                      controller: _nameController,
                      validator: _requiredValidator,
                    ),
                  ),

                  _fieldLabel('تاريخ الميلاد'),
                  Padding(
                    padding: EdgeInsets.only(bottom: 4.0.r, top: 8.0.r),
                    child: _isEditing
                        ? CustomDateField(
                            hint: 'اختر تاريخ الميلاد',
                            prefixIcon: Iconify(
                              AppIcons.cake,
                              color: AppColors.primaryColor,
                            ),
                            height: 50,
                            controller: _birthDateController,
                            validator: _requiredValidator,
                          )
                        : CustomTextField(
                            hint: 'أدخل تاريخ الميلاد',
                            prefixIcon: AppIcons.cake,
                            height: 50,
                            isEnabled: false,
                            controller: _birthDateController,
                          ),
                  ),

                  // Gender: read-only text field in view mode,
                  // radio buttons in edit mode (matches the design).
                  _fieldLabel(_isEditing ? 'جنس الطفل' : 'الجنس'),
                  Padding(
                    padding: EdgeInsets.only(bottom: 4.0.r, top: 8.0.r),
                    child: _isEditing
                        ? Align(
                            alignment: AlignmentGeometry.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildRadioOption(
                                  label: 'بنت',
                                  value: 'female',
                                  isSelected: _gender == 'female',
                                ),
                                SizedBox(width: 40.w),
                                _buildRadioOption(
                                  label: 'ولد',
                                  value: 'male',
                                  isSelected: _gender == 'male',
                                ),
                              ],
                            ),
                          )
                        : CustomTextField(
                            hint: _gender == 'male' ? 'ذكر' : 'أنثى',
                            prefixIcon: _gender == 'male'
                                ? AppIcons.genderMale
                                : AppIcons.genderFemale,
                            height: 50,
                            isEnabled: false,
                          ),
                  ),

                  _fieldLabel('الحالة التشخيصية'),
                  Padding(
                    padding: EdgeInsets.only(bottom: 4.0.r, top: 8.0.r),
                    child: CustomTextField(
                      hint: 'اكتب الحالة',
                      prefixIcon: AppIcons.scope,
                      height: 50,
                      isEnabled: _isEditing,
                      controller: _diagnosisController,
                      validator: _requiredValidator,
                    ),
                  ),

                  _fieldLabel('مستوى الدعم المطلوب'),
                  Padding(
                    padding: EdgeInsets.only(bottom: 4.0.r, top: 8.0.r),
                    child: CustomTextField(
                      hint: 'درجة الدعم',
                      prefixIcon: AppIcons.heart,
                      height: 50,
                      isEnabled: _isEditing,
                      controller: _supportLevelController,
                    ),
                  ),

                  _fieldLabel('ملاحظات صحية'),
                  Padding(
                    padding: EdgeInsets.only(bottom: 4.0.r, top: 8.0.r),
                    child: CustomTextField(
                      hint: 'اكتب أي ملاحظات صحية',
                      prefixIcon: AppIcons.notes,
                      height: 50,
                      isEnabled: _isEditing,
                      controller: _healthNotesController,
                      maxLines: 3,
                    ),
                  ),

                  SizedBox(height: 24.h),
                  CustomElevatedButton(
                    title: _isEditing ? 'حفظ التغييرات' : 'تعديل البيانات',
                    isLoading: _isSaving,
                    onPressed: _onButtonPressed,
                    width: 200,
                    height: 44,
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Align(
      alignment: AlignmentGeometry.centerRight,
      child: SimiBoldTitle(title: label, fontSize: 12),
    );
  }

  Widget _buildRadioOption({
    required String label,
    required String value,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 18.w,
            height: 18.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryColor, width: 2),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 9.w,
                      height: 9.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  )
                : null,
          ),
          SizedBox(width: 8.w),
          SimiBoldTitle(title: label, fontSize: 12),
        ],
      ),
    );
  }
}
