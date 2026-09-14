import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:sawa/core/constants/app_colors.dart';
import 'package:sawa/features/onboarding/screens/onboarding_screen.dart';

void configureEasyLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorWidget = const CircularProgressIndicator(
      color: AppColors.primaryColor,
    )
    ..loadingStyle = EasyLoadingStyle.custom
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..progressColor = AppColors.primaryColor
    ..backgroundColor = Colors.white
    ..indicatorColor = AppColors.primaryColor
    ..textColor = AppColors.primaryColor
    ..userInteractions = false
    ..dismissOnTap = false;
}

final _easyLoadingBuilder = EasyLoading.init();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  configureEasyLoading();
  runApp(const SAWA());
}

class SAWA extends StatelessWidget {
  const SAWA({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            home: OnboardingScreen(),
            builder: _easyLoadingBuilder,
          ),
        );
      },
    );
  }
}
