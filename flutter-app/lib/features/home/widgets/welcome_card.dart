import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/core/constants/app_colors.dart';
import 'package:sawa/core/widgets/common/medium_title.dart';
import 'package:sawa/core/widgets/common/simi_bold_title.dart';

class WelcomeCard extends StatelessWidget {
  const WelcomeCard({
    super.key,
    required this.title,
    required this.descripion,
    required this.image,
  });
  final String title;
  final String descripion;
  final String image;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130.h,
      decoration: BoxDecoration(
        color: const Color(0xffF1E8FF),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Image.asset(image),
              ),
            ],
          ),

          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SimiBoldTitle(title: title, fontSize: 16.sp),
                  SizedBox(height: 8.h),
                  MediumTitle(
                    title: descripion,
                    fontSize: 11.sp,
                    color: AppColors.secondaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
