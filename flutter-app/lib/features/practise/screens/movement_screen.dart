import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/core/constants/app_colors.dart';
import 'package:sawa/core/constants/app_icons.dart';
import 'package:sawa/core/widgets/buttons/custom_elevated_button.dart';
import 'package:sawa/core/widgets/common/custom_padding.dart';
import 'package:sawa/core/widgets/common/custom_title.dart';
import 'package:sawa/core/widgets/common/medium_title.dart';
import 'package:sawa/core/widgets/navigation/back_icon.dart';
import 'package:sawa/core/widgets/navigation/custom_app_bar.dart';
import 'package:sawa/features/assessment/screens/celebration_screen.dart';
import 'package:sawa/features/assessment/screens/encouragement_screen.dart';
import 'package:sawa/features/practise/screens/practise_result_screen.dart';

class MovementScreen extends StatefulWidget {
  const MovementScreen({
    super.key,
    this.appBarTitle = const CustomTitle(title: 'قولها معايا', fontSize: 22),
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

  // =========================
  // Camera
  // =========================

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();

    if (cameras.isEmpty) {
      return;
    }

    // نستخدم الكاميرا الأمامية
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
  }

  Future<void> stopCamera() async {
    if (cameraController == null) return;

    if (cameraController!.value.isStreamingImages) {
      await cameraController!.stopImageStream();
    }

    await cameraController!.dispose();
    cameraController = null;
  }

  void startCameraStream() {
    if (cameraController == null) return;

    cameraController!.startImageStream((CameraImage image) {
      processFrame(image);
    });
  }

  // =========================
  // Frame Processing
  // =========================

  void processFrame(CameraImage image) {
    // ==================================================
    // MediaPipe integration will be added here later
    // ==================================================

    // مثال:
    //
    // final landmarks = await mediaPipeModel.processFrame(image);
    //
    // if (landmarks != null) {
    //   checkHandPosition(landmarks);
    // }

    // حاليًا بنستقبل الـ frames فقط
  }

  // =========================
  // Star Movement
  // =========================

  void startStarMovement() {
    timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;

      setState(() {
        starLeft = random.nextDouble() * 150.w;
        starTop = random.nextDouble() * 200.h;
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();

    cameraController?.dispose();

    super.dispose();
  }

  // =========================
  // UI
  // =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        leading: BackIcon(),
        title: CustomTitle(title: 'اتبع الحركة', fontSize: 22),
      ),

      body: CustomPadding(
        child: Column(
          children: [
            SizedBox(height: 32.h),

            Center(
              child: Container(
                width: 200.w,
                height: 30.h,
                decoration: BoxDecoration(
                  color: AppColors.notificationColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: MediumTitle(
                    title: 'حرك يدك لتصل إلى الهدف',
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            SizedBox(height: 64.h),

            Stack(
              children: [
                Image.asset(
                  'assets/images/background.png',
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),

                AnimatedPositioned(
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeInOut,
                  left: starLeft,
                  top: starTop,
                  child: Image.asset(
                    'assets/images/movement_star.png',
                    width: 50.w,
                  ),
                ),
              ],
            ),
            SizedBox(height: 64.h),
            CustomElevatedButton(
              width: 150.w,
              title: 'التالي',
              onPressed: () async {
                await stopCamera();
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => widget.isExercise
                        ? CelebrationScreen()
                        : EncouragementScreen(
                            circleAvatarColor: AppColors.lightOrange,
                            iconColor: AppColors.dartOrange,
                            icon: AppIcons.running,
                            title: 'تمرين: اتبع الحركة',
                            description: 'تم إكمال جميع الأنشطة بنجاح',
                            exerciseName: '"اتبع الحركة"',
                            targetScreen: PractiseResultScreen(),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
