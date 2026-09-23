import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_text_styles.dart';
import 'package:sawa/constants.dart';
import 'package:sawa/core/models/child_enums.dart';
import 'package:sawa/core/models/child_model.dart';
import 'package:sawa/core/services/children_service.dart';
import 'package:sawa/core/storage/secure_storage_service.dart';
import 'package:sawa/core/utils/child_avatar_helper.dart';

/// View-only screen for a child's profile data.
///
/// Editing is intentionally disabled until PUT /api/children/{id} is
/// implemented in the backend. The "تعديل البيانات" button shows a transparent
/// bottom sheet rather than entering a fake edit mode.
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
  String? _errorMessage;
  ChildModel? _child;

  // Used only for avatar display — synced from _child.gender.
  String _selectedGender = 'Male';

  @override
  void initState() {
    super.initState();
    _child = widget.initialChild;
    _syncDisplayState();
    if (_child == null) {
      _loadChildData();
    }
  }

  void _syncDisplayState() {
    _selectedGender = _child?.gender ?? 'Male';
  }

  // ─── Backend mapping helpers ───────────────────────────────────────────────

  /// Converts backend SupportLevel ('Mild'/'Moderate'/'High') to Arabic label.
  String _supportLevelArabic(String? raw) {
    if (raw == null) return '';
    final lower = raw.trim().toLowerCase();
    if (lower == 'mild')     return SupportLevelTier.mild.arabicLabel;
    if (lower == 'moderate') return SupportLevelTier.moderate.arabicLabel;
    if (lower == 'high')     return SupportLevelTier.high.arabicLabel;
    return raw; // fall back to raw if unknown
  }

  // ─── Data loading ──────────────────────────────────────────────────────────

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
          _syncDisplayState();
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

  // ─── UI helpers ───────────────────────────────────────────────────────────

  /// Shows a transparent "coming soon" bottom sheet when the user taps
  /// "تعديل البيانات". No false edit mode is entered.
  void _showEditComingSoon() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 32.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.circleAvatarColor,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              SizedBox(height: 20.h),
              Container(
                width: 60.r,
                height: 60.r,
                decoration: BoxDecoration(
                  color: AppColors.secondaryTextColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit_off_outlined,
                  size: 28.r,
                  color: AppColors.secondaryTextColor,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'التعديل غير متاح حالياً',
                style: AppTextStyles.font700Bold.copyWith(
                  fontSize: 17.sp,
                  color: AppColors.primaryColor,
                ),
                textDirection: TextDirection.rtl,
              ),
              SizedBox(height: 10.h),
              Text(
                'بيانات طفلك محفوظة بدقة كما تم تسجيلها.\nإمكانية التعديل ستكون متاحة في التحديث القادم.',
                style: AppTextStyles.font400Regular.copyWith(
                  fontSize: 13.sp,
                  color: AppColors.secondaryColor,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryTextColor,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'حسناً، فهمت',
                    style: AppTextStyles.font600SimiBold.copyWith(
                      fontSize: 14.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// A read-only info card for a single profile field.
  Widget _buildFieldCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final hasValue = value.isNotEmpty;
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
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                  color: AppColors.circleAvatarColor.withValues(alpha: 0.7)),
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
                Icon(icon, size: 20.r, color: AppColors.primaryColor),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    hasValue ? value : 'غير محدد',
                    style: AppTextStyles.font400Regular.copyWith(
                      fontSize: 13.sp,
                      color: hasValue
                          ? AppColors.primaryColor
                          : AppColors.secondaryColor,
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

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final genderArabic =
        (_child?.gender?.toLowerCase() == 'female' || _selectedGender == 'Female')
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
          'بيانات الطفل',
          style: AppTextStyles.font700Bold.copyWith(
            fontSize: 18.sp,
            color: AppColors.primaryColor,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                    color: AppColors.secondaryTextColor))
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.r),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline_rounded,
                              size: 48.r, color: Colors.redAccent),
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
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r)),
                            ),
                            child: const Text('إعادة المحاولة',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: EdgeInsets.symmetric(
                        horizontal: 20.w, vertical: 12.h),
                    children: [
                      // ── Avatar ─────────────────────────────────────────
                      Center(
                        child: Stack(
                          alignment: Alignment.bottomLeft,
                          children: [
                            Container(
                              width: 105.r,
                              height: 105.r,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.circleAvatarColor
                                    .withValues(alpha: 0.5),
                                border:
                                    Border.all(color: Colors.white, width: 3.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryColor
                                        .withValues(alpha: 0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Builder(
                                  builder: (context) {
                                    final resolvedAvatar =
                                        ChildAvatarHelper.resolve(
                                      gender: _selectedGender,
                                      avatarUrl: _child?.avatarUrl,
                                    );
                                    final isNetwork =
                                        ChildAvatarHelper.isNetworkUrl(
                                            resolvedAvatar);
                                    if (isNetwork) {
                                      return Image.network(
                                        resolvedAvatar,
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, e, st) =>
                                            Image.asset(
                                          ChildAvatarHelper.resolve(
                                              gender: _selectedGender),
                                          fit: BoxFit.cover,
                                        ),
                                      );
                                    }
                                    return Image.asset(
                                      resolvedAvatar,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, e, st) => Icon(
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
                                border:
                                    Border.all(color: Colors.white, width: 2.r),
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

                      // ── Profile fields (view-only) ──────────────────────
                      _buildFieldCard(
                        label: 'اسم الطفل بالكامل',
                        value: _child?.fullName ?? '',
                        icon: Icons.person_rounded,
                      ),
                      _buildFieldCard(
                        label: 'تاريخ الميلاد',
                        value: _child?.dateOfBirth != null
                            ? _child!.dateOfBirth!
                                .toIso8601String()
                                .split('T')
                                .first
                            : '',
                        icon: Icons.cake_rounded,
                      ),
                      _buildFieldCard(
                        label: 'الحالة التشخيصية',
                        // ✅ No fake default — null → 'غير محدد'
                        value: _child?.diagnosis ?? '',
                        icon: Icons.medical_services_rounded,
                      ),
                      _buildFieldCard(
                        label: 'الجنس',
                        value: genderArabic,
                        icon: Icons.wc_rounded,
                      ),
                      _buildFieldCard(
                        label: 'مستوى الدعم المطلوب',
                        // ✅ Maps 'Mild'/'Moderate'/'High' → بسيط/متوسط/عالي
                        value: _supportLevelArabic(_child?.supportLevel),
                        icon: Icons.favorite_rounded,
                      ),
                      _buildFieldCard(
                        label: 'أفضل وقت للممارسة',
                        value: _child?.preferredPracticeTime ?? '',
                        icon: Icons.schedule_rounded,
                      ),
                      _buildFieldCard(
                        label: 'وقت تركيز الطفل',
                        value: _child?.focusDurationMinutes != null
                            ? '${_child!.focusDurationMinutes} دقيقة'
                            : '',
                        icon: Icons.timer_outlined,
                      ),
                      _buildFieldCard(
                        label: 'ملاحظات صحية',
                        value: _child?.supportNotes ?? '',
                        icon: Icons.edit_note_rounded,
                      ),

                      SizedBox(height: 16.h),

                      // ── Edit button ─────────────────────────────────────
                      // TODO(backend): Replace with actual edit flow once
                      // PUT /api/children/{id} is available.
                      OutlinedButton.icon(
                        onPressed: _showEditComingSoon,
                        icon: Icon(
                          Icons.edit_outlined,
                          size: 18.r,
                          color: AppColors.secondaryTextColor,
                        ),
                        label: Text(
                          'تعديل البيانات',
                          style: AppTextStyles.font600SimiBold.copyWith(
                            fontSize: 14.sp,
                            color: AppColors.secondaryTextColor,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 13.h),
                          side: BorderSide(
                            color: AppColors.secondaryTextColor
                                .withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18.r),
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
