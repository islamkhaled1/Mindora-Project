import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ImageCircleAvatar extends StatelessWidget {
  const ImageCircleAvatar({
    super.key,
    required this.image,
    this.width = 200,
    this.height = 200,
    this.radius = 30,
  });
  final String image;
  final double width;
  final double height;
  final double radius;
  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Colors.transparent,
      radius: radius.r,
      child: SizedBox(
        width: width.w,
        height: height.w,
        child: Image.asset(image, fit: BoxFit.cover),
      ),
    );
  }
}
