// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:sawa/app_colors.dart';
// import 'package:sawa/app_icons.dart';
// import 'package:sawa/screens/encouragement_screen.dart';
// import 'package:sawa/widgets/back_icon.dart';
// import 'package:sawa/widgets/custom_app_bar.dart';
// import 'package:sawa/widgets/custom_elevated_button.dart';
// import 'package:sawa/widgets/custom_padding.dart';
// import 'package:sawa/widgets/custom_title.dart';
// import 'package:sawa/widgets/icon_circle_avatar.dart';

// class AttentionScreen extends StatelessWidget {
//   AttentionScreen({super.key});
//   final List<String> images = [
//     'assets/images/cat.png',
//     'assets/images/car.png',
//     'assets/images/star.png',
//     'assets/images/Ball.png',
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.backgroundColor,
//       appBar: CustomAppBar(
//         leading: BackIcon(),
//         title: CustomTitle(title: 'اسمع وابحث', fontSize: 22),
//       ),
//       body: CustomPadding(
//         child: Column(
//           children: [
//             SizedBox(height: 32.h),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 CustomTitle(title: 'أين النجمة', fontSize: 32),
//                 IconCircleAvatar(
//                   padding: 6,
//                   iconSize: 30,
//                   icon: AppIcons.speaker,
//                   color: AppColors.primaryColor,
//                   backgroundColor: AppColors.circleAvatarColor,
//                 ),
//               ],
//             ),
//             SizedBox(height: 32.h),
//             Container(
//               padding: EdgeInsets.all(10),
//               width: double.infinity,
//               height: 280.h,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(15.r),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withValues(alpha: 0.25),
//                     blurRadius: 8,
//                     offset: const Offset(0, 3),
//                   ),
//                 ],
//               ),
//               child: GridView.builder(
//                 itemCount: 4,
//                 gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: 2,
//                   mainAxisSpacing: 5.r,
//                   crossAxisSpacing: 15.r,
//                 ),
//                 itemBuilder: (buildContext, index) {
//                   return Container(
//                     margin: EdgeInsets.all(8.r),
//                     width: 120.w,
//                     height: 90.h,
//                     decoration: BoxDecoration(
//                       color: AppColors.cardsColor,
//                       borderRadius: BorderRadius.circular(15.r),
//                     ),
//                     child: Center(child: Image.asset(images[index])),
//                   );
//                 },
//               ),
//             ),
//             SizedBox(height: 64),

//             Row(
//               children: [
//                 CustomElevatedButton(
//                   backgroundColor: Colors.white,
//                   textColor: AppColors.primaryColor,
//                   width: 140.w,
//                   title: 'اسمع مرة أخرى',
//                   onPressed: () {},
//                 ),

//                 SizedBox(width: 10.w),

//                 CustomElevatedButton(
//                   width: 130.w,
//                   title: 'التالي',
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => EncouragementScreen(
//                           exerciseName: "اسمع وابحث",
//                           circleAvatarColor: AppColors.lightGreen,
//                           iconColor: AppColors.darkGreen,
//                           icon: AppIcons.brain,
//                           title: 'تمرين: اسمع وابحث',
//                           description: 'تم إكمال جميع الأنشطة بنجاح',
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_colors.dart';
import 'package:sawa/app_icons.dart';
import 'package:sawa/screens/encouragement_screen.dart';
import 'package:sawa/widgets/back_icon.dart';
import 'package:sawa/widgets/custom_app_bar.dart';
import 'package:sawa/widgets/custom_elevated_button.dart';
import 'package:sawa/widgets/custom_padding.dart';
import 'package:sawa/widgets/custom_title.dart';
import 'package:sawa/widgets/icon_circle_avatar.dart';

class AttentionScreen extends StatefulWidget {
  AttentionScreen({super.key});

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
      appBar: CustomAppBar(
        leading: BackIcon(),
        title: CustomTitle(title: 'اسمع وابحث', fontSize: 22),
      ),
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
                CustomElevatedButton(
                  backgroundColor: Colors.white,
                  textColor: AppColors.primaryColor,
                  width: 140.w,
                  title: 'اسمع مرة أخرى',
                  onPressed: () {},
                ),

                SizedBox(width: 10.w),

                CustomElevatedButton(
                  width: 130.w,
                  title: 'التالي',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EncouragementScreen(
                          exerciseName: "اسمع وابحث",
                          circleAvatarColor: AppColors.lightGreen,
                          iconColor: AppColors.darkGreen,
                          icon: AppIcons.brain,
                          title: 'تمرين: اسمع وابحث',
                          description: 'تم إكمال جميع الأنشطة بنجاح',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
