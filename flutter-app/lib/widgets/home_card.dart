import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/widgets/card_content.dart';
import 'package:sawa/widgets/icon_circle_avatar.dart';

class HomeCard extends StatelessWidget {
  const HomeCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.circleAvatarColor,
    required this.title,
    required this.description,
    required this.iconText,
    required this.lastWidget,
    this.onTap,
  });

  final String icon;
  final Color iconColor;
  final Color circleAvatarColor;
  final String title;
  final String description;
  final String iconText;
  final Widget lastWidget;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        constraints: BoxConstraints(minHeight: 130.h),
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
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
          children: [
            Column(
              children: [
                IconCircleAvatar(
                  icon: icon,
                  color: iconColor,
                  backgroundColor: circleAvatarColor,
                ),
              ],
            ),
            CardContent(
              title: title,
              description: description,
              iconText: iconText,
              onTap: onTap,
            ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.only(right: 4.r, top: 8.r),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [lastWidget],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
