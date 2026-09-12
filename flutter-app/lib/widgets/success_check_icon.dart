import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ci.dart';
import 'package:sawa/app_colors.dart';

class SuccessCheckIcon extends StatelessWidget {
  const SuccessCheckIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xff8456D2),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 40.r,
        backgroundColor: AppColors.secondaryTextColor,
        child: Iconify(Ci.check, color: Colors.white, size: 65.r),
      ),
    );
  }
}
