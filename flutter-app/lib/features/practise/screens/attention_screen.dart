import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:sawa/core/constants/app_colors.dart';
import 'package:sawa/core/constants/app_icons.dart';
import 'package:sawa/core/widgets/buttons/custom_elevated_button.dart';
import 'package:sawa/core/widgets/common/custom_padding.dart';
import 'package:sawa/core/widgets/common/custom_title.dart';
import 'package:sawa/core/widgets/icons/icon_circle_avatar.dart';
import 'package:sawa/core/widgets/navigation/back_icon.dart';
import 'package:sawa/core/widgets/navigation/custom_app_bar.dart';
import 'package:sawa/features/assessment/screens/encouragement_screen.dart';
import 'package:sawa/features/practise/screens/movement_screen.dart';
import 'package:sawa/features/practise/screens/practise_instruction_movement.dart';
import 'package:sawa/features/practise/widgets/exercise_progress_bar.dart';

class AttentionScreen extends StatefulWidget {
  AttentionScreen({
    super.key,
    this.appBarTitle = const CustomTitle(title: 'اسمع وابحث', fontSize: 22),
    this.isExersice = false,
  });
  final Widget appBarTitle;
  final bool isExersice;
  @override
  State<AttentionScreen> createState() => _AttentionScreenState();
}

class _AttentionScreenState extends State<AttentionScreen> {
  final List<Map<String, String>> items = [
    {'image': 'assets/images/cat.png', 'value': 'cat'},
    {'image': 'assets/images/car.png', 'value': 'car'},
    {'image': 'assets/images/star.png', 'value': 'star'},
    {'image': 'assets/images/Ball.png', 'value': 'ball'},
  ];

  final String correctValue = 'star';

  int? selectedIndex;

  void onItemSelected(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  Color _getBorderColor(int index) {
    if (selectedIndex == null) {
      return Colors.transparent;
    }
    if (selectedIndex != index) {
      return Colors.transparent;
    }
    final isCorrect = items[index]['value'] == correctValue;
    return isCorrect ? Colors.green : Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: CustomAppBar(leading: BackIcon(), title: widget.appBarTitle),
      body: CustomPadding(
        child: Column(
          children: [
            SizedBox(height: 32.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CustomTitle(title: 'أين النجمة', fontSize: 32),
                IconCircleAvatar(
                  padding: 6,
                  iconSize: 30,
                  icon: AppIcons.speaker,
                  color: AppColors.primaryColor,
                  backgroundColor: AppColors.circleAvatarColor,
                ),
              ],
            ),
            SizedBox(height: 32.h),
            Container(
              padding: EdgeInsets.all(10),
              width: double.infinity,
              height: 280.h,
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
              child: GridView.builder(
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 5.r,
                  crossAxisSpacing: 15.r,
                ),
                itemBuilder: (buildContext, index) {
                  final borderColor = _getBorderColor(index);
                  return GestureDetector(
                    onTap: () => onItemSelected(index),
                    child: Container(
                      margin: EdgeInsets.all(8.r),
                      width: 120.w,
                      height: 90.h,
                      decoration: BoxDecoration(
                        color: AppColors.cardsColor,
                        borderRadius: BorderRadius.circular(15.r),
                        border: Border.all(color: borderColor, width: 2),
                      ),
                      child: Center(child: Image.asset(items[index]['image']!)),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16.h),
            if (selectedIndex != null)
              CustomTitle(
                title: items[selectedIndex!]['value'] == correctValue
                    ? 'إجابة صحيحة'
                    : 'إجابة خاطئة',
                fontSize: 16,
              ),
            SizedBox(height: 48),

            Row(
              children: [
                Expanded(
                  child: CustomElevatedButton(
                    backgroundColor: Colors.white,
                    textColor: AppColors.primaryColor,
                    title: 'اسمع مرة أخرى',
                    onPressed: () {},
                  ),
                ),

                SizedBox(width: 10.w),

                Expanded(
                  child: CustomElevatedButton(
                    title: 'التالي',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => widget.isExersice
                              ? MovementScreen(
                                  isExercise: true,
                                  appBarTitle: ExerciseProgressBar(
                                    completedExercises: 2,
                                  ),
                                )
                              : EncouragementScreen(
                                  exerciseName: '"اسمع وابحث"',
                                  circleAvatarColor: AppColors.lightGreen,
                                  iconColor: AppColors.darkGreen,
                                  icon: AppIcons.brain,
                                  title: 'تمرين: اسمع وابحث',
                                  description: 'تم إكمال جميع الأنشطة بنجاح',
                                  targetScreen: PractiseInstructionMovement(),
                                ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
