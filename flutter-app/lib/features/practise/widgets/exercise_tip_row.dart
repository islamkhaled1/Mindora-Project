import 'package:flutter/material.dart';
import 'package:sawa/core/constants/app_colors.dart';
import 'package:sawa/core/widgets/common/simi_bold_title.dart';
import 'package:sawa/core/widgets/icons/icon_circle_avatar.dart';

class ExerciseTipRow extends StatelessWidget {
  const ExerciseTipRow({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.backGroundColor,
    this.fontSize = 16,
    this.align = TextAlign.center,
  });
  final String title;
  final String icon;
  final Color iconColor;
  final Color backGroundColor;
  final double fontSize;
  final TextAlign align;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SimiBoldTitle(
          align: align,
          title: title,
          fontSize: fontSize,
          textColor: AppColors.secondaryColor,
        ),
        IconCircleAvatar(
          icon: icon,
          color: iconColor,
          backgroundColor: backGroundColor,
          radius: 15,
          iconSize: 22,
        ),
      ],
    );
  }
}
