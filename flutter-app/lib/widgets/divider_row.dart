import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_colors.dart';
import 'package:sawa/widgets/description.dart';

class DividerRow extends StatelessWidget {
  const DividerRow({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(thickness: 1.r, color: Color(0xff878787)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.r),
          child: Description(text: text, fontSize: 14),
        ),
        Expanded(
          child: Divider(thickness: 1.r, color: AppColors.dividerColor),
        ),
      ],
    );
  }
}
