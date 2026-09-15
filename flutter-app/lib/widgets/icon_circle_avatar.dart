import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:sawa/app_colors.dart';

class IconCircleAvatar extends StatelessWidget {
  const IconCircleAvatar({
    super.key,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    this.radius = 25,
    this.iconSize = 25,
    this.padding = 10,
  });
  final String icon;
  final Color color;
  final Color backgroundColor;
  final double radius;
  final double iconSize;
  final double padding;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(padding.r),
      child: CircleAvatar(
        radius: radius.r,
        backgroundColor: backgroundColor,
        child: Iconify(icon, size: iconSize.r, color: color),
      ),
    );
  }
}
