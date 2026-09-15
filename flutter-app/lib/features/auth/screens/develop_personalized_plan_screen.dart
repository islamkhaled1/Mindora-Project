import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_text_styles.dart';
import 'package:sawa/constants.dart';
import 'package:sawa/screens/home_screen.dart';

class DevelopPersonalizedPlanScreen extends StatelessWidget {
  const DevelopPersonalizedPlanScreen({super.key});

  Widget _buildStepItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 48.r,
            height: 48.r,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.6), width: 1.5),
            ),
            child: Icon(icon, color: AppColors.primaryColor, size: 22.r),
          ),
          SizedBox(height: 8.h),
          Text(
            title,
            style: AppTextStyles.font700Bold.copyWith(
              fontSize: 11.sp,
              color: AppColors.primaryColor,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 3.h),
          Text(
            subtitle,
            style: AppTextStyles.font400Regular.copyWith(
              fontSize: 9.sp,
              color: AppColors.secondaryColor,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          children: [
            // Robot Icon / Header
            Center(
              child: Container(
                width: 130.r,
                height: 130.r,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.circleAvatarColor, width: 2.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondaryTextColor.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.smart_toy_rounded,
                  size: 70.r,
                  color: AppColors.secondaryTextColor,
                ),
              ),
            ),
            SizedBox(height: 18.h),

            // Main Info Card matching devolop personlized plan.png
            Container(
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 20.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22.r),
                border: Border.all(color: AppColors.circleAvatarColor.withValues(alpha: 0.6)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withValues(alpha: 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'تم إنشاء خطة علاجية مخصصة لطفلك',
                    style: AppTextStyles.font700Bold.copyWith(
                      fontSize: 16.sp,
                      color: AppColors.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'تم تصميم هذه الخطة بناءً على نتائج التقييم لتناسب احتياجات طفلك ومساعدته على التطور خطوة بخطوة.',
                    style: AppTextStyles.font400Regular.copyWith(
                      fontSize: 12.sp,
                      color: AppColors.secondaryColor,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // Section: ماذا يحدث الآن؟
            Text(
              'ماذا يحدث الآن؟',
              style: AppTextStyles.font700Bold.copyWith(
                fontSize: 16.sp,
                color: AppColors.primaryColor,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            SizedBox(height: 14.h),

            // 4 Steps Row (Right-to-Left in Arabic)
            Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStepItem(
                  icon: Icons.flag_outlined,
                  title: 'تحقيق الأهداف',
                  subtitle: 'نحتفل معاً بكل إنجاز أسبوعياً',
                ),
                SizedBox(width: 6.w),
                _buildStepItem(
                  icon: Icons.people_outline_rounded,
                  title: 'ابدأ الأنشطة',
                  subtitle: 'ابدأ الأنشطة اليومية لطفلك',
                ),
                SizedBox(width: 6.w),
                _buildStepItem(
                  icon: Icons.trending_up_rounded,
                  title: 'تابع التقدم',
                  subtitle: 'تابع تقدم طفلك الموصى به',
                ),
                SizedBox(width: 6.w),
                _buildStepItem(
                  icon: Icons.assignment_outlined,
                  title: 'خطة جاهزة',
                  subtitle: 'تم إنشاء خطة مخصصة لطفلك',
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // Note Card: أنت لست وحدك
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: AppColors.circleAvatarColor.withValues(alpha: 0.6)),
              ),
              child: Row(
                textDirection: TextDirection.rtl,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42.r,
                    height: 42.r,
                    decoration: BoxDecoration(
                      color: AppColors.circleAvatarColor.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(Icons.favorite_rounded, color: AppColors.primaryColor, size: 22.r),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      textDirection: TextDirection.rtl,
                      children: [
                        Text(
                          'أنت لست وحدك',
                          style: AppTextStyles.font700Bold.copyWith(
                            fontSize: 14.sp,
                            color: AppColors.primaryColor,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'نحن هنا لدعمك في كل خطوة من رحلتك مع طفلك، مع الاستمرارية والمحبة، يمكن لطفلك تحقيق الكثير.',
                          style: AppTextStyles.font400Regular.copyWith(
                            fontSize: 11.sp,
                            color: AppColors.secondaryColor,
                            height: 1.4,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 28.h),

            // CTA Button: ابدأ رحلتنا معاً
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
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
                'ابدأ رحلتنا معاً',
                style: AppTextStyles.font700Bold.copyWith(
                  fontSize: 16.sp,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}
