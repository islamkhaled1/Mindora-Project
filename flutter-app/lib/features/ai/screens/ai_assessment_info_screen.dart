import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/core/constants/app_colors.dart';
import 'package:sawa/core/widgets/buttons/custom_elevated_button.dart';
import 'package:sawa/core/widgets/common/custom_padding.dart';
import 'package:sawa/core/widgets/common/custom_title.dart';
import 'package:sawa/core/widgets/common/description.dart';
import 'package:sawa/core/widgets/common/simi_bold_title.dart';
import 'package:sawa/core/widgets/navigation/back_icon.dart';
import 'package:sawa/core/widgets/navigation/custom_app_bar.dart';
import 'package:sawa/features/ai/widgets/assessment_tips.dart';
import 'package:sawa/features/ai/widgets/assessment_tips_sec.dart';
import 'package:sawa/features/practise/screens/speech_screen.dart';
import 'package:sawa/features/practise/widgets/exercise_progress_bar.dart';

class AiAssessmentInfoScreen extends StatelessWidget {
  const AiAssessmentInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: CustomAppBar(leading: BackIcon()),
      body: SingleChildScrollView(
        child: CustomPadding(
          child: Column(
            children: [
              Center(
                child: CustomTitle(
                  title: 'التقييم بالذكاء الاصطناعي',
                  fontSize: 20,
                ),
              ),
              SizedBox(height: 8.h),
              Center(
                child: Description(
                  text: 'تقييم مخصص لفهم نقاط القوة\n ومجالات النمو لدى طفلك.',
                  fontSize: 13,
                ),
              ),
              SizedBox(height: 32.h),
              Center(
                child: SimiBoldTitle(
                  title: 'يساعد هذا التقييم على قياس',
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 16.h),
              AssessmentTips(),
              SizedBox(height: 16.h),
              AssessmentTipsSec(),
              SizedBox(height: 32.h),
              CustomElevatedButton(
                width: 220.w,
                title: 'بدء تقييم الذكاء الاصطناعي',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SpeechScreen(
                        isExercise: true,
                        appBarTitle: ExerciseProgressBar(completedExercises: 1),
                      ),
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
