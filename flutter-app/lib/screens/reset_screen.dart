import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ci.dart';
import 'package:sawa/constants.dart';
import 'package:sawa/screens/log_in_screen.dart';
import 'package:sawa/widgets/custom_elevated_button.dart';
import 'package:sawa/widgets/custom_padding.dart';
import 'package:sawa/widgets/custom_title.dart';
import 'package:sawa/widgets/description.dart';

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
            Center(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff8456D2),
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 40.r,
                  backgroundColor: AppColors.secondaryTextColor,
                  child: Iconify(Ci.check, color: Colors.white, size: 65.r),
                ),
              ),
            ),
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
