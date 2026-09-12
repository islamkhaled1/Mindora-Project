import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ImageCircleAvatar extends StatelessWidget {
  const ImageCircleAvatar({super.key, required this.image});
  final String image;
  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Colors.transparent,
      radius: 30.r,
      child: SizedBox(
        width: 200.w,
        height: 200.w,
        child: Image.asset(image, fit: BoxFit.cover),
      ),
    );
  }
}
