import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/core/widgets/common/simi_bold_title.dart';

class AssessmentTipsSec extends StatelessWidget {
  const AssessmentTipsSec({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.r),
      width: double.infinity,
      height: 120.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 8.0.r),
            child: SimiBoldTitle(
              title: 'يُنجز وفق سرعة طفلك الخاصة',
              fontSize: 14,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 8.0.r),
            child: SimiBoldTitle(
              title: 'يستغرق حوالي 10–15 دقيقة',
              fontSize: 14,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 8.0.r),
            child: SimiBoldTitle(title: 'متكيف ومناسب للأطفال', fontSize: 14),
          ),
          Padding(
            padding: EdgeInsets.only(top: 8.0.r),
            child: SimiBoldTitle(title: 'بيانات طفلك آمنة وخاصة', fontSize: 14),
          ),
        ],
      ),
    );
  }
}
