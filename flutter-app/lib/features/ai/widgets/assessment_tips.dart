import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/core/widgets/common/description.dart';
import 'package:sawa/core/widgets/common/simi_bold_title.dart';

class AssessmentTips extends StatelessWidget {
  const AssessmentTips({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.r),
      width: double.infinity,
      height: 300.h,
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
            padding: EdgeInsets.only(bottom: 8.0.r),
            child: SimiBoldTitle(title: 'المهارات الإدراكية', fontSize: 18),
          ),
          Description(
            text: 'الانتباه، الذاكرة، حل المشكلات، والتعلم.',
            fontSize: 14,
          ),
          SizedBox(height: 24.h),
          Padding(
            padding: EdgeInsets.only(bottom: 8.0.r),
            child: SimiBoldTitle(title: 'التواصل', fontSize: 18),
          ),
          Description(
            text: 'الفهم، التعبير اللغوي، والتفاعل الاجتماعي.',
            fontSize: 14,
          ),
          SizedBox(height: 24.h),
          Padding(
            padding: EdgeInsets.only(bottom: 8.0.r),
            child: SimiBoldTitle(title: 'المهارات الحركية', fontSize: 18),
          ),
          Description(
            text: 'الحركة الدقيقة، الحركة الكبرى، التناسق.',
            fontSize: 14,
          ),
          SizedBox(height: 24.h),
          Padding(
            padding: EdgeInsets.only(bottom: 8.0.r),
            child: SimiBoldTitle(title: 'المهارات التكيفية', fontSize: 18),
          ),
          Description(
            text: 'مهارات الحياة اليومية، الاستقلالية، والمسؤولية الشخصية',
            fontSize: 14,
            align: TextAlign.start,
          ),
        ],
      ),
    );
  }
}
