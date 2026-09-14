import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/core/constants/app_colors.dart';
import 'package:sawa/core/widgets/buttons/custom_elevated_button.dart';
import 'package:sawa/core/widgets/common/custom_padding.dart';
import 'package:sawa/core/widgets/common/custom_title.dart';
import 'package:sawa/core/widgets/common/description.dart';
import 'package:sawa/core/widgets/icons/success_check_icon.dart';
import 'package:sawa/features/auth/screens/log_in_screen.dart';

class ResetScreen extends StatelessWidget {
  const ResetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: CustomPadding(
        child: Column(
          children: [
            SizedBox(height: 180.h),
            Center(child: SuccessCheckIcon()),
            SizedBox(height: 32.h),
            CustomTitle(title: 'تم تحديث كلمة المرور \nبنجاح', fontSize: 24),
            SizedBox(height: 32.h),
            Description(
              text: 'يمكنك الآن تسجيل الدخول باستخدام\nكلمة المرور الجديدة.',
              fontSize: 13,
            ),
            SizedBox(height: 32.h),
            CustomElevatedButton(
              title: 'العودة لتسجيل الدخول',
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LogInScreen()),
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
