import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sawa/constants.dart';
import 'package:sawa/core/state/auth_state.dart';
import 'package:sawa/screens/home_screen.dart';
import 'package:sawa/screens/splash.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _hasNavigated = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer(const Duration(milliseconds: 1500), () {
      _navigateNext();
    });
  }

  void _navigateNext() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    _timer?.cancel();

    final isAuthenticated = AuthState.instance.isAuthenticated;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => isAuthenticated ? const HomeScreen() : Splash1(),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Center(
        child: GestureDetector(
          onTap: _navigateNext,
          child: Image.asset('assets/images/logo.png'),
        ),
      ),
    );
  }
}
