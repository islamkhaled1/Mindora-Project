import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/core/constants/app_colors.dart';
import 'package:sawa/core/constants/app_icons.dart';
import 'package:sawa/core/widgets/common/custom_padding.dart';
import 'package:sawa/core/widgets/common/custom_title.dart';
import 'package:sawa/core/widgets/common/medium_title.dart';
import 'package:sawa/core/widgets/common/notification_leading.dart';
import 'package:sawa/core/widgets/common/simi_bold_title.dart';
import 'package:sawa/core/widgets/icons/image_circle_avatar.dart';
import 'package:sawa/core/widgets/navigation/custom_app_bar.dart';
import 'package:sawa/features/child/screens/child_data_screen.dart';
import 'package:sawa/features/home/screens/home_nav_screen.dart';
import 'package:sawa/features/profile/widgets/custom_settings_icon.dart';
import 'package:sawa/features/profile/widgets/profile_list_tile.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  final String kidImage = 'assets/images/kid_image.png';
  final String kidName = 'عمر';
  final int age = 4;
  final String gender = 'ذكر';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: CustomAppBar(
        height: 60,
        leadingWidth: 60.w,
        leading: CustomSettingsIcon(),
        title: CustomTitle(title: 'الملف الشخصي', fontSize: 24),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: NotificationLeading(),
          ),
        ],
      ),
      body: CustomPadding(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(right: 14.0.r),
                child: Center(
                  child: ImageCircleAvatar(radius: 100, image: kidImage),
                ),
              ),
              Center(child: SimiBoldTitle(title: kidName, fontSize: 20)),
              Center(
                child: MediumTitle(
                  title: '${age} سنوات   •  ${gender}',
                  fontSize: 20,
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppColors.dividerColor, width: 0.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ProfileListTile(
                      title: 'بيانات الطفل',
                      description: 'معلومات وبيانات الطفل',
                      icon: AppIcons.user,
                      targetScreen: ChildDataScreen(),
                    ),
                    Divider(),
                    ProfileListTile(
                      title: 'هدف الطفل',
                      description: 'الأهداف والتقدم',
                      icon: AppIcons.target,
                      targetScreen: HomeNavScreen(),
                    ),
                    Divider(),
                    ProfileListTile(
                      title: 'الخطة العلاجية',
                      description: ' التطور خطوة بخطوة',
                      icon: AppIcons.task,
                      targetScreen: HomeNavScreen(),
                    ),
                    Divider(),
                    ProfileListTile(
                      title: 'التقدم',
                      description: 'متابعة الجلسات والتطور',
                      icon: AppIcons.chart,
                      targetScreen: HomeNavScreen(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
