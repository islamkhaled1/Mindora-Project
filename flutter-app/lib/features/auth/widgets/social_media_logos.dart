import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SocialMediaLogos extends StatelessWidget {
  const SocialMediaLogos({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.r),
          child: Image.asset(
            'assets/images/google.png',
            height: 25.h,
            width: 25.w,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.r),
          child: Image.asset(
            'assets/images/facebook.png',
            height: 25.h,
            width: 25.w,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.r),
          child: Image.asset(
            'assets/images/apple.png',
            height: 25.h,
            width: 25.w,
          ),
        ),
      ],
    );
  }
}
