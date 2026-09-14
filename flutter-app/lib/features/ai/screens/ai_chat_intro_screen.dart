import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/core/constants/app_colors.dart';
import 'package:sawa/core/widgets/buttons/custom_elevated_button.dart';
import 'package:sawa/core/widgets/common/custom_padding.dart';
import 'package:sawa/core/widgets/common/description.dart';
import 'package:sawa/core/widgets/common/medium_title.dart';
import 'package:sawa/core/widgets/navigation/back_icon.dart';
import 'package:sawa/core/widgets/navigation/custom_app_bar.dart';
import 'package:sawa/features/ai/screens/ai_chat_screen.dart';

class AiChatIntroScreen extends StatelessWidget {
  const AiChatIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: CustomAppBar(
        leading: BackIcon(),
        title: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0.r),
              child: MediumTitle(title: 'مساعد الذكاء الاصطناعي', fontSize: 14),
            ),
            Description(text: 'رفيقك الذكي للدعم', fontSize: 12),
          ],
        ),
      ),
      body: CustomPadding(
        child: Column(
          children: [
            SizedBox(height: 80.h),
            Positioned(
              child: SizedBox(
                height: 300.h,
                width: double.infinity,
                child: Stack(
                  children: [
                    Positioned(
                      right: 0,
                      top: 25.r,
                      child: Container(
                        width: 180.w,
                        height: 120.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.white,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(15.0.r),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              MediumTitle(title: 'أهلاً', fontSize: 14),
                              SizedBox(height: 10.h),
                              MediumTitle(
                                align: TextAlign.start,
                                title:
                                    'أنا هنا لمساعدتك\n بالنصائح والأنشطة والإرشادات.',
                                fontSize: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Image.asset(
                        'assets/images/fourthBot.png',
                        width: 200.w,
                        height: 250.h,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 64.h),
            CustomElevatedButton(
              width: 220.w,
              title: ' بدء المحادثة',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AiChatScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
