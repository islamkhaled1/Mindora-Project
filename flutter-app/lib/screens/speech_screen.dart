// import 'package:audioplayers/audioplayers.dart';
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

// class SpeechScreen extends StatelessWidget {
//   SpeechScreen({super.key});
//   final AudioPlayer player = AudioPlayer();
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.backgroundColor,
//       appBar: CustomAppBar(
//         leading: BackIcon(),
//         title: CustomTitle(title: 'قولها معايا', fontSize: 22),
//       ),
//       body: CustomPadding(
//         child: Column(
//           children: [
//             SizedBox(height: 32.h),
//             Center(child: CustomTitle(title: 'انظر ثم استمع', fontSize: 24)),
//             SizedBox(height: 32.h),
//             Container(
//               width: double.infinity,
//               height: 250.h,
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
//               child: Stack(
//                 clipBehavior: Clip.none,
//                 children: [
//                   Positioned(
//                     left: 0,
//                     top: 0,
//                     child: IconCircleAvatar(
//                       icon: AppIcons.speaker,
//                       color: AppColors.primaryColor,
//                       backgroundColor: AppColors.circleAvatarColor,
//                       iconSize: 28,
//                     ),
//                   ),

//                   Center(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         CustomTitle(title: 'تفاحة', fontSize: 40),
//                         Center(
//                           child: Image.asset(
//                             'assets/images/red_apple.png',
//                             width: 200.w,
//                             height: 180.h,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Positioned(
//                     bottom: -60.r,
//                     left: 0,
//                     right: 0,
//                     child: Center(
//                       child: IconCircleAvatar(
//                         radius: 35,
//                         iconSize: 35,
//                         icon: AppIcons.mic,
//                         color: Colors.white,
//                         backgroundColor: AppColors.primaryColor,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 46.h),
//             CustomTitle(title: 'حاول تقول الكلمة', fontSize: 20),
//             SizedBox(height: 64),
//             Row(
//               children: [
//                 CustomElevatedButton(
//                   backgroundColor: Colors.white,
//                   textColor: AppColors.primaryColor,
//                   width: 140.w,
//                   title: 'اسمع مرة أخرى',
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => EncouragementScreen(),
//                       ),
//                     );
//                   },
//                 ),
//                 SizedBox(width: 10.w),
//                 CustomElevatedButton(
//                   width: 130.w,
//                   title: 'التالي',
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => EncouragementScreen(),
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

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:sawa/app_colors.dart';
import 'package:sawa/app_icons.dart';
import 'package:sawa/screens/encouragement_screen.dart';
import 'package:sawa/widgets/back_icon.dart';
import 'package:sawa/widgets/custom_app_bar.dart';
import 'package:sawa/widgets/custom_elevated_button.dart';
import 'package:sawa/widgets/custom_padding.dart';
import 'package:sawa/widgets/custom_title.dart';
import 'package:sawa/widgets/icon_circle_avatar.dart';

class SpeechScreen extends StatefulWidget {
  const SpeechScreen({super.key});

  @override
  State<SpeechScreen> createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  final AudioPlayer player = AudioPlayer();
  final AudioRecorder _audioRecorder = AudioRecorder();

  bool _isRecording = false;
  String? _audioPath;

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      setState(() {
        _isRecording = false;
      });

      final path = await _audioRecorder.stop();

      setState(() {
        _audioPath = path;
      });
    } else {
      final hasPermission = await _audioRecorder.hasPermission();

      if (!hasPermission) {
        return;
      }

      final directory = await getTemporaryDirectory();

      final path =
          '${directory.path}/pronunciation_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(const RecordConfig(), path: path);

      setState(() {
        _isRecording = true;
        _audioPath = null;
      });
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: CustomAppBar(
        leading: BackIcon(),
        title: CustomTitle(title: 'قولها معايا', fontSize: 22),
      ),
      body: CustomPadding(
        child: Column(
          children: [
            SizedBox(height: 32.h),

            Center(child: CustomTitle(title: 'انظر ثم استمع', fontSize: 24)),

            SizedBox(height: 32.h),

            Container(
              width: double.infinity,
              height: 250.h,
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
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    child: IconCircleAvatar(
                      icon: AppIcons.speaker,
                      color: AppColors.primaryColor,
                      backgroundColor: AppColors.circleAvatarColor,
                      iconSize: 28,
                    ),
                  ),

                  Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CustomTitle(title: 'تفاحة', fontSize: 40),
                        Center(
                          child: Image.asset(
                            'assets/images/red_apple.png',
                            width: 200.w,
                            height: 180.h,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Positioned(
                    bottom: -60.r,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: _toggleRecording,
                        child: IconCircleAvatar(
                          radius: 35,
                          iconSize: 35,
                          icon: _isRecording
                              ? AppIcons.stopRecord
                              : AppIcons.mic,
                          color: Colors.white,
                          backgroundColor: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 46.h),

            CustomTitle(
              title: _isRecording ? 'جاري التسجيل ...' : 'حاول تقول الكلمة',
              fontSize: 20,
            ),

            SizedBox(height: 64),

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
                          exerciseName: "قولها معايا",
                          circleAvatarColor: AppColors.circleAvatarColor,
                          iconColor: AppColors.primaryColor,
                          icon: AppIcons.speaker,
                          title: 'تمرين: قولها معايا',
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
