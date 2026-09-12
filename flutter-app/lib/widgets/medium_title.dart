import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_text_styles.dart';
import 'package:sawa/app_colors.dart';

class MediumTitle extends StatelessWidget {
  const MediumTitle({
    super.key,
    required this.title,
    required this.fontSize,
    this.color = AppColors.primaryColor,
  });

  final String title;
  final double fontSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.font500Medium.copyWith(
        fontSize: fontSize.sp,
        color: color,
      ),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
    );
  }
}
