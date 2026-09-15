import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/core/widgets/common/custom_title.dart';
import 'package:sawa/core/widgets/common/medium_title.dart';

class StateBadge extends StatelessWidget {
  const StateBadge({
    super.key,
    required this.time,
    required this.exrecisesCount,
  });
  final String time;
  final String exrecisesCount;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40.h,
      decoration: BoxDecoration(
        color: const Color(0xffF1E8FF),
        borderRadius: BorderRadius.circular(15.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MediumTitle(title: ' دقائق', fontSize: 14),
                CustomTitle(title: time, fontSize: 14),
                MediumTitle(title: 'حوالي ', fontSize: 14),
                CustomTitle(title: ' • ', fontSize: 14),
                CustomTitle(title: exrecisesCount, fontSize: 14),
                MediumTitle(title: 'تمارين ', fontSize: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
