import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/core/constants/app_colors.dart';
import 'package:sawa/core/constants/app_text_styles.dart';

class MediumTitle extends StatelessWidget {
  const MediumTitle({
    super.key,
    required this.title,
    required this.fontSize,
    this.color = AppColors.primaryColor,
    this.align = TextAlign.center,
  });

  final String title;
  final double fontSize;
  final Color color;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.font500Medium.copyWith(
        fontSize: fontSize.sp,
        color: color,
      ),
      textDirection: TextDirection.rtl,
      textAlign: align,
    );
  }
}
