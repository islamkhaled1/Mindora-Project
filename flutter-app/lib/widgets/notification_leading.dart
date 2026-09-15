import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:sawa/app_colors.dart';
import 'package:sawa/app_icons.dart';

class NotificationLeading extends StatelessWidget {
  final VoidCallback? onTap;
  const NotificationLeading({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50.r,
      height: 50.r,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        color: AppColors.notificationColor,
      ),
      child: GestureDetector(
        onTap: onTap ?? () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
        child: Transform.scale(
          scale: 0.6,
          child: Iconify(AppIcons.notification, size: 5.r),
        ),
      ),
    );
  }
}
