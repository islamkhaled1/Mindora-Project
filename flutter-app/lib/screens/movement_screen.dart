import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_colors.dart';
import 'package:sawa/app_icons.dart';
import 'package:sawa/screens/celebration_screen.dart';
import 'package:sawa/screens/encouragement_screen.dart';
import 'package:sawa/screens/practise_result_screen.dart';
import 'package:sawa/widgets/back_icon.dart';
import 'package:sawa/widgets/custom_app_bar.dart';
import 'package:sawa/widgets/custom_elevated_button.dart';
import 'package:sawa/widgets/custom_padding.dart';
import 'package:sawa/widgets/custom_title.dart';
import 'package:sawa/widgets/medium_title.dart';

class MovementScreen extends StatefulWidget {
  const MovementScreen({
    super.key,
    this.appBarTitle = const CustomTitle(title: 'اتبع الحركة', fontSize: 22),
    this.isExercise = false,
  });

  final Widget appBarTitle;
  final bool isExercise;

  @override
  State<MovementScreen> createState() => _MovementScreenState();
}

class _MovementScreenState extends State<MovementScreen> {
  CameraController? cameraController;
  Timer? timer;
  final Random random = Random();

  double starLeft = 50;
  double starTop = 50;
  bool isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    initializeCamera();
    startStarMovement();
  }

  Future<void> initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await cameraController!.initialize();
      if (!mounted) return;

      setState(() {
        isCameraInitialized = true;
      });

      startCameraStream();
    } catch (_) {
      // Camera permission or hardware not available - continue with visual animation
    }
  }

  Future<void> stopCamera() async {
    if (cameraController == null) return;
    try {
      if (cameraController!.value.isStreamingImages) {
        await cameraController!.stopImageStream();
      }
      await cameraController!.dispose();
    } catch (_) {}
    cameraController = null;
  }

  void startCameraStream() {
    if (cameraController == null || !cameraController!.value.isInitialized) return;
    try {
      cameraController!.startImageStream((CameraImage image) {
        processFrame(image);
      });
    } catch (_) {}
  }

  void processFrame(CameraImage image) {
    // Frame processing hook for pose/landmark detection
  }

  void startStarMovement() {
    timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        starLeft = random.nextDouble() * 150.w;
        starTop = random.nextDouble() * 180.h;
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: CustomAppBar(
        leading: const BackIcon(),
        title: widget.appBarTitle,
      ),
      body: CustomPadding(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 24.h),
              Center(
                child: Container(
                  width: 220.w,
                  height: 36.h,
                  decoration: BoxDecoration(
                    color: AppColors.notificationColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: MediumTitle(
                      title: 'حرك يدك لتصل إلى الهدف',
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      'assets/images/background.png',
                      width: double.infinity,
                      height: 320.h,
                      fit: BoxFit.cover,
                    ),
                    if (isCameraInitialized && cameraController != null)
                      Opacity(
                        opacity: 0.35,
                        child: SizedBox(
                          height: 320.h,
                          width: double.infinity,
                          child: CameraPreview(cameraController!),
                        ),
                      ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeInOut,
                      left: starLeft + 40.w,
                      top: starTop + 40.h,
                      child: Image.asset(
                        'assets/images/movement_star.png',
                        width: 55.w,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 48.h),
              CustomElevatedButton(
                width: 160.w,
                title: 'التالي',
                onPressed: () async {
                  await stopCamera();
                  if (!context.mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => widget.isExercise
                          ? const CelebrationScreen()
                          : const EncouragementScreen(
                              circleAvatarColor: AppColors.lightOrange,
                              iconColor: AppColors.dartOrange,
                              icon: AppIcons.running,
                              title: 'تمرين: اتبع الحركة',
                              description: 'تم إكمال جميع الأنشطة بنجاح',
                              exerciseName: 'اتبع الحركة',
                              targetScreen: PractiseResultScreen(),
                            ),
                    ),
                  );
                },
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}
