import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/core/constants/app_colors.dart';
import 'package:sawa/core/constants/app_icons.dart';
import 'package:sawa/core/widgets/common/custom_note.dart';
import 'package:sawa/core/widgets/common/custom_padding.dart';
import 'package:sawa/core/widgets/common/custom_title.dart';
import 'package:sawa/core/widgets/common/description.dart';
import 'package:sawa/core/widgets/common/notification_leading.dart';
import 'package:sawa/core/widgets/navigation/custom_app_bar.dart';
import 'package:sawa/features/plan/widgets/plan_details.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: CustomAppBar(
        leading: SizedBox(),
        title: Padding(
          padding: EdgeInsets.only(top: 10.0.r),
          child: CustomTitle(title: 'الخطة العلاجية', fontSize: 24),
        ),
        actions: [
          Padding(padding: EdgeInsets.all(8.0.r), child: NotificationLeading()),
        ],
      ),
      body: CustomPadding(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 5.h),
              Description(
                text:
                    'خطة مخصصة لطفلك بناءً على نتائج التقييم، لمساعدته على التطور خطوة بخطوة.',
                fontSize: 14,
              ),
              SizedBox(height: 24.h),
              Align(
                alignment: AlignmentGeometry.centerRight,
                child: CustomTitle(
                  title: 'مجالات الخطة العلاجية',
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 10.h),
              Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 460.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        PlanDetails(
                          title: 'التواصل واللغة',
                          description:
                              'تحسين مهارات التواصل والتعبير\n عن الاحتياجات وفهم اللغة.',
                          sessionsCount: 3,
                          icon: AppIcons.message,
                          containersColor: AppColors.circleAvatarColor,
                          iconColor: AppColors.primaryColor,
                        ),
                        Divider(),
                        PlanDetails(
                          title: 'المهارات الحركية',
                          description:
                              'تطوير التوازن، التنسيق، والمهارات\n الحركية الدقيقة والكبيرة.',
                          sessionsCount: 2,
                          icon: AppIcons.running,
                          containersColor: AppColors.lightOrange,
                          iconColor: AppColors.dartOrange,
                        ),
                        Divider(),
                        PlanDetails(
                          title: 'الإدراك والتعلم',
                          description:
                              ' تنمية الانتباه، الذاكرة، وحل \nالمشكلات والاستقلالية في التعلم.',
                          sessionsCount: 2,
                          icon: AppIcons.brain,
                          containersColor: AppColors.lightGreen,
                          iconColor: AppColors.darkGreen,
                        ),
                        Divider(),
                        PlanDetails(
                          title: 'المهارات الاجتماعية والعاطفية',
                          description:
                              'تعزيز التفاعل الاجتماعي، بناء العلاقات، والتعبير عن المشاعر.',
                          sessionsCount: 2,
                          icon: AppIcons.handshake,
                          containersColor: AppColors.lightRed,
                          iconColor: AppColors.darkRed,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              CustomNote(
                width: 270.w,
                fontSize: 12,
                iconColor: AppColors.primaryColor,
                height: 50,
                title:
                    'تُراجع الخطة بشكل دوري وتُعدّل حسب تقدم طفلك واحتياجاته لتحقيق أفضل النتائج.',
                icon: AppIcons.heart,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
