import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/core/constants/app_colors.dart';
import 'package:sawa/core/constants/app_icons.dart';
import 'package:sawa/core/constants/app_text_styles.dart';
import 'package:sawa/core/widgets/buttons/custom_elevated_button.dart';
import 'package:sawa/core/widgets/common/animated_gradient_circular_progress.dart';
import 'package:sawa/core/widgets/common/custom_padding.dart';
import 'package:sawa/core/widgets/common/custom_title.dart';
import 'package:sawa/core/widgets/common/description.dart';
import 'package:sawa/core/widgets/common/simi_bold_title.dart';
import 'package:sawa/core/widgets/icons/icon_container.dart';
import 'package:sawa/core/widgets/navigation/back_icon.dart';
import 'package:sawa/core/widgets/navigation/custom_app_bar.dart';
import 'package:sawa/features/home/screens/home_nav_screen.dart';

class PractiseResultScreen extends StatelessWidget {
  const PractiseResultScreen({super.key});
  final double percent = 85;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: CustomAppBar(
        leading: BackIcon(),
        title: CustomTitle(title: 'نتائج تمارين اليوم', fontSize: 24),
      ),
      body: CustomPadding(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 5.h),
              Description(
                text: 'شاطر جدا\nأكملت جميع تمارين اليوم',
                fontSize: 16,
              ),
              SizedBox(height: 32.h),
              Container(
                width: double.infinity,
                height: 250.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Column(
                    children: [
                      SizedBox(height: 10.h),
                      SimiBoldTitle(title: 'النتيجة الإجمالية', fontSize: 18),
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
                      SimiBoldTitle(title: 'أداء جيد جداً', fontSize: 14),
                      SizedBox(height: 5.h),
                      Description(text: 'استمر في هذا التقدم', fontSize: 14),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Container(
                width: double.infinity,
                height: 120.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Column(
                    children: [
                      SimiBoldTitle(title: 'تمارين اليوم', fontSize: 20),
                      SizedBox(height: 15.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HomeNavScreen()),
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
