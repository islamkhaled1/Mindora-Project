import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_text_styles.dart';
import 'package:sawa/constants.dart';
import 'package:sawa/core/state/auth_state.dart';
import 'package:sawa/screens/change_password_screen.dart';
import 'package:sawa/screens/log_in_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isSoundEnabled = true;
  bool _isNotificationsEnabled = true;

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          'اختيار اللغة',
          style: AppTextStyles.font700Bold.copyWith(
            fontSize: 16.sp,
            color: AppColors.primaryColor,
          ),
          textDirection: TextDirection.rtl,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('العربية (الافتراضية)', textDirection: TextDirection.rtl),
              leading: const Icon(Icons.check_circle_rounded, color: AppColors.secondaryTextColor),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('English (قريباً)', textDirection: TextDirection.rtl),
              leading: const Icon(Icons.radio_button_unchecked_rounded),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('اللغة الإنجليزية ستتوفر في التحديث القادم.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          'الأمان والخصوصية',
          style: AppTextStyles.font700Bold.copyWith(
            fontSize: 16.sp,
            color: AppColors.primaryColor,
          ),
          textDirection: TextDirection.rtl,
        ),
        content: Text(
          'تلتزم منصة سوا بأعلى معايير حماية وخصوصية بيانات الأطفال وأولياء الأمور. جميع البيانات والتقييمات والجلسات مشفرة ومحمية وفق المعايير السريرية والتقنية المعمول بها.',
          style: AppTextStyles.font400Regular.copyWith(
            fontSize: 13.sp,
            color: AppColors.primaryColor,
            height: 1.5,
          ),
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          'حول تطبيق سوا | SAWA',
          style: AppTextStyles.font700Bold.copyWith(
            fontSize: 16.sp,
            color: AppColors.primaryColor,
          ),
          textDirection: TextDirection.rtl,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          textDirection: TextDirection.rtl,
          children: [
            Text(
              'منصة سوا للتأهيل النمائي الذكي للأطفال',
              style: AppTextStyles.font600SimiBold.copyWith(
                fontSize: 13.sp,
                color: AppColors.primaryColor,
              ),
              textDirection: TextDirection.rtl,
            ),
            SizedBox(height: 6.h),
            Text(
              'الإصدار: 1.0.0 (Release Candidate)\nتطوير مدعوم بالذكاء الاصطناعي السريري لتتبع وتأهيل الحركة والانتباه والتواصل للأطفال.',
              style: AppTextStyles.font400Regular.copyWith(
                fontSize: 12.sp,
                color: AppColors.secondaryColor,
                height: 1.5,
              ),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إغلاق',
              style: AppTextStyles.font600SimiBold.copyWith(
                color: AppColors.secondaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
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
          'هل أنت متأكد من رغبتك في تسجيل الخروج من التطبيق؟',
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

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? titleColor,
    Color? iconColor,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.circleAvatarColor.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  width: 44.r,
                  height: 44.r,
                  decoration: BoxDecoration(
                    color: (iconColor ?? AppColors.secondaryTextColor).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(
                    icon,
                    size: 22.r,
                    color: iconColor ?? AppColors.secondaryTextColor,
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
                          color: titleColor ?? AppColors.primaryColor,
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
                trailing ??
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
    );
  }

  @override
  Widget build(BuildContext context) {
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
        title: Column(
          children: [
            Text(
              'الإعدادات',
              style: AppTextStyles.font700Bold.copyWith(
                fontSize: 18.sp,
                color: AppColors.primaryColor,
              ),
            ),
            Text(
              'تخصيص التطبيق والإشعارات',
              style: AppTextStyles.font400Regular.copyWith(
                fontSize: 11.sp,
                color: AppColors.secondaryColor,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          children: [
            _buildSettingTile(
              icon: Icons.language_rounded,
              title: 'اللغة',
              subtitle: 'تحويل من لغة إلى أخرى (العربية)',
              onTap: _showLanguageDialog,
            ),
            _buildSettingTile(
              icon: Icons.nightlight_round,
              title: 'الوضع الليلي',
              subtitle: 'معطل',
              trailing: Switch.adaptive(
                value: false,
                activeColor: AppColors.secondaryTextColor,
                onChanged: (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('الوضع الداكن متاح في التحديث القادم.'),
                    ),
                  );
                },
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('الوضع الداكن متاح في التحديث القادم.'),
                  ),
                );
              },
            ),
            _buildSettingTile(
              icon: Icons.volume_up_rounded,
              title: 'الصوت والمؤثرات',
              subtitle: _isSoundEnabled ? 'مفعل للألعاب والتمارين' : 'صامت',
              trailing: Switch.adaptive(
                value: _isSoundEnabled,
                activeColor: AppColors.secondaryTextColor,
                onChanged: (val) => setState(() => _isSoundEnabled = val),
              ),
              onTap: () => setState(() => _isSoundEnabled = !_isSoundEnabled),
            ),
            _buildSettingTile(
              icon: Icons.notifications_active_rounded,
              title: 'الإشعارات',
              subtitle: _isNotificationsEnabled ? 'تلقي التنبيهات والتحديثات' : 'معطلة',
              trailing: Switch.adaptive(
                value: _isNotificationsEnabled,
                activeColor: AppColors.secondaryTextColor,
                onChanged: (val) => setState(() => _isNotificationsEnabled = val),
              ),
              onTap: () => setState(() => _isNotificationsEnabled = !_isNotificationsEnabled),
            ),
            _buildSettingTile(
              icon: Icons.security_rounded,
              title: 'الأمان والخصوصية',
              subtitle: 'إدارة الحماية وتشفير البيانات',
              onTap: _showPrivacyDialog,
            ),
            _buildSettingTile(
              icon: Icons.lock_reset_rounded,
              title: 'تغيير كلمة المرور',
              subtitle: 'تحديث كلمة المرور الحالية لحسابك',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                );
              },
            ),
            _buildSettingTile(
              icon: Icons.info_outline_rounded,
              title: 'حول التطبيق',
              subtitle: 'معلومات المنصة والإصدار',
              onTap: _showAboutDialog,
            ),
            SizedBox(height: 8.h),
            _buildSettingTile(
              icon: Icons.logout_rounded,
              title: 'تسجيل خروج',
              subtitle: 'الخروج من الحساب الحالي',
              titleColor: Colors.redAccent,
              iconColor: Colors.redAccent,
              onTap: _handleLogout,
            ),
          ],
        ),
      ),
    );
  }
}
