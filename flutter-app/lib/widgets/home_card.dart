import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_colors.dart';
import 'package:sawa/app_text_styles.dart';
import 'package:sawa/widgets/animated_gradient_circular_progress.dart';
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
  });

  final String icon;
  final Color iconColor;
  final Color circleAvatarColor;
  final String title;
  final String description;
  final String iconText;
  final Widget lastWidget;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130.h,
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
          ),
          Spacer(),
          Padding(
            padding: EdgeInsets.only(right: 4.r, top: 8.r),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [lastWidget],
            ),
          ),
        ],
      ),
    );
  }
}
