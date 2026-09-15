import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_text_styles.dart';
import 'package:sawa/app_colors.dart';

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
