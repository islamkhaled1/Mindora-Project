import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_text_styles.dart';
import 'package:sawa/constants.dart';
import 'package:sawa/core/models/child_model.dart';
import 'package:sawa/core/services/children_service.dart';
import 'package:sawa/core/state/auth_state.dart';
import 'package:sawa/core/storage/secure_storage_service.dart';
import 'package:sawa/core/utils/child_avatar_helper.dart';
import 'package:sawa/screens/child_data_screen.dart';
import 'package:sawa/screens/log_in_screen.dart';
import 'package:sawa/screens/progress_screen.dart';
import 'package:sawa/screens/settings_screen.dart';
import 'package:sawa/screens/treatment_plan_screen.dart';

class ProfileScreen extends StatefulWidget {
  final ChildModel? initialChild;
  final bool showBackButton;

  const ProfileScreen({
    super.key,
    this.initialChild,
    this.showBackButton = true,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ChildrenService _childrenService = ChildrenService();
  final SecureStorageService _storage = SecureStorageService();

  bool _isLoading = true;
  ChildModel? _child;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialChild != null) {
      _child = widget.initialChild;
      _isLoading = false;
    } else {
      _loadProfileData();
    }
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final childId = await _storage.getActiveChildId();
      if (childId == null || childId.isEmpty) {
        setState(() {
          _errorMessage = 'لم يتم تحديد طفل حالي.';
          _isLoading = false;
        });
        return;
      }

      final child = await _childrenService.getChildById(childId);
      if (mounted) {
        setState(() {
          _child = child;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'تعذر تحميل الملف الشخصي: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          'تسجيل الخروج',
          style: AppTextStyles.font700Bold.copyWith(
            fontSize: 16.sp,
            color: AppColors.primaryColor,
          ),
          textDirection: TextDirection.rtl,
        ),
        content: Text(
          'هل تريد بالتأكيد تسجيل الخروج من الحساب؟',
          style: AppTextStyles.font400Regular.copyWith(
            fontSize: 13.sp,
            color: AppColors.primaryColor,
          ),
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'إلغاء',
              style: AppTextStyles.font600SimiBold.copyWith(
                color: AppColors.secondaryColor,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'تسجيل خروج',
              style: AppTextStyles.font700Bold.copyWith(
                color: Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await AuthState.instance.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LogInScreen()),
          (route) => false,
        );
      }
    }
  }

  Widget _buildMenuItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16.r),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Container(
                    width: 44.r,
                    height: 44.r,
                    decoration: BoxDecoration(
                      color: AppColors.circleAvatarColor.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.primaryColor,
                      size: 22.r,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      textDirection: TextDirection.rtl,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.font700Bold.copyWith(
                            fontSize: 14.sp,
                            color: AppColors.primaryColor,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          subtitle,
                          style: AppTextStyles.font400Regular.copyWith(
                            fontSize: 11.sp,
                            color: AppColors.secondaryColor,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16.r,
                    color: AppColors.secondaryColor.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 0.8,
            indent: 16.w,
            endIndent: 16.w,
            color: AppColors.circleAvatarColor.withValues(alpha: 0.6),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final genderArabic = (_child?.gender?.toLowerCase() == 'female') ? 'أنثى' : 'ذكر';
    final ageText = _child != null
        ? (_child!.age != null ? '${_child!.age} سنوات • $genderArabic' : genderArabic)
        : '';

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: (widget.showBackButton && Navigator.canPop(context))
            ? Container(
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
              )
            : null,
        title: Text(
          'الملف الشخصي',
          style: AppTextStyles.font700Bold.copyWith(
            fontSize: 18.sp,
            color: AppColors.primaryColor,
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.circleAvatarColor),
            ),
            child: IconButton(
              icon: Icon(
                Icons.settings_rounded,
                size: 20.r,
                color: AppColors.primaryColor,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
          ),
          Container(
            margin: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.circleAvatarColor),
            ),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.notifications_outlined,
                    size: 20.r,
                    color: AppColors.primaryColor,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('لا توجد تنبيهات جديدة حالياً.')),
                    );
                  },
                ),
                Positioned(
                  top: 8.r,
                  right: 8.r,
                  child: Container(
                    width: 7.r,
                    height: 7.r,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
                            onPressed: _loadProfileData,
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
                      // Child Avatar
                      Center(
                        child: Stack(
                          alignment: Alignment.bottomLeft,
                          children: [
                            Container(
                              width: 110.r,
                              height: 110.r,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.circleAvatarColor.withValues(alpha: 0.5),
                                border: Border.all(color: Colors.white, width: 3.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryColor.withValues(alpha: 0.08),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Builder(
                                  builder: (context) {
                                    final resolvedAvatar = ChildAvatarHelper.resolve(
                                      gender: _child?.gender,
                                      avatarUrl: _child?.avatarUrl,
                                    );
                                    final isNetwork = ChildAvatarHelper.isNetworkUrl(resolvedAvatar);
                                    if (isNetwork) {
                                      return Image.network(
                                        resolvedAvatar,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Image.asset(
                                          ChildAvatarHelper.resolve(gender: _child?.gender),
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
                              width: 34.r,
                              height: 34.r,
                              decoration: BoxDecoration(
                                color: AppColors.secondaryTextColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.r),
                              ),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                size: 17.r,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 14.h),

                      // Child Name & Age / Gender
                      Text(
                        _child?.fullName ?? 'الطفل',
                        style: AppTextStyles.font700Bold.copyWith(
                          fontSize: 18.sp,
                          color: AppColors.primaryColor,
                        ),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        ageText,
                        style: AppTextStyles.font400Regular.copyWith(
                          fontSize: 12.sp,
                          color: AppColors.secondaryColor,
                        ),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                      ),
                      SizedBox(height: 24.h),

                      // Grouped Menu Card matching profile.png
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24.r),
                          border: Border.all(color: AppColors.circleAvatarColor.withValues(alpha: 0.7)),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryColor.withValues(alpha: 0.03),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildMenuItem(
                              title: 'بيانات الطفل',
                              subtitle: 'معلومات وبيانات الطفل',
                              icon: Icons.person_rounded,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChildDataScreen(initialChild: _child),
                                  ),
                                );
                              },
                            ),
                            _buildMenuItem(
                              title: 'هدف الطفل',
                              subtitle: 'الأهداف والتقدم',
                              icon: Icons.track_changes_rounded,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ProgressScreen(showBackButton: true),
                                  ),
                                );
                              },
                            ),
                            _buildMenuItem(
                              title: 'خطة الأنشطة المنزلية',
                              subtitle: 'التطور خطوة بخطوة',
                              icon: Icons.assignment_turned_in_rounded,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const TreatmentPlanScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildMenuItem(
                              title: 'التقدم',
                              subtitle: 'متابعة الجلسات والتطور',
                              icon: Icons.bar_chart_rounded,
                              isLast: true,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ProgressScreen(showBackButton: true),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // Settings & Logout quick card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: AppColors.circleAvatarColor.withValues(alpha: 0.7)),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20.r),
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                                trailing: const Icon(Icons.settings_outlined, color: AppColors.secondaryTextColor),
                                title: Text(
                                  'الإعدادات العامة',
                                  style: AppTextStyles.font600SimiBold.copyWith(
                                    fontSize: 13.sp,
                                    color: AppColors.primaryColor,
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                                  );
                                },
                              ),
                              Divider(height: 1, indent: 16.w, endIndent: 16.w, color: AppColors.circleAvatarColor),
                              ListTile(
                                leading: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.redAccent),
                                trailing: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                                title: Text(
                                  'تسجيل الخروج',
                                  style: AppTextStyles.font600SimiBold.copyWith(
                                    fontSize: 13.sp,
                                    color: Colors.redAccent,
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                                onTap: _handleLogout,
                              ),
                            ],
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
