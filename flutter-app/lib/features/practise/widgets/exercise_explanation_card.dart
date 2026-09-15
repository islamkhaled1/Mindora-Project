import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:sawa/core/widgets/common/custom_title.dart';
import 'package:sawa/core/widgets/common/description.dart';
import 'package:sawa/core/widgets/common/simi_bold_title.dart';

class ExerciseExplanationCard extends StatelessWidget {
  const ExerciseExplanationCard({
    super.key,
    required this.title,
    required this.description,
    this.descriptionSize = 14,
  });
  final String title;
  final String description;
  final double descriptionSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      width: double.infinity,
      height: 100.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SimiBoldTitle(title: title, fontSize: 18),
          SizedBox(height: 10.h),
          Description(
            text: description,
            fontSize: descriptionSize,
            align: TextAlign.start,
          ),
        ],
      ),
    );
  }
}

class ExerciseTitle extends StatelessWidget {
  const ExerciseTitle({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
  });
  final String title;
  final String icon;
  final Color iconColor;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200.w,
      height: 50.h,
      decoration: BoxDecoration(
        color: const Color(0xffF1E8FF),
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Iconify(icon, color: iconColor, size: 35.r),
          SizedBox(width: 10.w),
          CustomTitle(title: title, fontSize: 20),
        ],
      ),
    );
  }
}
