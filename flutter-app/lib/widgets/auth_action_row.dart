import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_text_styles.dart';
import 'package:sawa/app_colors.dart';
import 'package:sawa/screens/otp_verification_screen.dart';

class AuthActionRow extends StatelessWidget {
  const AuthActionRow({
    super.key,
    required this.question,
    required this.linkText,
    this.targetScreen,
  });
  final String question;
  final String linkText;
  final Widget? targetScreen;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => targetScreen ?? OtpVerificationScreen(),
              ),
            );
          },
          child: Text(
            linkText,
            style: AppTextStyles.font400Regular.copyWith(
              color: AppColors.secondaryTextColor,
              fontSize: 12.sp,
            ),
          ),
        ),
        Text(
          question,
          style: AppTextStyles.font400Regular.copyWith(
            color: AppColors.primaryColor,
            fontSize: 12.sp,
          ),
        ),
      ],
    );
  }
}
