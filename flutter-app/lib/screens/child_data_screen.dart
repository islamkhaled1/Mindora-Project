import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_text_styles.dart';
import 'package:sawa/constants.dart';
import 'package:sawa/core/models/child_model.dart';
import 'package:sawa/core/services/children_service.dart';
import 'package:sawa/core/storage/secure_storage_service.dart';
import 'package:sawa/core/utils/child_avatar_helper.dart';

class ChildDataScreen extends StatefulWidget {
  final ChildModel? initialChild;

  const ChildDataScreen({super.key, this.initialChild});

  @override
  State<ChildDataScreen> createState() => _ChildDataScreenState();
}

class _ChildDataScreenState extends State<ChildDataScreen> {
  final ChildrenService _childrenService = ChildrenService();
  final SecureStorageService _storage = SecureStorageService();

  bool _isLoading = false;
  bool _isEditing = false;
  String? _errorMessage;
  ChildModel? _child;

  // Controllers for edit mode
  late TextEditingController _nameController;
  late TextEditingController _dobController;
  late TextEditingController _diagnosisController;
  late TextEditingController _supportLevelController;
  late TextEditingController _notesController;
  String _selectedGender = 'Male';

  @override
  void initState() {
    super.initState();
    _child = widget.initialChild;
    _initControllers();
    if (_child == null) {
      _loadChildData();
    }
  }

  void _initControllers() {
    _nameController = TextEditingController(text: _child?.fullName ?? '');
    _dobController = TextEditingController(
      text: _child?.dateOfBirth != null
          ? _child!.dateOfBirth!.toIso8601String().split('T').first
          : '',
    );
    _diagnosisController = TextEditingController(text: _child?.diagnosis ?? 'متلازمة داون');
    _supportLevelController = TextEditingController(text: _child?.supportLevel ?? 'دعم متوسط');
    _notesController = TextEditingController(text: _child?.supportNotes ?? 'لا توجد ملاحظات خاصة');
    _selectedGender = _child?.gender ?? 'Male';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _diagnosisController.dispose();
    _supportLevelController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadChildData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final childId = await _storage.getActiveChildId();
      if (childId == null || childId.isEmpty) {
        setState(() {
          _errorMessage = 'لا يوجد طفل نشط مسجل حالياً.';
          _isLoading = false;
        });
        return;
      }

      final child = await _childrenService.getChildById(childId);
      if (mounted) {
        setState(() {
          _child = child;
          _initControllers();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'تعذر تحميل بيانات الطفل: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _handleSave() {
    // Validate inputs
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال اسم الطفل بالكامل.')),
      );
      return;
    }

    // Transparent notification regarding backend contract without fake persistence
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          textDirection: TextDirection.rtl,
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.secondaryTextColor),
            SizedBox(width: 8.w),
            Text(
              'تنبيه الحفظ',
              style: AppTextStyles.font700Bold.copyWith(
                fontSize: 16.sp,
                color: AppColors.primaryColor,
              ),
            ),
          ],
        ),
        content: Text(
          'خادم النظام لا يوفر حالياً واجهة برمجية لتعديل بيانات الطفل المسجل (Backend API Gap: No PUT /api/children).\n\nبيانات طفلك الحالية محفوظة ومعتمدة بدقة كما تم تسجيلها أول مرة.',
          style: AppTextStyles.font400Regular.copyWith(
            fontSize: 13.sp,
            color: AppColors.primaryColor,
            height: 1.5,
          ),
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isEditing = false;
              });
            },
            child: Text(
              'حسناً',
              style: AppTextStyles.font600SimiBold.copyWith(
                color: AppColors.secondaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldCard({
    required String label,
    required String value,
    required IconData icon,
    Widget? customInput,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: TextDirection.rtl,
        children: [
          Text(
            label,
            style: AppTextStyles.font600SimiBold.copyWith(
              fontSize: 13.sp,
              color: AppColors.primaryColor,
            ),
            textDirection: TextDirection.rtl,
          ),
          SizedBox(height: 6.h),
          if (_isEditing && customInput != null)
            customInput
          else
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.circleAvatarColor.withValues(alpha: 0.7)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Icon(
                    icon,
                    size: 20.r,
                    color: AppColors.primaryColor,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      value.isNotEmpty ? value : 'غير محدد',
                      style: AppTextStyles.font400Regular.copyWith(
                        fontSize: 13.sp,
                        color: AppColors.primaryColor,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required IconData icon,
    String? hintText,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.secondaryTextColor.withValues(alpha: 0.4)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        textDirection: TextDirection.rtl,
        style: AppTextStyles.font500Medium.copyWith(
          fontSize: 13.sp,
          color: AppColors.primaryColor,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintTextDirection: TextDirection.rtl,
          hintStyle: AppTextStyles.font400Regular.copyWith(
            fontSize: 12.sp,
            color: AppColors.secondaryColor.withValues(alpha: 0.7),
          ),
          prefixIcon: Icon(icon, color: AppColors.secondaryTextColor, size: 20.r),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final genderArabic = (_child?.gender?.toLowerCase() == 'female' || _selectedGender == 'Female')
        ? 'أنثى'
        : 'ذكر';

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Container(
          margin: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.circleAvatarColor),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16.r,
              color: AppColors.primaryColor,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          _isEditing ? 'تعديل بيانات الطفل' : 'بيانات الطفل',
          style: AppTextStyles.font700Bold.copyWith(
            fontSize: 18.sp,
            color: AppColors.primaryColor,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.secondaryTextColor))
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.r),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline_rounded, size: 48.r, color: Colors.redAccent),
                          SizedBox(height: 12.h),
                          Text(
                            _errorMessage!,
                            style: AppTextStyles.font500Medium.copyWith(
                              fontSize: 14.sp,
                              color: AppColors.primaryColor,
                            ),
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                          ),
                          SizedBox(height: 16.h),
                          ElevatedButton(
                            onPressed: _loadChildData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondaryTextColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                            ),
                            child: const Text('إعادة المحاولة', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    children: [
                      // Avatar with camera badge
                      Center(
                        child: Stack(
                          alignment: Alignment.bottomLeft,
                          children: [
                            Container(
                              width: 105.r,
                              height: 105.r,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.circleAvatarColor.withValues(alpha: 0.5),
                                border: Border.all(color: Colors.white, width: 3.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryColor.withValues(alpha: 0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Builder(
                                  builder: (context) {
                                    final resolvedAvatar = ChildAvatarHelper.resolve(
                                      gender: _selectedGender,
                                      avatarUrl: _child?.avatarUrl,
                                    );
                                    final isNetwork = ChildAvatarHelper.isNetworkUrl(resolvedAvatar);
                                    if (isNetwork) {
                                      return Image.network(
                                        resolvedAvatar,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Image.asset(
                                          ChildAvatarHelper.resolve(gender: _selectedGender),
                                          fit: BoxFit.cover,
                                        ),
                                      );
                                    }
                                    return Image.asset(
                                      resolvedAvatar,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Icon(
                                        Icons.child_care_rounded,
                                        size: 55.r,
                                        color: AppColors.secondaryTextColor,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Container(
                              width: 32.r,
                              height: 32.r,
                              decoration: BoxDecoration(
                                color: AppColors.secondaryTextColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.r),
                              ),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                size: 16.r,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Full Name
                      _buildFieldCard(
                        label: 'اسم الطفل بالكامل',
                        value: _child?.fullName ?? '',
                        icon: Icons.person_rounded,
                        customInput: _buildTextInput(
                          controller: _nameController,
                          icon: Icons.person_rounded,
                          hintText: 'أدخل اسم الطفل',
                        ),
                      ),

                      // Date of Birth
                      _buildFieldCard(
                        label: 'تاريخ الميلاد',
                        value: _child?.dateOfBirth != null
                            ? _child!.dateOfBirth!.toIso8601String().split('T').first
                            : '',
                        icon: Icons.cake_rounded,
                        customInput: _buildTextInput(
                          controller: _dobController,
                          icon: Icons.cake_rounded,
                          hintText: 'YYYY-MM-DD',
                        ),
                      ),

                      // Diagnosis
                      _buildFieldCard(
                        label: 'الحالة التشخيصية',
                        value: _child?.diagnosis ?? 'متلازمة داون',
                        icon: Icons.medical_services_rounded,
                        customInput: _buildTextInput(
                          controller: _diagnosisController,
                          icon: Icons.medical_services_rounded,
                          hintText: 'التشخيص الطبي',
                        ),
                      ),

                      // Gender Field / Radio
                      if (_isEditing)
                        Container(
                          margin: EdgeInsets.only(bottom: 14.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            textDirection: TextDirection.rtl,
                            children: [
                              Text(
                                'جنس الطفل',
                                style: AppTextStyles.font600SimiBold.copyWith(
                                  fontSize: 13.sp,
                                  color: AppColors.primaryColor,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                              SizedBox(height: 6.h),
                              Row(
                                textDirection: TextDirection.rtl,
                                children: [
                                  Expanded(
                                    child: RadioListTile<String>(
                                      value: 'Male',
                                      groupValue: _selectedGender,
                                      title: const Text('ولد (ذكر)', textDirection: TextDirection.rtl),
                                      activeColor: AppColors.secondaryTextColor,
                                      onChanged: (val) {
                                        if (val != null) setState(() => _selectedGender = val);
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: RadioListTile<String>(
                                      value: 'Female',
                                      groupValue: _selectedGender,
                                      title: const Text('بنت (أنثى)', textDirection: TextDirection.rtl),
                                      activeColor: AppColors.secondaryTextColor,
                                      onChanged: (val) {
                                        if (val != null) setState(() => _selectedGender = val);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      else
                        _buildFieldCard(
                          label: 'الجنس',
                          value: genderArabic,
                          icon: Icons.wc_rounded,
                        ),

                      // Support Level
                      _buildFieldCard(
                        label: 'مستوى الدعم المطلوب',
                        value: _child?.supportLevel ?? 'دعم متوسط',
                        icon: Icons.favorite_rounded,
                        customInput: _buildTextInput(
                          controller: _supportLevelController,
                          icon: Icons.favorite_rounded,
                          hintText: 'مستوى الدعم المطلوب',
                        ),
                      ),

                      // Health Notes
                      _buildFieldCard(
                        label: 'ملاحظات صحية',
                        value: _child?.supportNotes ?? 'لا توجد ملاحظات',
                        icon: Icons.edit_note_rounded,
                        customInput: _buildTextInput(
                          controller: _notesController,
                          icon: Icons.edit_note_rounded,
                          hintText: 'اكتب أي ملاحظات صحية أو نمائية',
                          maxLines: 3,
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // Action Button (تعديل البيانات or حفظ التغييرات)
                      ElevatedButton(
                        onPressed: () {
                          if (_isEditing) {
                            _handleSave();
                          } else {
                            setState(() {
                              _isEditing = true;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryTextColor,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18.r),
                          ),
                          elevation: 1,
                        ),
                        child: Text(
                          _isEditing ? 'حفظ التغييرات' : 'تعديل البيانات',
                          style: AppTextStyles.font700Bold.copyWith(
                            fontSize: 15.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                    ],
                  ),
      ),
    );
  }
}
