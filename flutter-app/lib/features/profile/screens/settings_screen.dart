import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/core/constants/app_colors.dart';
import 'package:sawa/core/constants/app_icons.dart';
import 'package:sawa/core/widgets/common/custom_padding.dart';
import 'package:sawa/core/widgets/common/custom_title.dart';
import 'package:sawa/core/widgets/common/description.dart';
import 'package:sawa/core/widgets/navigation/back_icon.dart';
import 'package:sawa/core/widgets/navigation/custom_app_bar.dart';
import 'package:sawa/features/profile/widgets/settings_list_tile.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: CustomAppBar(leading: BackIcon()),
      body: CustomPadding(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Center(child: CustomTitle(title: 'الإعدادات', fontSize: 24)),
              SizedBox(height: 5.h),
              Center(
                child: Description(
                  text: 'تخصيص التطبيق والإشعارات',
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 32.h),
              SettingsListTile(
                title: 'اللغة',
                description: 'تحويل من لغة إلي اخري',
                icon: AppIcons.language,
              ),
              SizedBox(height: 15.h),
              SettingsListTile(
                title: 'الوضع الليلي',
                description: 'تجربه مريحه للعين',
                icon: AppIcons.moon,
              ),
              SizedBox(height: 15.h),
              SettingsListTile(
                title: 'الصوت',
                description: 'مفعل',
                icon: AppIcons.speaker,
              ),
              SizedBox(height: 15.h),
              SettingsListTile(
                title: 'الإشعارات',
                description: 'تلقي التنبيهات والتحديثات',
                icon: AppIcons.notificationfilled,
              ),
              SizedBox(height: 15.h),
              SettingsListTile(
                title: 'الأمان والخصوصية',
                description: 'إدارة كلمة المرور والخصوصية',
                icon: AppIcons.privacy,
              ),
              SizedBox(height: 15.h),
              SettingsListTile(title: 'حول التطبيق', icon: AppIcons.about),
              SizedBox(height: 15.h),
              SettingsListTile(title: 'تسجيل خروج', icon: AppIcons.logout),
            ],
          ),
        ),
      ),
    );
  }
}
