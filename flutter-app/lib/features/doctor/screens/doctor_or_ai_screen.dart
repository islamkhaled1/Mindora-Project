import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/core/constants/app_colors.dart';
import 'package:sawa/core/widgets/buttons/custom_elevated_button.dart';
import 'package:sawa/core/widgets/common/custom_padding.dart';
import 'package:sawa/core/widgets/common/custom_title.dart';
import 'package:sawa/core/widgets/common/description.dart';
import 'package:sawa/core/widgets/navigation/back_icon.dart';
import 'package:sawa/core/widgets/navigation/custom_app_bar.dart';
import 'package:sawa/features/ai/screens/ai_assessment_info_screen.dart';
import 'package:sawa/features/doctor/screens/connect_with_doctor_screen.dart';
import 'package:sawa/features/doctor/widgets/custom_choice_group.dart';

class DoctorOrAiScreen extends StatefulWidget {
  const DoctorOrAiScreen({super.key});

  @override
  State<DoctorOrAiScreen> createState() => _DoctorOrAiScreenState();
}

class _DoctorOrAiScreenState extends State<DoctorOrAiScreen> {
  String? doctorPreference;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: CustomAppBar(leading: BackIcon()),
      body: CustomPadding(
        child: Column(
          children: [
            Center(
              child: CustomTitle(
                title: 'هل لدى طفلك أخصائي / طبيب؟',
                fontSize: 20,
              ),
            ),
            SizedBox(height: 8.h),
            Center(
              child: Description(
                text: ' يساعدنا التواصل مع طبيبك في\n إنشاء خطة أفضل لطفلك.',
                fontSize: 13,
              ),
            ),
            SizedBox(height: 64.h),
            CustomChoiceGroup(
              options: [
                ChoiceOption(
                  title: 'نعم، لدينا طبيب',
                  subtitle: 'أرغب في الربط / التواصل',
                  value: 'has_doctor',
                ),

                ChoiceOption(
                  title: 'لا، ليس لدينا طبيب',
                  subtitle: 'المتابعة باستخدام التقييم بواسطة الذكاء الاصطناعي',
                  value: 'no_doctor',
                ),
              ],
              onChanged: (value) {
                setState(() {
                  doctorPreference = value;
                });
              },
            ),
            SizedBox(height: 32.h),
            CustomElevatedButton(
              title: 'متابعة',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => doctorPreference == 'has_doctor'
                        ? const ConnectWithDoctorScreen()
                        : const AiAssessmentInfoScreen(),
                  ),
                );
              },
              width: 165,
              height: 40,
            ),
          ],
        ),
      ),
    );
  }
}
