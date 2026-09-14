import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:sawa/core/constants/app_colors.dart';
import 'package:sawa/core/widgets/common/description.dart';
import 'package:sawa/core/widgets/common/simi_bold_title.dart';

class SettingsListTile extends StatelessWidget {
  const SettingsListTile({
    super.key,
    required this.icon,
    required this.title,
    this.description,
  });

  final String icon;
  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 50.h),
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.dividerColor, width: 0.7),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primaryColor,
            size: 25.r,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                SimiBoldTitle(title: title, fontSize: 14),
                if (description != null) ...[
                  SizedBox(height: 2.h),
                  Description(text: description!, fontSize: 12),
                ],
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Iconify(icon, color: AppColors.primaryColor, size: 30.r),
        ],
      ),
    );
  }
}
