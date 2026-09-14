import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:sawa/core/widgets/common/custom_title.dart';

class IconContainer extends StatelessWidget {
  const IconContainer({
    super.key,
    required this.backGroundColor,
    required this.iconColor,
    required this.icon,
    this.label,
    this.labelSize = 14,
    this.width = 70,
    this.height = 45,
  });
  final Color backGroundColor;
  final Color iconColor;
  final String icon;
  final String? label;
  final int labelSize;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: width.w,
          height: height.h,
          decoration: BoxDecoration(
            color: backGroundColor,
            borderRadius: BorderRadius.circular(15.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(5.0.r),
            child: Iconify(icon, color: iconColor),
          ),
        ),
        if (label != null)
          Padding(
            padding: EdgeInsets.only(top: 8.0.r),
            child: CustomTitle(title: label!, fontSize: labelSize),
          ),
      ],
    );
  }
}
