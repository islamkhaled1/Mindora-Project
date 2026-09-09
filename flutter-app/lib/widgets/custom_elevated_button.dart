// import 'package:flutter/material.dart';
// import 'package:flutter_easyloading/flutter_easyloading.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:sawa/app_text_styles.dart';

// class CustomElevatedButton extends StatelessWidget {
//   const CustomElevatedButton({
//     super.key,
//     required this.title,
//     required this.targetScreen,
//     this.height = 45,
//     this.width = double.infinity,
//   });

//   final Widget targetScreen;
//   final String title;
//   final double height;
//   final double width;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: height.h,
//       width: width.w,
//       child: ElevatedButton(
//         onPressed: () async {
//           EasyLoading.show(status: 'Loading');

//           try {
//             await EasyLoading.dismiss();
//             if (!context.mounted) return;
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (context) => targetScreen),
//             );
//           } catch (e) {
//             await EasyLoading.showError('There was an error, try again');
//           }
//         },
//         style: ElevatedButton.styleFrom(
//           backgroundColor: const Color(0xff8456D2),
//           shadowColor: Colors.black,
//           elevation: 5,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(15.r),
//           ),
//         ),
//         child: Text(
//           title,
//           style: AppTextStyles.font700Bold.copyWith(
//             color: Colors.white,
//             fontSize: 16.sp,
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_text_styles.dart';

class CustomElevatedButton extends StatelessWidget {
  const CustomElevatedButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.height = 45,
    this.width = double.infinity,
    this.isLoading = false,
  });

  final String title;
  final VoidCallback? onPressed;
  final double height;
  final double width;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height.h,
      width: width.w,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff8456D2),
          disabledBackgroundColor: const Color(
            0xff8456D2,
          ).withValues(alpha: 0.6),
          shadowColor: Colors.black,
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.r),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 20.h,
                width: 20.h,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                title,
                style: AppTextStyles.font700Bold.copyWith(
                  color: Colors.white,
                  fontSize: 16.sp,
                ),
              ),
      ),
    );
  }
}
