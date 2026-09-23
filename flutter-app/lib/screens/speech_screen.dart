import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_colors.dart';
import 'package:sawa/app_icons.dart';
import 'package:sawa/screens/encouragement_screen.dart';
import 'package:sawa/screens/practise_instruction_attention.dart';
import 'package:sawa/widgets/ai_status_banner.dart';
import 'package:sawa/widgets/back_icon.dart';
import 'package:sawa/widgets/custom_app_bar.dart';
import 'package:sawa/widgets/custom_elevated_button.dart';
import 'package:sawa/widgets/custom_padding.dart';
import 'package:sawa/widgets/custom_title.dart';
import 'package:sawa/widgets/icon_circle_avatar.dart';

/// Interactive UI training screen for Speech/Pronunciation.
/// Clarifies that interactive training is available now, while advanced
/// AI audio/speech analysis model is currently in development.
class SpeechScreen extends StatefulWidget {
  const SpeechScreen({super.key});

  @override
  State<SpeechScreen> createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  bool _isRecording = false;

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: CustomAppBar(
        leading: const BackIcon(),
        title: const CustomTitle(title: 'قولها معايا', fontSize: 22),
      ),
      body: SingleChildScrollView(
        child: CustomPadding(
          child: Column(
            children: [
              SizedBox(height: 12.h),

              // AI Status Banner - Transparent messaging
              const AiStatusBanner(
                compact: true,
                domainName: 'النطق والكلام',
                title: 'تحليل الكلام بالـ AI قريبًا',
                description:
                    'نعمل حاليًا على تطوير نموذج AI مخصص لدعم وتحليل مهارات النطق.',
              ),

              SizedBox(height: 20.h),
              const Center(
                child: CustomTitle(title: 'انظر ثم استمع', fontSize: 22),
              ),
              SizedBox(height: 16.h),
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CustomTitle(title: 'تفاحة', fontSize: 36),
                          SizedBox(height: 8.h),
                          Center(
                            child: Image.asset(
                              'assets/images/red_apple.png',
                              width: 170.w,
                              height: 150.h,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: -32.r,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: _toggleRecording,
                          child: IconCircleAvatar(
                            radius: 32,
                            iconSize: 32,
                            icon: _isRecording
                                ? AppIcons.stopRecord
                                : AppIcons.mic,
                            color: Colors.white,
                            backgroundColor: _isRecording
                                ? AppColors.darkRed
                                : AppColors.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 48.h),
              CustomTitle(
                title: _isRecording
                    ? 'جاري الاستماع والتسجيل ...'
                    : 'اضغط على المايك وحاول نطق الكلمة',
                fontSize: 16,
              ),
              SizedBox(height: 32.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: CustomElevatedButton(
                      backgroundColor: Colors.white,
                      textColor: AppColors.primaryColor,
                      title: 'اسمع مرة أخرى',
                      onPressed: () {},
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: CustomElevatedButton(
                      title: 'التالي',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EncouragementScreen(
                              exerciseName: "قولها معايا",
                              circleAvatarColor: AppColors.circleAvatarColor,
                              iconColor: AppColors.primaryColor,
                              icon: AppIcons.speaker,
                              title: 'تمرين: قولها معايا',
                              description: 'تم إكمال جميع الأنشطة بنجاح',
                              targetScreen: PractiseInstructionAttention(),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}
