import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_text_styles.dart';
import 'package:sawa/constants.dart';
import 'package:sawa/core/models/baseline_assessment_models.dart';
import 'package:sawa/screens/ai_assessment_screen.dart';
import 'package:sawa/screens/develop_personalized_plan_screen.dart';

class CelebrationScreen extends StatelessWidget {
  final BaselineAssessmentModel? result;

  const CelebrationScreen({super.key, this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 1),

              // Celebratory Robot Illustration with Animated Glow
              Center(
                child: Container(
                  width: 170.r,
                  height: 170.r,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.circleAvatarColor, width: 3.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondaryTextColor.withValues(alpha: 0.18),
                        blurRadius: 28,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: 20.r,
                        right: 25.r,
                        child: Icon(Icons.celebration_rounded, color: const Color(0xffFDB62C), size: 24.r),
                      ),
                      Positioned(
                        top: 25.r,
                        left: 25.r,
                        child: Icon(Icons.auto_awesome_rounded, color: AppColors.secondaryTextColor, size: 20.r),
                      ),
                      Icon(
                        Icons.smart_toy_rounded,
                        size: 90.r,
                        color: AppColors.secondaryTextColor,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32.h),

              // Card matching Celebration.png
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 26.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(color: AppColors.circleAvatarColor.withValues(alpha: 0.6)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'عمل رائع',
                      style: AppTextStyles.font700Bold.copyWith(
                        fontSize: 22.sp,
                        color: AppColors.primaryColor,
                      ),
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      'لقد أكملت التقييم بنجاح.',
                      style: AppTextStyles.font500Medium.copyWith(
                        fontSize: 14.sp,
                        color: AppColors.primaryColor,
                      ),
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'نتائجك جاهزة لوالدك/والدتك.',
                      style: AppTextStyles.font400Regular.copyWith(
                        fontSize: 13.sp,
                        color: AppColors.secondaryColor,
                      ),
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Button: عرض النتائج -> Leads to AiAssessmentScreen result view (Result AI.png)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (result != null) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AiAssessmentScreen(
                            initialResult: result,
                          ),
                        ),
                      );
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DevelopPersonalizedPlanScreen(),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryTextColor,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'عرض النتائج',
                    style: AppTextStyles.font700Bold.copyWith(
                      fontSize: 16.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}
