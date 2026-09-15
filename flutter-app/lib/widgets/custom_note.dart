import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:sawa/app_text_styles.dart';
import 'package:sawa/app_colors.dart';

class CustomNote extends StatelessWidget {
  const CustomNote({super.key, required this.title, required this.icon});
  final String title;
  final String icon;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70.h,
      decoration: BoxDecoration(
        color: const Color(0xffF1E8FF),
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Iconify(icon, size: 25, color: AppColors.secondaryTextColor),
          ),

          Flexible(
            child: Text(
              title,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.font400Regular.copyWith(
                color: AppColors.primaryColor,
                fontSize: 13.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
