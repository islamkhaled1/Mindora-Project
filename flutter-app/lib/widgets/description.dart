import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_text_styles.dart';
import 'package:sawa/app_colors.dart';

class Description extends StatelessWidget {
  const Description({
    super.key,
    required this.text,
    required this.fontSize,
    this.align = TextAlign.center,
  });

  final String text;
  final int fontSize;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.font400Regular.copyWith(
        fontSize: fontSize.sp,
        color: AppColors.secondaryColor,
      ),

      textAlign: align,
      textDirection: TextDirection.rtl,
    );
  }
}
