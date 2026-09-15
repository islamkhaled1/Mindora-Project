import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/core/constants/app_colors.dart';
import 'package:sawa/core/constants/app_text_styles.dart';

class Description extends StatelessWidget {
  const Description({
    super.key,
    required this.text,
    required this.fontSize,
    this.align = TextAlign.center,
    this.color = AppColors.secondaryColor,
  });

  final String text;
  final double fontSize;
  final TextAlign align;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.font400Regular.copyWith(
        fontSize: fontSize.sp,
        color: color,
      ),

      textAlign: align,
      textDirection: TextDirection.rtl,
    );
  }
}
