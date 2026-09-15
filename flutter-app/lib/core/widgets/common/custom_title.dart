import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/core/constants/app_colors.dart';
import 'package:sawa/core/constants/app_text_styles.dart';

class CustomTitle extends StatelessWidget {
  const CustomTitle({super.key, required this.title, required this.fontSize});

  final String title;
  final int fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.font700Bold.copyWith(
        fontSize: fontSize.sp,
        color: AppColors.primaryColor,
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
    );
  }
}
