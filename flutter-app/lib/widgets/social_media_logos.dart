import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SocialMediaLogos extends StatelessWidget {
  final VoidCallback? onGoogleTap;
  final VoidCallback? onFacebookTap;
  final VoidCallback? onAppleTap;

  const SocialMediaLogos({
    super.key,
    this.onGoogleTap,
    this.onFacebookTap,
    this.onAppleTap,
  });

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('متاح في التحديث القادم'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          key: const Key('google_sign_in_button'),
          onTap: onGoogleTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.r),
            child: Image.asset(
              'assets/images/google.png',
              height: 25.h,
              width: 25.w,
            ),
          ),
        ),
        GestureDetector(
          key: const Key('facebook_sign_in_button'),
          onTap: onFacebookTap ?? () => _showComingSoon(context),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.r),
            child: Image.asset(
              'assets/images/facebook.png',
              height: 25.h,
              width: 25.w,
            ),
          ),
        ),
        GestureDetector(
          key: const Key('apple_sign_in_button'),
          onTap: onAppleTap ?? () => _showComingSoon(context),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.r),
            child: Image.asset(
              'assets/images/apple.png',
              height: 25.h,
              width: 25.w,
            ),
          ),
        ),
      ],
    );
  }
}
