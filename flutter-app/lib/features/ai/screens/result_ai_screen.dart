import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/core/constants/app_colors.dart';
import 'package:sawa/core/constants/app_icons.dart';
import 'package:sawa/core/constants/app_text_styles.dart';
import 'package:sawa/core/widgets/buttons/custom_elevated_button.dart';
import 'package:sawa/core/widgets/common/animated_gradient_circular_progress.dart';
import 'package:sawa/core/widgets/common/custom_container.dart';
import 'package:sawa/core/widgets/common/custom_note.dart';
import 'package:sawa/core/widgets/common/custom_padding.dart';
import 'package:sawa/core/widgets/common/custom_title.dart';
import 'package:sawa/core/widgets/navigation/back_icon.dart';
import 'package:sawa/core/widgets/navigation/custom_app_bar.dart';
import 'package:sawa/features/plan/screens/developed_personlized_plan_screen.dart';

class ResultAiScreen extends StatelessWidget {
  const ResultAiScreen({super.key});
  final double totalPercent = 72;
  final double perceptualSkillsPercent = 75;
  final double communicationPercent = 45;
  final double motorSkillsPercent = 66;
  final double emotionalSkillsPercent = 80;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: CustomAppBar(
        leading: BackIcon(),
        title: CustomTitle(title: 'النتيجة الإجمالية', fontSize: 24),
      ),
      body: SingleChildScrollView(
        child: CustomPadding(
          child: Column(
            children: [
              SizedBox(height: 16.h),
              Center(
                child: AnimatedGradientCircularProgress(
                  size: 150.r,
                  percent: totalPercent,
                  strokeWidth: 10.r,
                  labelBuilder: (animatedPercent) => Text(
                    '${animatedPercent.round()}%',
                    style: AppTextStyles.font600SimiBold.copyWith(
                      color: AppColors.primaryColor,
                      fontSize: 32.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32.h),
              CustomContainer(
                width: double.infinity,
                height: 300.h,
                child: Column(
                  children: [
                    SkillProgressBar(
                      title: 'المهارات الإدراكية',
                      percent: perceptualSkillsPercent,
                    ),
                    SizedBox(height: 5.h),
                    SkillProgressBar(
                      title: 'التواصل',
                      percent: communicationPercent,
                    ),
                    SizedBox(height: 5.h),
                    SkillProgressBar(
                      title: 'المهارات الحركية',
                      percent: motorSkillsPercent,
                    ),
                    SizedBox(height: 5.h),
                    SkillProgressBar(
                      title: 'المهارات العاطفية',
                      percent: emotionalSkillsPercent,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18.h),
              CustomNote(
                title: 'يحرز طفلك تقدماً رائعاً. \nاستمر في تشجيعه',
                icon: AppIcons.heart,
                iconColor: AppColors.primaryColor,
                height: 60,
              ),
              SizedBox(height: 32.h),
              CustomElevatedButton(
                width: 200.w,
                title: 'عرض الخطة العلاجية',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DevelopedPersonlizedPlan(),
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

class SkillProgressBar extends StatelessWidget {
  const SkillProgressBar({
    super.key,
    required this.title,
    required this.percent,
  });

  final String title;
  final double percent;

  @override
  Widget build(BuildContext context) {
    final progress = (percent.clamp(0, 100)) / 100;

    return Padding(
      padding: EdgeInsets.all(15.0.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomTitle(title: '${percent.toInt()}%', fontSize: 16),

              CustomTitle(title: title, fontSize: 16),
            ],
          ),
          SizedBox(height: 10.h),

          Container(
            height: 10.h,
            decoration: BoxDecoration(
              color: const Color(0xFFF3EFFF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progress),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Align(
                    alignment: Alignment.centerRight,
                    child: FractionallySizedBox(
                      widthFactor: value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xff6D3FD6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
