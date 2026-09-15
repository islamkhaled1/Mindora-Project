import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:sawa/core/constants/app_colors.dart';
import 'package:sawa/core/constants/app_text_styles.dart';
import 'package:sawa/core/widgets/common/custom_container.dart';

class CustomNote extends StatelessWidget {
  const CustomNote({
    super.key,
    required this.title,
    required this.icon,
    this.height = 70,
    this.fontSize = 13,
    this.width = double.infinity,
    this.iconColor = AppColors.secondaryTextColor,
  });
  final String title;
  final String icon;
  final double height;
  final double width;
  final double fontSize;
  final Color iconColor;
  @override
  Widget build(BuildContext context) {
    return CustomContainer(
      width: width.w,
      height: height.h,
      color: Color(0xffF1E8FF),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Iconify(icon, size: 25, color: iconColor),
          ),

          Flexible(
            child: Text(
              title,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.font500Medium.copyWith(
                color: AppColors.primaryColor,
                fontSize: fontSize.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
