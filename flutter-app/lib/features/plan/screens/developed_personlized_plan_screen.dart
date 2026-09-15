import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:sawa/core/constants/app_colors.dart';
import 'package:sawa/core/constants/app_icons.dart';
import 'package:sawa/core/widgets/buttons/custom_elevated_button.dart';
import 'package:sawa/core/widgets/common/custom_container.dart';
import 'package:sawa/core/widgets/common/custom_padding.dart';
import 'package:sawa/core/widgets/common/custom_title.dart';
import 'package:sawa/core/widgets/common/description.dart';
import 'package:sawa/core/widgets/common/simi_bold_title.dart';
import 'package:sawa/core/widgets/navigation/back_icon.dart';
import 'package:sawa/core/widgets/navigation/custom_app_bar.dart';
import 'package:sawa/features/home/screens/home_nav_screen.dart';

class DevelopedPersonlizedPlan extends StatelessWidget {
  const DevelopedPersonlizedPlan({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: CustomAppBar(leading: BackIcon()),
      body: CustomPadding(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 80.h),
              SizedBox(
                width: double.infinity,
                height: 150.h,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // الصورة
                    Positioned(
                      top: -130.h,
                      left: 0,
                      right: 0,

                      child: Center(
                        child: Image.asset(
                          'assets/images/thirdBot.png',
                          width: 220.w,
                          height: 190.h,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    Center(
                      child: Container(
                        height: 120.h,
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 18.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomTitle(
                              title: 'تم إنشاء خطة علاجية مخصصة لطفلك',
                              fontSize: 16,
                            ),
                            SizedBox(height: 8.h),
                            Description(
                              text:
                                  'تم تصميم هذه الخطة بناءً على نتائج التقييم\n لتناسب احتياجاتة طفلك ومساعدته على التطور خطوة بخطوة.',
                              fontSize: 12,
                              color: AppColors.primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              CustomTitle(title: 'ماذا سيحدث الآن؟', fontSize: 18),
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildItem(
                    icon: AppIcons.plan,
                    title: 'خطة جاهزة',
                    description: 'تم إنشاء خطة علاجية مخصصة لطفلك.',
                  ),
                  SizedBox(width: 8.w),
                  _buildItem(
                    icon: AppIcons.trending,
                    title: 'تابع التقدم',
                    description: 'تابع تقدم \nطفلك \nالموصى \nبها.',
                  ),
                  SizedBox(width: 8.w),
                  _buildItem(
                    icon: AppIcons.persons,
                    title: 'ابدأ الأنشطة',
                    description: 'ابدأ الأنشطة اليومية مخصصة لطفلك.',
                  ),
                  SizedBox(width: 8.w),
                  _buildItem(
                    icon: AppIcons.flag,
                    title: 'تحقيق الأهداف',
                    description: 'نحتفل معًا بكل إنجاز\n أسبوعيًا.',
                  ),
                ],
              ),
              SizedBox(height: 32.h),
              CustomContainer(
                width: double.infinity,
                height: 80.h,
                color: Color(0xffF1E8FF),
                child: Column(
                  children: [
                    SimiBoldTitle(title: 'أنت لست وحدك', fontSize: 14),
                    SizedBox(height: 10.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Description(
                          text:
                              'نحن هنا لدعمك في كل خطوة من رحلتك مع طفلك\nمع الاستمرارية والمحبة، يمكن لطفلك تحقيق الكثير.',
                          fontSize: 11,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Iconify(
                            AppIcons.heart,
                            size: 25,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),
              CustomElevatedButton(
                width: 200.w,
                title: 'ابدأ رحلتنا معاً',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomeNavScreen(initialIndex: 1),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildItem({
  required String icon,
  required String title,
  required String description,
}) {
  return Expanded(
    child: Column(
      children: [
        Container(
          width: 40.w,
          height: 40.h,
          decoration: BoxDecoration(
            color: Color(0xFFF3EFFF),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primaryColor, width: 2),
          ),
          child: CircleAvatar(
            backgroundColor: Colors.white,

            child: Iconify(icon, color: AppColors.primaryColor),
          ),
        ),
        SizedBox(height: 10.h),
        SimiBoldTitle(title: title, fontSize: 12),
        SizedBox(height: 4.h),
        Description(text: description, fontSize: 10.5),
      ],
    ),
  );
}
