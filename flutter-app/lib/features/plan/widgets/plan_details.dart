import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:sawa/core/constants/app_colors.dart';
import 'package:sawa/core/constants/app_icons.dart';
import 'package:sawa/core/widgets/common/description.dart';
import 'package:sawa/core/widgets/common/medium_title.dart';
import 'package:sawa/core/widgets/common/simi_bold_title.dart';
import 'package:sawa/core/widgets/icons/icon_container.dart';

class PlanDetails extends StatelessWidget {
  const PlanDetails({
    super.key,
    required this.title,
    required this.description,
    required this.sessionsCount,
    required this.icon,
    required this.containersColor,
    required this.iconColor,
  });
  final String title;
  final String description;
  final int sessionsCount;
  final String icon;
  final Color containersColor;
  final Color iconColor;
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(8.0.r),
          child: Align(
            alignment: AlignmentGeometry.topLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                Iconify(
                  AppIcons.clock,
                  size: 30,
                  color: AppColors.primaryColor,
                ),
                SizedBox(height: 5.h),
                MediumTitle(title: ' ${sessionsCount} جلسات', fontSize: 13),
                SizedBox(height: 5.h),
                Description(text: ' في الأسبوع', fontSize: 13),
              ],
            ),
          ),
        ),

        Padding(
          padding: EdgeInsets.all(8.0.r),
          child: Align(
            alignment: AlignmentGeometry.topRight,
            child: SizedBox(
              width: 170.w,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SimiBoldTitle(title: title, fontSize: 12),
                  SizedBox(height: 5.h),
                  Description(
                    align: TextAlign.start,
                    text: description,
                    fontSize: 11,
                  ),
                  SizedBox(height: 10.h),
                  Container(
                    width: 90.w,
                    height: 30.h,
                    decoration: BoxDecoration(
                      color: containersColor,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: SimiBoldTitle(
                        title: 'الأهداف ${sessionsCount}',
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Spacer(),
        Padding(
          padding: EdgeInsets.only(right: 6.0.r, top: 6.0.r),
          child: IconContainer(
            width: 45,
            height: 30,
            backGroundColor: containersColor,
            iconColor: iconColor,
            icon: icon,
          ),
        ),
      ],
    );
  }
}
