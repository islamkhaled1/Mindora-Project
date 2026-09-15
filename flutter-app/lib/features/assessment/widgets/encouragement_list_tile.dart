import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconify_flutter/icons/ci.dart';
import 'package:sawa/app_colors.dart';
import 'package:sawa/widgets/custom_title.dart';
import 'package:sawa/widgets/description.dart';
import 'package:sawa/widgets/icon_circle_avatar.dart';

class EncouragmentListTile extends StatelessWidget {
  const EncouragmentListTile({
    super.key,
    required this.circleAvatarColor,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.description,
  });
  final Color circleAvatarColor;
  final Color iconColor;
  final String icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 100.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Center(
        child: ListTile(
          horizontalTitleGap: 0,

          leading: SizedBox(
            height: 80.h,
            width: 80.w,
            child: Transform.scale(
              scale: 1.2,
              child: Align(
                alignment: AlignmentGeometry.centerLeft,
                child: IconCircleAvatar(
                  padding: 0,
                  radius: 25,
                  iconSize: 30,
                  icon: icon,
                  color: iconColor,
                  backgroundColor: circleAvatarColor,
                ),
              ),
            ),
          ),
          trailing: IconCircleAvatar(
            radius: 15,
            icon: Ci.check,
            color: Colors.white,
            backgroundColor: AppColors.primaryColor,
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 4.0.r),
                  child: CustomTitle(title: title, fontSize: 14),
                ),
              ),
            ],
          ),
          subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Description(
                  text: description,
                  fontSize: 12,
                  align: TextAlign.start,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
