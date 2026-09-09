import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_text_styles.dart';
import 'package:sawa/constants.dart';

class Description extends StatelessWidget {
  const Description({super.key, required this.text, required this.fontSize});

  final String text;
  final int fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.font400Regular.copyWith(
        fontSize: fontSize.sp,
        color: AppColors.secondaryColor,
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
    );
  }
}
