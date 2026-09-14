import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/core/widgets/common/custom_title.dart';
import 'package:sawa/core/widgets/common/description.dart';

class SplashWidget extends StatelessWidget {
  const SplashWidget({
    super.key,
    required this.image,
    required this.title,
    required this.text,
  });
  final String image;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 69.h),
        Align(alignment: AlignmentGeometry.center, child: Image.asset(image)),
        SizedBox(height: 32.h),
        CustomTitle(title: title, fontSize: 23),
        SizedBox(height: 32.h),
        Description(text: text, fontSize: 13),
        SizedBox(height: 104.h),
      ],
    );
  }
}
