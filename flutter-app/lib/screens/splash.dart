import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/constants.dart';
import 'package:sawa/screens/log_in_screen.dart';
import 'package:sawa/widgets/back_icon.dart';
import 'package:sawa/widgets/custom_app_bar.dart';
import 'package:sawa/widgets/splash.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class Splash1 extends StatelessWidget {
  Splash1({super.key});
  final PageController _pageController = PageController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: CustomAppBar(
        leading: BackIcon(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LogInScreen()),
                );
              },
              child: Text(
                'تخطي',
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 16.sp,
                  fontFamily: 'Readex Pro',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),

      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            children: [
              Splash(
                image: 'assets/images/Frame1.png',
                title: 'أنشئ خطة علاجية\n مخصصة لطفلك',
                text:
                    'أضف أهدافًا وتمارين تناسب احتياجات طفلك\n مع إرشادات من المتخصصين.',
              ),
              Splash(
                image: 'assets/images/Frame2.png',
                title: 'تتبّع التقدم باستخدام \nالذكاء الاصطناعي',
                text:
                    ' قوم الذكاء الاصطناعي لدينا بتحليل الأداء وإظهار التحسن\n واقتراح ما يجب التركيز عليه بعد ذلك.',
              ),
              Splash(
                image: 'assets/images/frame3.png',
                title: 'نتعاون لنصنع أثراً\n في حياة طفلك',
                text:
                    'ابقَ على تواصل مع المتخصصين وقم بتحديث الخطة\nوادعم طفلك في كل خطوة على الطريق.',
              ),
            ],
          ),
          Positioned(
            bottom: 110.h,
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: _pageController,
                count: 3,
                effect: SlideEffect(
                  spacing: 8,
                  radius: 6,
                  dotWidth: 12,
                  dotHeight: 12,
                  dotColor: Color(0xffD9D3E5),
                  activeDotColor: Color(0xff8456D2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
