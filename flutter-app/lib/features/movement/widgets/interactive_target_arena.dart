import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_text_styles.dart';
import 'package:sawa/constants.dart';
import '../engine/movement_engine.dart';
import '../models/hand_tracking_result.dart';
import '../models/movement_reach_event.dart';
import '../services/hand_tracker_service.dart';

/// Interactive Star Target Arena for Movement Activities.
///
/// Combines:
/// - Real front camera preview (mirrored horizontally for intuitive interaction)
/// - Bounded dynamic Star Target in normalized coordinates [0.15, 0.85]
/// - Real-time hand landmark indicator (fingertip Landmark 8 / Landmark 9)
/// - Success glow animations and reaction time badges
/// - Live telemetry HUD (repetitions, derived accuracy %, reaction time ms, tracking status)
/// - Graceful fallback UI for camera permissions or missing hardware
class InteractiveTargetArena extends StatefulWidget {
  final MovementEngine engine;
  final HandTrackerService trackerService;
  final VoidCallback? onMetricsUpdated;

  const InteractiveTargetArena({
    super.key,
    required this.engine,
    required this.trackerService,
    this.onMetricsUpdated,
  });

  @override
  State<InteractiveTargetArena> createState() => _InteractiveTargetArenaState();
}

class _InteractiveTargetArenaState extends State<InteractiveTargetArena>
    with SingleTickerProviderStateMixin {
  HandTrackingResult _latestTracking = const HandTrackingResult.untracked();
  MovementReachEvent? _lastReachEvent;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  double? _arenaWidth;
  double? _arenaHeight;

  /// Remap normalized coordinates from camera space to the arena viewport space.
  /// This compensates for BoxFit.cover scaling and cropping, ensuring visual 1:1 alignment.
  Offset _mapCameraToArena({
    required double normX,
    required double normY,
    required double arenaWidth,
    required double arenaHeight,
    required double camWidth,
    required double camHeight,
  }) {
    if (camWidth <= 0 || camHeight <= 0) return Offset(normX, normY);

    final scale = max(arenaWidth / camWidth, arenaHeight / camHeight);
    final scaledW = camWidth * scale;
    final scaledH = camHeight * scale;

    final cropX = (scaledW - arenaWidth) / 2.0;
    final cropY = (scaledH - arenaHeight) / 2.0;

    final pixelX = (normX * scaledW) - cropX;
    final pixelY = (normY * scaledH) - cropY;

    return Offset(
      (pixelX / arenaWidth).clamp(0.0, 1.0),
      (pixelY / arenaHeight).clamp(0.0, 1.0),
    );
  }

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    widget.trackerService.trackingStream.listen((result) {
      if (mounted) {
        // Remap camera normalized coordinates to arena visual coordinates so
        // touching the target on screen mathematically aligns 1:1 with screen space!
        final controller = widget.trackerService.cameraController;
        final camW = controller?.value.previewSize?.height;
        final camH = controller?.value.previewSize?.width;

        HandTrackingResult mappedResult = result;
        if (result.isTracked &&
            camW != null &&
            camH != null &&
            _arenaWidth != null &&
            _arenaHeight != null &&
            _arenaWidth! > 0 &&
            _arenaHeight! > 0) {
          final mappedPrimary = _mapCameraToArena(
            normX: result.x,
            normY: result.y,
            arenaWidth: _arenaWidth!,
            arenaHeight: _arenaHeight!,
            camWidth: camW,
            camHeight: camH,
          );

          Offset? mappedLm8;
          if (result.landmark8X != null && result.landmark8Y != null) {
            mappedLm8 = _mapCameraToArena(
              normX: result.landmark8X!,
              normY: result.landmark8Y!,
              arenaWidth: _arenaWidth!,
              arenaHeight: _arenaHeight!,
              camWidth: camW,
              camHeight: camH,
            );
          }

          Offset? mappedLm9;
          if (result.landmark9X != null && result.landmark9Y != null) {
            mappedLm9 = _mapCameraToArena(
              normX: result.landmark9X!,
              normY: result.landmark9Y!,
              arenaWidth: _arenaWidth!,
              arenaHeight: _arenaHeight!,
              camWidth: camW,
              camHeight: camH,
            );
          }

          mappedResult = HandTrackingResult(
            x: mappedPrimary.dx,
            y: mappedPrimary.dy,
            confidence: result.confidence,
            isTracked: true,
            landmarkUsed: result.landmarkUsed,
            timestampMs: result.timestampMs,
            landmark8X: mappedLm8?.dx,
            landmark8Y: mappedLm8?.dy,
            landmark9X: mappedLm9?.dx,
            landmark9Y: mappedLm9?.dy,
          );
        }

        setState(() {
          _latestTracking = mappedResult;
        });

        final target = widget.engine.currentTarget;
        final dist = (mappedResult.isTracked && target != null)
            ? sqrt(pow(mappedResult.x - target.targetX, 2) + pow(mappedResult.y - target.targetY, 2))
            : null;

        debugPrint(
          '[MovementDebug] isTracked: ${mappedResult.isTracked}, '
          'hand: (${mappedResult.x.toStringAsFixed(3)}, ${mappedResult.y.toStringAsFixed(3)}), '
          'lm8: (${mappedResult.landmark8X?.toStringAsFixed(3)}, ${mappedResult.landmark8Y?.toStringAsFixed(3)}), '
          'lm9: (${mappedResult.landmark9X?.toStringAsFixed(3)}, ${mappedResult.landmark9Y?.toStringAsFixed(3)}), '
          'target: (${target?.targetX.toStringAsFixed(3)}, ${target?.targetY.toStringAsFixed(3)}), '
          'dist: ${dist?.toStringAsFixed(3)} (threshold: ${target?.targetRadius}), '
          'conf: ${mappedResult.confidence.toStringAsFixed(2)}, '
          'lm: ${mappedResult.landmarkUsed}, state: ${widget.engine.state.name}'
        );

        // Feed mapped tracking into movement engine
        final reach = widget.engine.processFrame(
          tracking: mappedResult,
          currentTimestampMs: DateTime.now().millisecondsSinceEpoch,
        );

        if (reach != null) {
          debugPrint(
            '[MovementDebug] *** REACH EVENT TRIGGERED! *** '
            'reps: ${widget.engine.repetitions}, reactionTime: ${reach.reactionTimeMs}ms'
          );
          setState(() {
            _lastReachEvent = reach;
          });
          widget.onMetricsUpdated?.call();
        }
      }
    });

    widget.engine.onReach = (reach) {
      debugPrint('[MovementDebug] engine.onReach callback: targetId=${reach.targetId}, reps=${widget.engine.repetitions}');
      if (mounted) {
        setState(() {
          _lastReachEvent = reach;
        });
        widget.onMetricsUpdated?.call();
      }
    };

    widget.engine.onTargetExpired = (target) {
      debugPrint('[MovementDebug] engine.onTargetExpired: targetId=${target.targetId}, failedAttempts=${widget.engine.failedAttempts}');
      if (mounted) {
        setState(() {});
        widget.onMetricsUpdated?.call();
      }
    };

    widget.engine.onTargetSpawned = (target) {
      debugPrint('[MovementDebug] engine.onTargetSpawned: targetId=${target.targetId} at (${target.targetX.toStringAsFixed(3)}, ${target.targetY.toStringAsFixed(3)})');
      if (mounted) {
        setState(() {});
      }
    };
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.trackerService.status;

    if (status == CameraTrackingStatus.requestingPermission ||
        status == CameraTrackingStatus.initializing) {
      return _buildLoadingState('جاري تجهيز الكاميرا ونظام تتبع اليد الذكي...');
    }

    if (status == CameraTrackingStatus.permissionDenied ||
        status == CameraTrackingStatus.permissionPermanentlyDenied) {
      return _buildPermissionFallback(
        widget.trackerService.errorMessage ??
            'يرجى السماح بالوصول إلى الكاميرا لتتبع حركة يد الطفل بالذكاء الاصطناعي.',
      );
    }

    if (status == CameraTrackingStatus.cameraUnavailable ||
        status == CameraTrackingStatus.error) {
      return _buildErrorFallback(
        widget.trackerService.errorMessage ??
            'تعذر تشغيل الكاميرا على هذا الجهاز.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final arenaWidth = constraints.maxWidth;
        // 4:3 or 16:9 responsive arena height
        final arenaHeight = (arenaWidth * 1.1).clamp(280.0, 420.0);
        _arenaWidth = arenaWidth;
        _arenaHeight = arenaHeight;

        return Container(
          width: arenaWidth,
          height: arenaHeight,
          decoration: BoxDecoration(
            color: const Color(0xff120D26),
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(color: const Color(0xff8A47FE).withValues(alpha: 0.4), width: 1.8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff8A47FE).withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // 1. Mirrored Camera Preview Layer
              _buildCameraPreviewLayer(arenaWidth, arenaHeight),

              // 2. Arena Ambient Vignette / Tint
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.0,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.45),
                    ],
                  ),
                ),
              ),

              // 3. Dynamic Interactive Star Target Layer
              _buildTargetLayer(arenaWidth, arenaHeight),

              // 4. Hand Tracking Reticle / Cursor
              _buildHandReticleLayer(arenaWidth, arenaHeight),

              // 5. Reach Success Feedback Splash
              if (widget.engine.state == MovementEngineState.reached && _lastReachEvent != null)
                _buildReachSplashBadge(_lastReachEvent!),

              // 6. Modern Real-time Telemetry HUD (Reps, Accuracy, Reaction Time)
              Positioned(
                top: 10.h,
                left: 10.w,
                right: 10.w,
                child: _buildTelemetryHUD(),
              ),

              // 7. Status Banner at Bottom
              Positioned(
                bottom: 8.h,
                left: 12.w,
                right: 12.w,
                child: _buildTrackingStatusBadge(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCameraPreviewLayer(double width, double height) {
    final controller = widget.trackerService.cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return Container(
        color: const Color(0xff1A1438),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryColor),
        ),
      );
    }

    // Mirror horizontally for front-facing camera natural interaction
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
      child: SizedBox(
        width: width,
        height: height,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.previewSize?.height ?? width,
            height: controller.value.previewSize?.width ?? height,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }

  Widget _buildTargetLayer(double width, double height) {
    final target = widget.engine.currentTarget;
    if (target == null) return const SizedBox.shrink();

    // Map normalized coordinates [0.15, 0.85] to arena pixel coordinates
    final targetPixelX = target.targetX * width;
    final targetPixelY = target.targetY * height;
    final targetPixelRadius = max(24.0, target.targetRadius * min(width, height));

    final isReached = widget.engine.state == MovementEngineState.reached;
    final isCooldown = widget.engine.state == MovementEngineState.cooldown;

    return Positioned(
      left: targetPixelX - targetPixelRadius,
      top: targetPixelY - targetPixelRadius,
      child: ScaleTransition(
        scale: isReached ? const AlwaysStoppedAnimation(1.25) : _pulseAnimation,
        child: Container(
          width: targetPixelRadius * 2,
          height: targetPixelRadius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isReached
                ? const Color(0xff00E676).withValues(alpha: 0.35)
                : isCooldown
                    ? Colors.grey.withValues(alpha: 0.2)
                    : const Color(0xffFFD700).withValues(alpha: 0.28),
            border: Border.all(
              color: isReached
                  ? const Color(0xff00E676)
                  : isCooldown
                      ? Colors.white38
                      : const Color(0xffFFD700),
              width: 2.4,
            ),
            boxShadow: [
              BoxShadow(
                color: isReached
                    ? const Color(0xff00E676).withValues(alpha: 0.7)
                    : const Color(0xffFFD700).withValues(alpha: 0.6),
                blurRadius: isReached ? 20 : 14,
                spreadRadius: isReached ? 4 : 2,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              isReached ? Icons.check_circle_rounded : Icons.star_rounded,
              color: isReached
                  ? const Color(0xff00E676)
                  : const Color(0xffFFF176),
              size: targetPixelRadius * 1.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHandReticleLayer(double width, double height) {
    final handX = widget.engine.smoothedHandX ?? _latestTracking.x;
    final handY = widget.engine.smoothedHandY ?? _latestTracking.y;

    if (!_latestTracking.isTracked) return const SizedBox.shrink();

    final pixelX = handX * width;
    final pixelY = handY * height;

    return Positioned(
      left: pixelX - 16,
      top: pixelY - 16,
      child: IgnorePointer(
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xff00E5FF).withValues(alpha: 0.3),
            border: Border.all(color: const Color(0xff00E5FF), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff00E5FF).withValues(alpha: 0.6),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.pan_tool_alt_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReachSplashBadge(MovementReachEvent reach) {
    return Positioned(
      top: 52.h,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: const Color(0xff00C853),
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff00C853).withValues(alpha: 0.5),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            children: [
              const Icon(Icons.bolt_rounded, color: Colors.yellow, size: 18),
              SizedBox(width: 4.w),
              Text(
                'استجابة ممتازة! (${reach.reactionTimeMs} ms)',
                style: AppTextStyles.font700Bold.copyWith(
                  fontSize: 12.sp,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTelemetryHUD() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      textDirection: TextDirection.rtl,
      children: [
        // Repetitions Badge
        Flexible(
          child: _buildHudPill(
            icon: Icons.star_rounded,
            iconColor: const Color(0xffFFD700),
            label: 'التكرارات',
            value: '${widget.engine.repetitions}',
          ),
        ),
        SizedBox(width: 4.w),
        // Derived Honest Accuracy Badge
        Flexible(
          child: _buildHudPill(
            icon: Icons.track_changes_rounded,
            iconColor: const Color(0xff00E676),
            label: 'الدقة',
            value: '${widget.engine.accuracyPercentage.toStringAsFixed(0)}%',
          ),
        ),
        SizedBox(width: 4.w),
        // Measured Reaction Time Badge
        Flexible(
          child: _buildHudPill(
            icon: Icons.timer_outlined,
            iconColor: const Color(0xff40C4FF),
            label: 'الاستجابة',
            value: widget.engine.latestReactionTimeMs != null
                ? '${widget.engine.latestReactionTimeMs}ms'
                : '--',
          ),
        ),
      ],
    );
  }

  Widget _buildHudPill({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        textDirection: TextDirection.rtl,
        children: [
          Icon(icon, size: 13.r, color: iconColor),
          SizedBox(width: 3.w),
          Text(
            '$label: ',
            style: AppTextStyles.font400Regular.copyWith(
              fontSize: 9.5.sp,
              color: Colors.white70,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.font700Bold.copyWith(
              fontSize: 10.5.sp,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingStatusBadge() {
    final isTracked = _latestTracking.isTracked;
    final conf = (_latestTracking.confidence * 100).toStringAsFixed(0);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isTracked
              ? const Color(0xff00E676).withValues(alpha: 0.5)
              : Colors.amber.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 8.r,
            height: 8.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isTracked ? const Color(0xff00E676) : Colors.amber,
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            isTracked
                ? 'تتبع اليد نشط على الجهاز (دقة الرصد: $conf%)'
                : 'وجّه يد الطفل نحو الكاميرا للمس النجمة',
            style: AppTextStyles.font500Medium.copyWith(
              fontSize: 11.sp,
              color: Colors.white,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(String message) {
    return Container(
      height: 260.h,
      decoration: BoxDecoration(
        color: const Color(0xffF8F6FF),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xffE4D4FF), width: 1.2),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primaryColor),
            SizedBox(height: 16.h),
            Text(
              message,
              style: AppTextStyles.font500Medium.copyWith(
                fontSize: 13.sp,
                color: AppColors.primaryColor,
              ),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionFallback(String message) {
    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: const Color(0xffFFF3E0),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xffFFE0B2), width: 1.2),
      ),
      child: Column(
        children: [
          Icon(Icons.videocam_off_rounded, size: 40.r, color: const Color(0xffE65100)),
          SizedBox(height: 10.h),
          Text(
            'مطلوب إذن الكاميرا لتتبع الحركة',
            style: AppTextStyles.font700Bold.copyWith(
              fontSize: 14.sp,
              color: const Color(0xffE65100),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.font400Regular.copyWith(
              fontSize: 12.sp,
              color: AppColors.secondaryColor,
              height: 1.4,
            ),
            textDirection: TextDirection.rtl,
          ),
          SizedBox(height: 14.h),
          ElevatedButton.icon(
            onPressed: () => widget.trackerService.initialize(),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('إعادة طلب إذن الكاميرا'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorFallback(String message) {
    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: const Color(0xffFFEBEE),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xffFFCDD2), width: 1.2),
      ),
      child: Column(
        children: [
          Icon(Icons.warning_amber_rounded, size: 40.r, color: Colors.red.shade700),
          SizedBox(height: 8.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.font500Medium.copyWith(
              fontSize: 12.sp,
              color: Colors.red.shade700,
            ),
          ),
          SizedBox(height: 12.h),
          TextButton.icon(
            onPressed: () => widget.trackerService.initialize(),
            icon: const Icon(Icons.replay_rounded),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}
