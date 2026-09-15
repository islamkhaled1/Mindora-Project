import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_colors.dart';
import 'package:sawa/app_icons.dart';
import 'package:sawa/screens/movement_screen.dart';
import 'package:sawa/widgets/back_icon.dart';
import 'package:sawa/widgets/custom_app_bar.dart';
import 'package:sawa/widgets/custom_elevated_button.dart';
import 'package:sawa/widgets/custom_padding.dart';
import 'package:sawa/widgets/custom_title.dart';
import 'package:sawa/widgets/exercise_explanation_card.dart';
import 'package:sawa/widgets/exercise_note.dart';
import 'package:sawa/widgets/exercise_tip_row.dart';
import 'package:sawa/widgets/exercise_tips_stack.dart';

class PractiseInstructionMovement extends StatelessWidget {
  const PractiseInstructionMovement({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: CustomAppBar(
        height: 75.h,
        leading: BackIcon(),
        title: CustomTitle(title: 'اتبع الحركة', fontSize: 22),
      ),
      body: SingleChildScrollView(
        child: CustomPadding(
          child: Column(
            children: [
              SizedBox(height: 24.h),
              Center(
                child: ExerciseTitle(
                  title: 'الحركة',
                  icon: AppIcons.running,
                  iconColor: AppColors.dartOrange,
                ),
              ),
              SizedBox(height: 24.h),
              ExerciseExplanationCard(
                title: 'هدف التمرين',
                descriptionSize: 12,
                description:
                    'تحسين مهارات التحكم بالحركة والتركيز لدى\n الطفل من خلال التفاعل الحركي مع العناصر \nالممتعة على الشاشة.',
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                height: 260.h,
                child: ExerciseTipsStack(
                  tips: [
                    ExerciseTipRow(
                      title: 'قف أمام الكاميرا.',
                      icon: AppIcons.camera,
                      iconColor: AppColors.primaryColor,
                      backGroundColor: AppColors.circleAvatarColor,
                      fontSize: 13,
                    ),
                    ExerciseTipRow(
                      title: 'استمع جيداً.',
                      icon: AppIcons.move,
                      iconColor: AppColors.dartOrange,
                      backGroundColor: AppColors.lightOrange,
                      fontSize: 13,
                    ),
                    ExerciseTipRow(
                      title: 'انظر إلى النجمه.',
                      icon: AppIcons.eyes,
                      iconColor: AppColors.darkRed,
                      backGroundColor: AppColors.lightRed,
                      fontSize: 13,
                    ),
                    ExerciseTipRow(
                      align: TextAlign.start,
                      title: 'اتبع النجمة للوصول\n للهدف',
                      icon: AppIcons.secStar,
                      iconColor: AppColors.darkYellow,
                      backGroundColor: AppColors.lightYellow,
                      fontSize: 13,
                    ),
                  ],
                ),
              ),
              ExerciseNote(
                text:
                    'هذا التمرين جزء من خطة عمر العلاجية\n لتحسين مهارة التواصل والتعبير.',
              ),
              SizedBox(height: 32.h),
              CustomElevatedButton(
                width: 200.w,
                title: 'حسنًا، لنبدأ!',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MovementScreen(),
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
