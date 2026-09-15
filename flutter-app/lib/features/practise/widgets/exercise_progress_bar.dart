import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/core/constants/app_colors.dart';

class ExerciseProgressBar extends StatelessWidget {
  const ExerciseProgressBar({super.key, required this.completedExercises});

  final int completedExercises;

  @override
  Widget build(BuildContext context) {
    final progress = (completedExercises.clamp(0, 3)) / 3;

    return Container(
      height: 14.h,
      decoration: BoxDecoration(
        color: const Color(0xFFF3EFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryColor, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: progress),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(widthFactor: value, child: child),
            );
          },
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF432F62),
                  Color(0xFF8456D2),
                  Color(0xFFA88DE7),
                  Color(0xffF3EFFF),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
