import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/core/constants/app_colors.dart';
import 'package:sawa/core/constants/app_icons.dart';
import 'package:sawa/core/constants/app_text_styles.dart';
import 'package:sawa/core/widgets/common/animated_gradient_circular_progress.dart';
import 'package:sawa/core/widgets/common/custom_padding.dart';
import 'package:sawa/core/widgets/common/medium_title.dart';
import 'package:sawa/core/widgets/common/notification_leading.dart';
import 'package:sawa/core/widgets/common/simi_bold_title.dart';
import 'package:sawa/core/widgets/icons/image_circle_avatar.dart';
import 'package:sawa/core/widgets/navigation/custom_app_bar.dart';
import 'package:sawa/features/home/widgets/home_card.dart';
import 'package:sawa/features/home/widgets/welcome_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  final double percent = 0;
  final String childName = 'عمر';
  final String childImage = 'assets/images/kid_image.png';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: CustomAppBar(
        height: 75.h,
        leadingWidth: 80.w,
        leading: Center(child: NotificationLeading()),
        actions: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SimiBoldTitle(title: 'مرحباً ', fontSize: 14),
                  MediumTitle(
                    title: 'إزاي حال $childName النهاردة؟',
                    fontSize: 14,
                    color: AppColors.secondaryColor,
                  ),
                ],
              ),
              ImageCircleAvatar(image: childImage),
            ],
          ),
        ],
      ),

      body: CustomPadding(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 24.h),
              WelcomeCard(
                title: 'نتابع رحلة $childName معاً',
                descripion: 'كل يوم خطوة جديدة نحو تطور أفضل لمستقبله.',
                image: 'assets/images/firstBot.png',
              ),
              Padding(
                padding: EdgeInsets.only(top: 20.r),
                child: HomeCard(
                  icon: AppIcons.chartStroke,
                  circleAvatarColor: AppColors.circleAvatarColor,
                  iconColor: AppColors.primaryColor,
                  title: 'نظرة على التقدم',
                  description:
                      'تابعي أحدث نتائج $childName\nوتطوره في المهارات المختلفة.',
                  iconText: 'عرض التقدم',
                  lastWidget: AnimatedGradientCircularProgress(
                    percent: percent,
                    size: 60.r,
                    strokeWidth: 10,
                    labelBuilder: (animatedPercent) => Text(
                      '${animatedPercent.round()}%',
                      style: AppTextStyles.font600SimiBold.copyWith(
                        color: AppColors.primaryColor,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 20.r),
                child: HomeCard(
                  icon: AppIcons.star,
                  iconColor: Color(0xff5BAC34),
                  circleAvatarColor: Color(0xffDFF3D2),
                  title: 'تمرينات اليوم المخصصة',
                  description:
                      'أنشطة وتعارين مختارة خصيصاً ل$childName بناءً على خطة العلاج.',
                  iconText: 'ابدأ الان',
                  lastWidget: Image(
                    image: AssetImage('assets/images/toy.png'),
                    width: 65.w,
                    height: 100.h,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 20.r),
                child: HomeCard(
                  icon: AppIcons.bulb,
                  iconColor: AppColors.primaryColor,
                  circleAvatarColor: AppColors.circleAvatarColor,
                  title: 'رؤى ذكية',
                  description:
                      'ملاحظات وتحليلات ذكية تساعدك على فهم احتياجات $childName بشكل أفضل.',
                  iconText: 'عرض الرؤى',
                  lastWidget: Image(
                    image: AssetImage('assets/images/book.png'),
                    width: 65.w,
                    height: 100.h,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
