import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/core/constants/app_colors.dart';
import 'package:sawa/core/constants/app_text_styles.dart';
import 'package:sawa/core/widgets/common/description.dart';
import 'package:sawa/core/widgets/common/simi_bold_title.dart';

class CardContent extends StatelessWidget {
  const CardContent({
    super.key,
    required this.title,
    required this.description,
    required this.iconText,
  });
  final String title;
  final String description;
  final String iconText;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Spacer(),
          SimiBoldTitle(title: title, fontSize: 16),
          Spacer(),
          Description(text: description, fontSize: 12, align: TextAlign.left),
          Spacer(),
          Container(
            width: 110.w,
            height: 35.h,
            child: ElevatedButton(
              onPressed: () {},

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                side: BorderSide(color: AppColors.primaryColor, width: 1.5),

                padding: EdgeInsets.symmetric(horizontal: 4.w),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),

              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  iconText,
                  maxLines: 1,
                  softWrap: false,
                  style: AppTextStyles.font500Medium.copyWith(
                    fontSize: 14,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ),
          ),
          Spacer(),
        ],
      ),
    );
  }
}
