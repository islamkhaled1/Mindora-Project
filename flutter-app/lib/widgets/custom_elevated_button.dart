import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_colors.dart';
import 'package:sawa/app_text_styles.dart';

class CustomElevatedButton extends StatelessWidget {
  const CustomElevatedButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.height = 45,
    this.width = double.infinity,
    this.isLoading = false,
    this.backgroundColor = AppColors.primaryColor,
    this.textColor = Colors.white,
  });

  final String title;
  final VoidCallback? onPressed;
  final double height;
  final double width;
  final bool isLoading;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height.h,
      width: width.w,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          disabledBackgroundColor: AppColors.primaryColor.withValues(alpha: 0.6),
          shadowColor: Colors.black,
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.r),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 20.h,
                width: 20.h,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                title,
                style: AppTextStyles.font700Bold.copyWith(
                  color: textColor,
                  fontSize: 16.sp,
                ),
              ),
      ),
    );
  }
}
