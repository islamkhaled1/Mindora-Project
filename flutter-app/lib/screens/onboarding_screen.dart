import 'package:flutter/material.dart';
import 'package:sawa/constants.dart';
import 'package:sawa/screens/splash.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Center(
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Splash1()),
            );
          },
          child: Image.asset('assets/images/logo.png'),
        ),
      ),
    );
  }
}
