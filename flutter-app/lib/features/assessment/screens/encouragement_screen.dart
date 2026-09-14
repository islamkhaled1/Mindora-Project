import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/core/constants/app_colors.dart';
import 'package:sawa/core/widgets/buttons/custom_elevated_button.dart';
import 'package:sawa/core/widgets/common/custom_padding.dart';
import 'package:sawa/core/widgets/common/custom_title.dart';
import 'package:sawa/core/widgets/common/description.dart';
import 'package:sawa/core/widgets/icons/success_check_icon.dart';
import 'package:sawa/core/widgets/navigation/back_icon.dart';
import 'package:sawa/core/widgets/navigation/custom_app_bar.dart';
import 'package:sawa/features/assessment/widgets/encouragement_list_tile.dart';

class EncouragementScreen extends StatelessWidget {
  const EncouragementScreen({
    super.key,
    required this.circleAvatarColor,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.description,
    required this.exerciseName,
    required this.targetScreen,
  });
  final Color circleAvatarColor;
  final Color iconColor;
  final String icon;
  final String title;
  final String description;
  final String exerciseName;
  final Widget targetScreen;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: CustomAppBar(leading: BackIcon()),
      body: CustomPadding(
        child: Column(
          children: [
            SizedBox(height: 70.h),
            Center(child: SuccessCheckIcon()),
            SizedBox(height: 32.h),
            CustomTitle(title: 'أحسنت يا بطل', fontSize: 26),
            SizedBox(height: 12.h),
            Description(
              text:
                  'لقد أكملت تمرين ${exerciseName} بنجاح.\nاستمر  هكذا، أنت رائع',
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
              title: 'التالي',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => targetScreen),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
