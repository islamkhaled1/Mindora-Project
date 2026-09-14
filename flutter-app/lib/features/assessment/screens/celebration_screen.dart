import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/core/constants/app_colors.dart';
import 'package:sawa/core/widgets/buttons/custom_elevated_button.dart';
import 'package:sawa/core/widgets/common/custom_padding.dart';
import 'package:sawa/core/widgets/common/custom_title.dart';
import 'package:sawa/core/widgets/common/description.dart';
import 'package:sawa/core/widgets/navigation/back_icon.dart';
import 'package:sawa/core/widgets/navigation/custom_app_bar.dart';
import 'package:sawa/features/ai/screens/result_ai_screen.dart';

class CelebrationScreen extends StatelessWidget {
  const CelebrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: CustomAppBar(leading: BackIcon()),
      body: CustomPadding(
        child: Column(
          children: [
            SizedBox(height: 70.h),
            SizedBox(
              width: double.infinity,
              height: 350.h,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // الصورة
                  Positioned(
                    top: -40.h,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Image.asset(
                        'assets/images/thirdBot.png',
                        width: 220.w,
                        height: 190.h,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  Center(
                    child: Container(
                      height: 130.h,
                      width: 270.w,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 18.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomTitle(title: 'عمل رائع', fontSize: 20),
                          SizedBox(height: 8.h),
                          Description(
                            text: 'لقد أكملت التقييم بنجاح.',
                            fontSize: 14,
                            color: AppColors.primaryColor,
                          ),
                          SizedBox(height: 5.h),
                          Description(
                            text: 'نتائجك جاهزة لوالدك/والدتك.',
                            fontSize: 14,
                            color: AppColors.primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            CustomElevatedButton(
              width: 150.w,
              title: 'عرض النتائج',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ResultAiScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
