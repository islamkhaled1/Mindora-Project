import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_text_styles.dart';
import 'package:sawa/constants.dart';
import 'package:sawa/core/models/activity_models.dart';
import 'package:sawa/core/models/session_models.dart';
import 'package:sawa/screens/home_screen.dart';
import 'package:sawa/screens/session_result_screen.dart';

class SessionEncouragementScreen extends StatelessWidget {
  final CompletedSessionModel completedSession;
  final ActivityModel activity;

  const SessionEncouragementScreen({
    super.key,
    required this.completedSession,
    required this.activity,
  });

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
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            },
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const Spacer(flex: 1),

              // Glowing Purple Circle Checkmark matching Encouragement.png
              Center(
                child: Container(
                  width: 140.r,
                  height: 140.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.secondaryTextColor,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondaryTextColor.withValues(alpha: 0.35),
                        blurRadius: 32,
                        spreadRadius: 6,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 75.r,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 32.h),

              // Title: أحسنت يا بطل
              Text(
                'أحسنت يا بطل',
                style: AppTextStyles.font700Bold.copyWith(
                  fontSize: 26.sp,
                  color: AppColors.primaryColor,
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
              SizedBox(height: 12.h),

              // Subtitle
              Text(
                'لقد أكملت تمرين "${activity.title}" بنجاح.\nاستمر هكذا، أنت رائع!',
                style: AppTextStyles.font500Medium.copyWith(
                  fontSize: 14.sp,
                  color: AppColors.secondaryColor,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
              SizedBox(height: 36.h),

              // Activity Detail Card matching Encouragement.png
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22.r),
                  border: Border.all(color: AppColors.circleAvatarColor.withValues(alpha: 0.7)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withValues(alpha: 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    // Speaker Box
                    Container(
                      width: 48.r,
                      height: 48.r,
                      decoration: BoxDecoration(
                        color: AppColors.circleAvatarColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Icon(
                        Icons.volume_up_rounded,
                        color: AppColors.primaryColor,
                        size: 24.r,
                      ),
                    ),
                    SizedBox(width: 14.w),

                    // Exercise Title & Status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        textDirection: TextDirection.rtl,
                        children: [
                          Text(
                            'تمرين: ${activity.title}',
                            style: AppTextStyles.font700Bold.copyWith(
                              fontSize: 14.sp,
                              color: AppColors.primaryColor,
                            ),
                            textDirection: TextDirection.rtl,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            'تم إكمال جميع الحركات والأنشطة بنجاح',
                            style: AppTextStyles.font400Regular.copyWith(
                              fontSize: 11.sp,
                              color: AppColors.secondaryColor,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),
                    ),

                    // Small Check Circle
                    Container(
                      width: 28.r,
                      height: 28.r,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 16.r,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Button: التالي -> leads to SessionResultScreen
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SessionResultScreen(
                          completedSession: completedSession,
                          activity: activity,
                        ),
                      ),
                    );
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
                    'التالي',
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
    ),
  );
},
),
),
);
}
}
