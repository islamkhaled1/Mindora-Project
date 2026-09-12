import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/widgets/simi_bold_title.dart';
import 'package:sawa/widgets/exercise_tip_row.dart';

class ExerciseTipsStack extends StatelessWidget {
  const ExerciseTipsStack({super.key, required this.tips});
  final List<ExerciseTipRow> tips;
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          bottom: 0,
          left: -10,
          child: Image.asset('assets/images/secBot.png'),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            width: 182.w,
            height: 240.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: EdgeInsets.all(8.r),
                  child: SimiBoldTitle(title: 'ماذا سنفعل؟', fontSize: 18),
                ),
                tips[0],
                tips[1],
                tips[2],
                tips[3],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
