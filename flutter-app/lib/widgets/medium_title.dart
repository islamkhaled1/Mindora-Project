import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_text_styles.dart';
import 'package:sawa/constants.dart';

class MediumTitle extends StatelessWidget {
  const MediumTitle({super.key, required this.title, required this.fontSize});

  final String title;
  final int fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.font500Medium.copyWith(
        fontSize: fontSize.sp,
        color: AppColors.primaryColor,
      ),
      textAlign: TextAlign.center,
    );
  }
}
