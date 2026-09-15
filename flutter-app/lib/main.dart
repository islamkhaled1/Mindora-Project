import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_colors.dart';
import 'package:sawa/screens/home_nav_screen.dart';
import 'package:sawa/screens/onboarding_screen.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'core/state/auth_state.dart';

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureEasyLoading();
  AuthState.instance.initialize();
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
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: HomeNavScreen(),
          builder: EasyLoading.init(),
        );
      },
    );
  }
}
