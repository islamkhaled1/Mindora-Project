import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/hand_tracking_result.dart';

/// Status of the camera tracking lifecycle.
enum CameraTrackingStatus {
  uninitialized,
  requestingPermission,
  permissionDenied,
  permissionPermanentlyDenied,
  cameraUnavailable,
  initializing,
  ready,
  running,
  paused,
  error,
}

/// Service responsible for:
/// - Camera hardware acquisition (Front camera)
/// - Camera permission checks and friendly status
/// - MediaPipe HandLandmarker lifecycle via native MethodChannel
/// - Frame rate throttling (12-15 FPS for optimal battery and thermals)
/// - Normalization and Landmark 8 / Landmark 9 selection
/// - Clean HandTrackingResult stream output
class HandTrackerService {
  static const MethodChannel _channel = MethodChannel('mindora/hand_tracking');

  CameraController? _cameraController;
  CameraDescription? _frontCamera;
  CameraTrackingStatus _status = CameraTrackingStatus.uninitialized;
  String? _errorMessage;

  final StreamController<HandTrackingResult> _trackingController =
      StreamController<HandTrackingResult>.broadcast();
  final StreamController<CameraTrackingStatus> _statusController =
      StreamController<CameraTrackingStatus>.broadcast();

  bool _isProcessingFrame = false;
  int _lastFrameTimeMs = 0;
  // Target interval of 80ms gives ~12.5 FPS, ideal for mobile CV without heating
  final int targetFrameIntervalMs;

  HandTrackerService({this.targetFrameIntervalMs = 80});

  // --- Getters ---

  CameraController? get cameraController => _cameraController;
  CameraTrackingStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isReady => _status == CameraTrackingStatus.ready || _status == CameraTrackingStatus.running;
  Stream<HandTrackingResult> get trackingStream => _trackingController.stream;
  Stream<CameraTrackingStatus> get statusStream => _statusController.stream;

  /// Initialize camera hardware and native MediaPipe model.
  Future<bool> initialize() async {
    _updateStatus(CameraTrackingStatus.requestingPermission);

    // 1. Check Camera Permission
    final permissionStatus = await Permission.camera.request();
    if (permissionStatus.isPermanentlyDenied) {
      _errorMessage = 'يرجى تفعيل إذن الكاميرا من إعدادات الجهاز لمتابعة تمرين الحركة.';
      _updateStatus(CameraTrackingStatus.permissionPermanentlyDenied);
      return false;
    } else if (permissionStatus.isDenied) {
      _errorMessage = 'إذن الكاميرا مطلوب لتتبع حركة اليد في هذا النشاط.';
      _updateStatus(CameraTrackingStatus.permissionDenied);
      return false;
    }

    _updateStatus(CameraTrackingStatus.initializing);

    try {
      // 2. Discover Cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _errorMessage = 'لم يتم العثور على كاميرا في هذا الجهاز.';
        _updateStatus(CameraTrackingStatus.cameraUnavailable);
        return false;
      }

      // Prefer front camera for interactive child exercises
      _frontCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      debugPrint(
        '[HandTrackerService] Camera discovered: name=${_frontCamera?.name}, '
        'sensorOrientation=${_frontCamera?.sensorOrientation}, '
        'lensDirection=${_frontCamera?.lensDirection}',
      );

      // 3. Initialize Camera Controller
      _cameraController = CameraController(
        _frontCamera!,
        ResolutionPreset.medium, // 720x480 or similar, optimal for landmarking
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      // 4. Initialize Native MediaPipe Landmarker
      try {
        final initSuccess = await _channel.invokeMethod<bool>('initLandmarker');
        debugPrint('[HandTrackerService] Native MediaPipe init: $initSuccess');
        if (initSuccess != true) {
          try {
            final diagContent = await _channel.invokeMethod<String>('readDiagFile');
            debugPrint('[HandTrackerService] *** DIAG FILE:\n$diagContent\n***');
          } catch (_) {}
          try {
            final initError = await _channel.invokeMethod<String>('getInitError');
            debugPrint('[HandTrackerService] *** MEDIAPIPE INIT ERROR: $initError ***');
          } catch (_) {}
        }
      } on PlatformException catch (e) {
        debugPrint('[HandTrackerService] Warning initializing native landmarker: $e');
      }


      _updateStatus(CameraTrackingStatus.ready);
      return true;
    } catch (e) {
      _errorMessage = 'تعذر تشغيل الكاميرا: $e';
      _updateStatus(CameraTrackingStatus.error);
      return false;
    }
  }

  /// Start streaming camera frames to the on-device perception engine.
  Future<void> startTracking() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      debugPrint('[HandTrackerService] Cannot start tracking: camera not ready.');
      return;
    }

    if (_status == CameraTrackingStatus.running) return;

    try {
      _updateStatus(CameraTrackingStatus.running);
      await _cameraController!.startImageStream(_onCameraImage);
    } catch (e) {
      debugPrint('[HandTrackerService] Error starting image stream: $e');
      _errorMessage = 'حدث خطأ أثناء تشغيل تتبع الكاميرا: $e';
      _updateStatus(CameraTrackingStatus.error);
    }
  }

  /// Stop streaming camera frames.
  Future<void> stopTracking() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    try {
      if (_cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }
      _updateStatus(CameraTrackingStatus.ready);
    } catch (e) {
      debugPrint('[HandTrackerService] Error stopping image stream: $e');
    }
  }

  /// Internal frame handler with FPS throttling and asynchronous dispatch.
  void _onCameraImage(CameraImage image) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // Throttle frames to prevent CPU/battery strain
    if (nowMs - _lastFrameTimeMs < targetFrameIntervalMs) {
      return;
    }

    // Drop frame if previous inference is still in progress
    if (_isProcessingFrame) {
      return;
    }

    _isProcessingFrame = true;
    _lastFrameTimeMs = nowMs;

    try {
      final yPlane = image.planes[0];
      final uPlane = image.planes[1];
      final vPlane = image.planes[2];

      final Map<dynamic, dynamic>? nativeResult =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('processYuvFrame', {
        'y': yPlane.bytes,
        'u': uPlane.bytes,
        'v': vPlane.bytes,
        'width': image.width,
        'height': image.height,
        'yRowStride': yPlane.bytesPerRow,
        'uvRowStride': uPlane.bytesPerRow,
        'uvPixelStride': uPlane.bytesPerPixel ?? 1,
        'rotation': _frontCamera?.sensorOrientation ?? 270,
        'isFront': _frontCamera?.lensDirection == CameraLensDirection.front,
        'timestampMs': nowMs,
      });

      if (nativeResult != null && nativeResult['isTracked'] == true) {
        final lm8x = (nativeResult['landmark8_x'] as num?)?.toDouble();
        final lm8y = (nativeResult['landmark8_y'] as num?)?.toDouble();
        final lm9x = (nativeResult['landmark9_x'] as num?)?.toDouble();
        final lm9y = (nativeResult['landmark9_y'] as num?)?.toDouble();

        final result = HandTrackingResult(
          x: (nativeResult['x'] as num).toDouble(),
          y: (nativeResult['y'] as num).toDouble(),
          confidence: (nativeResult['confidence'] as num).toDouble(),
          isTracked: true,
          landmarkUsed: (nativeResult['landmarkUsed'] as num?)?.toInt() ?? 8,
          timestampMs: nowMs,
          landmark8X: (lm8x != null && lm8x > 0.0) ? lm8x : null,
          landmark8Y: (lm8y != null && lm8y > 0.0) ? lm8y : null,
          landmark9X: (lm9x != null && lm9x > 0.0) ? lm9x : null,
          landmark9Y: (lm9y != null && lm9y > 0.0) ? lm9y : null,
        );
        _trackingController.add(result);
      } else {
        final reason = nativeResult?['reason'] ?? nativeResult?['error'] ?? 'unknown';
        if (nowMs % 1000 < 100) {
          debugPrint('[MovementDebug] Untracked reason: $reason, nativeResult=$nativeResult');
        }
        _trackingController.add(HandTrackingResult.untracked(timestampMs: nowMs));
      }
    } catch (e) {
      debugPrint('[HandTrackerService] Inference error on frame: $e');
      _trackingController.add(HandTrackingResult.untracked(timestampMs: nowMs));
    } finally {
      _isProcessingFrame = false;
    }
  }

  void _updateStatus(CameraTrackingStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _statusController.add(_status);
    }
  }

  /// Clean up all camera and native tracking resources.
  Future<void> dispose() async {
    try {
      await stopTracking();
      await _cameraController?.dispose();
      _cameraController = null;
      await _channel.invokeMethod('closeLandmarker');
    } catch (e) {
      debugPrint('[HandTrackerService] Error during dispose: $e');
    } finally {
      _status = CameraTrackingStatus.uninitialized;
      if (!_trackingController.isClosed) await _trackingController.close();
      if (!_statusController.isClosed) await _statusController.close();
    }
  }
}
