import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_colors.dart';
import 'package:sawa/app_text_styles.dart';

/// Reusable banner clearly distinguishing available interactive training
/// from the in-development advanced AI model analysis.
class AiStatusBanner extends StatelessWidget {
  final String title;
  final String description;
  final String domainName;
  final bool compact;

  const AiStatusBanner({
    super.key,
    required this.title,
    required this.description,
    required this.domainName,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 14.w,
        vertical: compact ? 10.h : 14.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppColors.circleAvatarColor,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status Badges Row (Training Available NOW vs AI Model Coming Soon)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8.w,
            runSpacing: 6.h,
            children: [
              // Badge 1: Training is Available Now
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: AppColors.darkGreen.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 14.sp,
                      color: AppColors.darkGreen,
                    ),
                    SizedBox(width: 5.w),
                    Flexible(
                      child: Text(
                        'التدريب: متاح الآن',
                        style: AppTextStyles.font700Bold.copyWith(
                          fontSize: 11.sp,
                          color: AppColors.darkGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Badge 2: AI Model Coming Soon
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.cardsColor,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: AppColors.secondaryTextColor.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 13.sp,
                      color: AppColors.secondaryTextColor,
                    ),
                    SizedBox(width: 5.w),
                    Flexible(
                      child: Text(
                        'الـ AI: قيد التطوير قريبًا',
                        style: AppTextStyles.font700Bold.copyWith(
                          fontSize: 11.sp,
                          color: AppColors.secondaryTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 10.h),

          // Title & Description
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18.sp,
                color: AppColors.secondaryTextColor,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.font700Bold.copyWith(
                        fontSize: 13.sp,
                        color: AppColors.primaryColor,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      description,
                      style: AppTextStyles.font400Regular.copyWith(
                        fontSize: 11.5.sp,
                        color: AppColors.secondaryColor,
                        height: 1.35,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
