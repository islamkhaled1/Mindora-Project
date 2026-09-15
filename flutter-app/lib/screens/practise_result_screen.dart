import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_colors.dart';
import 'package:sawa/app_icons.dart';
import 'package:sawa/app_text_styles.dart';
import 'package:sawa/screens/home_screen.dart';
import 'package:sawa/widgets/animated_gradient_circular_progress.dart';
import 'package:sawa/widgets/back_icon.dart';
import 'package:sawa/widgets/custom_app_bar.dart';
import 'package:sawa/widgets/custom_elevated_button.dart';
import 'package:sawa/widgets/custom_padding.dart';
import 'package:sawa/widgets/custom_title.dart';
import 'package:sawa/widgets/description.dart';
import 'package:sawa/widgets/icon_container.dart';
import 'package:sawa/widgets/simi_bold_title.dart';

class PractiseResultScreen extends StatelessWidget {
  const PractiseResultScreen({
    super.key,
    this.percent = 85.0,
  });

  final double percent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: CustomAppBar(
        leading: const BackIcon(),
        title: const CustomTitle(title: 'نتائج تمارين اليوم', fontSize: 24),
      ),
      body: CustomPadding(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 5.h),
              const Description(
                text: 'شاطر جدا\nأكملت جميع تمارين اليوم',
                fontSize: 16,
              ),
              SizedBox(height: 32.h),
              Container(
                width: double.infinity,
                height: 250.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    children: [
                      SizedBox(height: 10.h),
                      const SimiBoldTitle(title: 'النتيجة الإجمالية', fontSize: 18),
                      SizedBox(height: 15.h),
                      AnimatedGradientCircularProgress(
                        size: 150.r,
                        percent: percent,
                        strokeWidth: 10.r,
                        labelBuilder: (animatedPercent) => Text(
                          '${animatedPercent.round()}%',
                          style: AppTextStyles.font600SimiBold.copyWith(
                            color: AppColors.primaryColor,
                            fontSize: 32.sp,
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      const SimiBoldTitle(title: 'أداء جيد جداً', fontSize: 14),
                      SizedBox(height: 5.h),
                      const Description(text: 'استمر في هذا التقدم', fontSize: 14),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    children: [
                      const SimiBoldTitle(title: 'تمارين اليوم', fontSize: 20),
                      SizedBox(height: 15.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: const [
                          IconContainer(
                            backGroundColor: AppColors.circleAvatarColor,
                            iconColor: AppColors.primaryColor,
                            icon: AppIcons.message,
                            label: 'التواصل',
                            width: 60,
                            height: 35,
                          ),
                          IconContainer(
                            backGroundColor: AppColors.lightGreen,
                            iconColor: AppColors.darkGreen,
                            icon: AppIcons.brain,
                            label: 'الفهم والإدراك',
                            width: 60,
                            height: 35,
                          ),
                          IconContainer(
                            backGroundColor: AppColors.lightOrange,
                            iconColor: AppColors.dartOrange,
                            icon: AppIcons.running,
                            label: 'الحركة',
                            width: 60,
                            height: 35,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32.h),
              CustomElevatedButton(
                width: 170.w,
                title: 'التالي',
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
                  );
                },
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}
