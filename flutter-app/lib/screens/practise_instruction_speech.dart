import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_colors.dart';
import 'package:sawa/app_icons.dart';
import 'package:sawa/widgets/ai_status_banner.dart';
import 'package:sawa/widgets/back_icon.dart';
import 'package:sawa/widgets/custom_app_bar.dart';
import 'package:sawa/widgets/custom_elevated_button.dart';
import 'package:sawa/widgets/custom_padding.dart';
import 'package:sawa/widgets/custom_title.dart';
import 'package:sawa/widgets/exercise_explanation_card.dart';
import 'package:sawa/widgets/exercise_note.dart';
import 'package:sawa/widgets/exercise_tip_row.dart';
import 'package:sawa/widgets/exercise_tips_stack.dart';

class PractiseInstructionSpeech extends StatelessWidget {
  const PractiseInstructionSpeech({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: CustomAppBar(
        height: 75.h,
        leading: BackIcon(),
        title: CustomTitle(title: 'قولها معايا', fontSize: 22),
      ),
      body: SingleChildScrollView(
        child: CustomPadding(
          child: Column(
            children: [
              SizedBox(height: 24.h),
              Center(
                child: ExerciseTitle(
                  title: 'التواصل واللغة',
                  icon: AppIcons.message,
                  iconColor: AppColors.primaryColor,
                ),
              ),
              SizedBox(height: 24.h),
              ExerciseExplanationCard(
                title: 'هدف التمرين',
                description:
                    'مساعدة عمر على تقليد الأصوات \nوالكلمات البسيطة للتعبير عن احتياجاته.',
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                height: 260.h,
                child: ExerciseTipsStack(
                  tips: [
                    ExerciseTipRow(
                      title: 'سأقول كلمة.',
                      icon: AppIcons.speaker,
                      iconColor: AppColors.primaryColor,
                      backGroundColor: AppColors.circleAvatarColor,
                      fontSize: 13,
                    ),
                    ExerciseTipRow(
                      title: 'استمع جيداً.',
                      icon: AppIcons.ear,
                      iconColor: AppColors.dartOrange,
                      backGroundColor: AppColors.lightOrange,
                      fontSize: 13,
                    ),
                    ExerciseTipRow(
                      title: 'حاول أن تقولها معي.',
                      icon: AppIcons.mouth,
                      iconColor: AppColors.darkRed,
                      backGroundColor: AppColors.lightRed,
                      fontSize: 13,
                    ),
                    ExerciseTipRow(
                      title: 'سأشجعك و نكرر معاً.',
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
                    'هذا التمرين جزء من خطة الأنشطة المنزلية\n لتحسين مهارة التواصل والتعبير.',
              ),
              SizedBox(height: 16.h),
              const AiStatusBanner(
                domainName: 'النطق والكلام',
                title: 'تحليل الكلام بالـ AI قريبًا',
                description:
                    'نعمل حاليًا على تطوير نموذج AI مخصص لدعم وتحليل مهارات النطق.',
              ),
              SizedBox(height: 24.h),
              CustomElevatedButton(
                width: 200.w,
                title: 'حسنًا، لنبدأ التدريب!',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تدريب النطق غير متاح حاليًا.'),
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
