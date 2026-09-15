import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_colors.dart';
import 'package:sawa/screens/home_screen.dart';
import 'package:sawa/widgets/back_icon.dart';
import 'package:sawa/widgets/custom_app_bar.dart';
import 'package:sawa/widgets/custom_elevated_button.dart';
import 'package:sawa/widgets/custom_padding.dart';
import 'package:sawa/widgets/custom_title.dart';
import 'package:sawa/widgets/description.dart';
import 'package:sawa/widgets/encouragement_list_tile.dart';
import 'package:sawa/widgets/success_check_icon.dart';

class EncouragementScreen extends StatelessWidget {
  const EncouragementScreen({
    super.key,
    required this.circleAvatarColor,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.description,
    required this.exerciseName,
    this.targetScreen,
  });
  final Color circleAvatarColor;
  final Color iconColor;
  final String icon;
  final String title;
  final String description;
  final String exerciseName;
  final Widget? targetScreen;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: CustomAppBar(leading: const BackIcon()),
      body: CustomPadding(
        child: Column(
          children: [
            SizedBox(height: 70.h),
            const Center(child: SuccessCheckIcon()),
            SizedBox(height: 32.h),
            const CustomTitle(title: 'أحسنت يا بطل', fontSize: 26),
            SizedBox(height: 12.h),
            Description(
              text:
                  'لقد أكملت تمرين $exerciseName بنجاح.\nاستمر هكذا، أنت رائع',
              fontSize: 16,
            ),
            SizedBox(height: 32.h),
            EncouragmentListTile(
              circleAvatarColor: circleAvatarColor,
              iconColor: iconColor,
              icon: icon,
              title: title,
              description: description,
            ),
            SizedBox(height: 64.h),

            CustomElevatedButton(
              width: 165,
              height: 40,
              title: targetScreen != null ? 'التالي' : 'العودة للرئيسية',
              onPressed: () {
                if (targetScreen != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => targetScreen!,
                    ),
                  );
                } else {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HomeScreen(),
                    ),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
