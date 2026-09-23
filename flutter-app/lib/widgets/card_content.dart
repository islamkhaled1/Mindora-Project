import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_colors.dart';
import 'package:sawa/app_text_styles.dart';
import 'package:sawa/widgets/description.dart';
import 'package:sawa/widgets/simi_bold_title.dart';

class CardContent extends StatelessWidget {
  const CardContent({
    super.key,
    required this.title,
    required this.description,
    required this.iconText,
    this.onTap,
  });
  final String title;
  final String description;
  final String iconText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SimiBoldTitle(title: title, fontSize: 15),
          SizedBox(height: 4.h),
          Description(text: description, fontSize: 11, align: TextAlign.left),
          SizedBox(height: 8.h),
          ConstrainedBox(
            constraints: BoxConstraints(minWidth: 100.w, maxWidth: 130.w),
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                side: BorderSide(color: AppColors.primaryColor, width: 1.5),
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                minimumSize: Size(0, 32.h),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                iconText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.font500Medium.copyWith(
                  fontSize: 13,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
