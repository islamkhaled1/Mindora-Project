import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/core/constants/app_colors.dart';
import 'package:sawa/core/widgets/buttons/custom_elevated_button.dart';
import 'package:sawa/core/widgets/common/custom_padding.dart';
import 'package:sawa/core/widgets/common/custom_title.dart';
import 'package:sawa/core/widgets/common/description.dart';
import 'package:sawa/core/widgets/icons/success_check_icon.dart';
import 'package:sawa/core/widgets/navigation/back_icon.dart';
import 'package:sawa/core/widgets/navigation/custom_app_bar.dart';
import 'package:sawa/features/doctor/widgets/doctor_card.dart';
import 'package:sawa/features/home/screens/home_nav_screen.dart';

class ConnectedSuccessfuly extends StatelessWidget {
  const ConnectedSuccessfuly({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: CustomAppBar(leading: BackIcon()),
      body: CustomPadding(
        child: Column(
          children: [
            SizedBox(height: 70.h),
            Center(child: SuccessCheckIcon()),
            SizedBox(height: 32.h),
            CustomTitle(title: ' تم الاتصال بنجاح', fontSize: 24),
            SizedBox(height: 12.h),
            Description(
              text: 'رائع! لقد تم الآن الاتصال بالطبيب.',
              fontSize: 12,
            ),
            SizedBox(height: 32.h),
            DoctorCard(docName: 'د.سارة أحمد'),
            SizedBox(height: 32.h),

            CustomElevatedButton(
              width: 165,
              height: 40,
              title: 'متابعة',
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => HomeNavScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
