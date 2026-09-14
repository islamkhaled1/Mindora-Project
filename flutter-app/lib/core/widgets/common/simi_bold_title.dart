import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/core/constants/app_colors.dart';
import 'package:sawa/core/constants/app_text_styles.dart';

class SimiBoldTitle extends StatelessWidget {
  const SimiBoldTitle({
    super.key,
    required this.title,
    required this.fontSize,
    this.textColor = AppColors.primaryColor,
    this.align = TextAlign.center,
  });

  final String title;
  final double fontSize;
  final Color textColor;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.font600SimiBold.copyWith(
        fontSize: fontSize.sp,
        color: textColor,
      ),
      textAlign: align,
      textDirection: TextDirection.rtl,
    );
  }
}
