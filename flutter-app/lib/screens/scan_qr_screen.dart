import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sawa/app_text_styles.dart';
import 'package:sawa/constants.dart';
import 'package:sawa/core/errors/api_exception.dart';
import 'package:sawa/core/services/doctor_linking_service.dart';
import 'package:sawa/screens/connected_successfuly_screen.dart';
import 'package:sawa/screens/enter_code_screen.dart';
import 'package:sawa/widgets/back_icon.dart';
import 'package:sawa/widgets/custom_app_bar.dart';
import 'package:sawa/widgets/custom_elevated_button.dart';
import 'package:sawa/widgets/custom_padding.dart';
import 'package:sawa/widgets/custom_title.dart';
import 'package:sawa/widgets/description.dart';

class ScanQrScreen extends StatefulWidget {
  final DoctorLinkingService? linkingService;

  const ScanQrScreen({super.key, this.linkingService});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> with WidgetsBindingObserver {
  late final DoctorLinkingService _linkingService;
  late final MobileScannerController _scannerController;

  bool _isSubmitting = false;
  bool _hasScanned = false;
  String? _errorMessage;
  bool _permissionDenied = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _linkingService = widget.linkingService ?? DoctorLinkingService();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    _checkCameraPermission();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_scannerController.value.isInitialized) return;
    if (state == AppLifecycleState.resumed) {
      if (!_hasScanned && !_isSubmitting) {
        _scannerController.start();
      }
    } else if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _scannerController.stop();
    }
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isDenied) {
      final req = await Permission.camera.request();
      if (mounted) {
        setState(() {
          _permissionDenied = !req.isGranted;
        });
      }
    } else if (status.isPermanentlyDenied || status.isRestricted) {
      if (mounted) {
        setState(() {
          _permissionDenied = true;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    super.dispose();
  }

  /// Handles incoming raw QR payload from MobileScanner.
  /// Strict duplicate callback lock prevents re-entry while an API call is in flight.
  Future<void> _handleQrPayload(String rawPayload) async {
    if (_isSubmitting || _hasScanned) return;

    final extractedCode =
        DoctorLinkingService.extractReferralCodeFromQrPayload(rawPayload);

    if (extractedCode == null) {
      setState(() {
        _errorMessage = 'الرمز الممسوح غير صالح. يرجى مسح رمز QR صالح للطبيب (مثال: DR-XXXXXXXX).';
      });
      return;
    }

    final activeChildId = await _linkingService.getActiveChildId();
    if (activeChildId == null || activeChildId.trim().isEmpty) {
      if (!mounted) return;
      _showErrorSnackBar(
        'لم يتم العثور على طفل محدد. يرجى إكمال إدخال بيانات الطفل أولاً.',
      );
      return;
    }

    setState(() {
      _hasScanned = true;
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      // Pause scanner while backend processes request
      await _scannerController.stop();

      final assignment = await _linkingService.linkDoctorByCode(
        childId: activeChildId.trim(),
        doctorCode: extractedCode,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ConnectedSuccessfuly(assignment: assignment),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      final msg = _mapApiExceptionToMessage(e);
      setState(() {
        _errorMessage = msg;
        _isSubmitting = false;
        _hasScanned = false; // Release lock on failure to allow retry
      });
      _scannerController.start();
      _showErrorSnackBar(msg);
    } catch (_) {
      if (!mounted) return;
      const msg = 'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى.';
      setState(() {
        _errorMessage = msg;
        _isSubmitting = false;
        _hasScanned = false;
      });
      _scannerController.start();
      _showErrorSnackBar(msg);
    }
  }

  String _mapApiExceptionToMessage(ApiException e) {
    switch (e.statusCode) {
      case 400:
        return e.firstErrorMessage.isNotEmpty
            ? e.firstErrorMessage
            : 'رمز الطبيب المدخل غير صحيح.';
      case 401:
        return 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مجدداً.';
      case 403:
        return 'غير مصرح لك بإجراء هذه العملية.';
      case 404:
        return 'رمز الطبيب غير موجود. يرجى التأكد من صحة الرمز والمحاولة مجدداً.';
      case 409:
        return 'تم إرسال طلب ربط مسبقاً أو أن الطبيب مرتبط بالطفل بالفعل.';
      case 500:
        return 'حدث خطأ في الخادم، يرجى المحاولة لاحقاً.';
      default:
        if (e.isNetworkError) {
          return 'تعذر الاتصال بالخادم، يرجى التحقق من اتصال الإنترنت.';
        }
        return e.message.isNotEmpty
            ? e.message
            : 'حدث خطأ أثناء ربط الطبيب، يرجى المحاولة لاحقاً.';
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: const CustomAppBar(leading: BackIcon()),
      body: CustomPadding(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Center(
                child: CustomTitle(
                  title: 'مسح رمز QR',
                  fontSize: 20,
                ),
              ),
              SizedBox(height: 8.h),
              const Center(
                child: Description(
                  text: 'وجّه الكاميرا نحو رمز الـ QR الخاص بطبيبك',
                  fontSize: 13,
                ),
              ),
              SizedBox(height: 28.h),

              // Viewfinder Container with Real MobileScanner
              Center(
                child: Container(
                  width: 260.w,
                  height: 260.w,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(
                      color: AppColors.frameColor,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withValues(alpha: 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(21.r),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_permissionDenied)
                          _buildPermissionDeniedView()
                        else
                          MobileScanner(
                            controller: _scannerController,
                            onDetect: (capture) {
                              final barcodes = capture.barcodes;
                              for (final barcode in barcodes) {
                                final value = barcode.rawValue;
                                if (value != null && value.trim().isNotEmpty) {
                                  _handleQrPayload(value);
                                  break;
                                }
                              }
                            },
                            errorBuilder: (context, error) {
                              return _buildCameraErrorView(error);
                            },
                          ),

                        // Animated scanning line or loading overlay
                        if (_isSubmitting)
                          Container(
                            color: Colors.black.withValues(alpha: 0.7),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(
                                    color: Color(0xff8456D2),
                                  ),
                                  SizedBox(height: 16.h),
                                  Text(
                                    'جاري إرسال طلب الربط...',
                                    style: AppTextStyles.font400Regular.copyWith(
                                      fontSize: 13.sp,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Corner overlays
                        Positioned(
                          top: 14.r,
                          left: 14.r,
                          child: _buildCorner(isTop: true, isLeft: true),
                        ),
                        Positioned(
                          top: 14.r,
                          right: 14.r,
                          child: _buildCorner(isTop: true, isLeft: false),
                        ),
                        Positioned(
                          bottom: 14.r,
                          left: 14.r,
                          child: _buildCorner(isTop: false, isLeft: true),
                        ),
                        Positioned(
                          bottom: 14.r,
                          right: 14.r,
                          child: _buildCorner(isTop: false, isLeft: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              // Torch & Camera Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () async {
                      await _scannerController.toggleTorch();
                      setState(() {
                        _isTorchOn = !_isTorchOn;
                      });
                    },
                    icon: Icon(
                      _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                      color: _isTorchOn ? Colors.amber : AppColors.primaryColor,
                      size: 24.r,
                    ),
                    tooltip: 'تشغيل/إيقاف الفلاش',
                  ),
                  SizedBox(width: 16.w),
                  IconButton(
                    onPressed: () async {
                      await _scannerController.switchCamera();
                    },
                    icon: Icon(
                      Icons.flip_camera_ios_rounded,
                      color: AppColors.primaryColor,
                      size: 24.r,
                    ),
                    tooltip: 'تبديل الكاميرا',
                  ),
                ],
              ),

              if (_errorMessage != null) ...[
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: const Color(0xffFFEBEE),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: AppTextStyles.font400Regular.copyWith(
                      color: Colors.red.shade900,
                      fontSize: 12.sp,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],

              SizedBox(height: 28.h),

              // Manual Code entry fallback button
              CustomElevatedButton(
                title: 'إدخال الرمز يدوياً',
                onPressed: _isSubmitting
                    ? null
                    : () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EnterCodeScreen(),
                          ),
                        );
                      },
                width: 180,
                height: 40,
              ),

              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedView() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16.r),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam_off_rounded, size: 48.r, color: Colors.red.shade400),
          SizedBox(height: 10.h),
          Text(
            'تم رفض إذن الكاميرا',
            style: TextStyle(
              fontFamily: 'Readex Pro',
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
              color: AppColors.primaryColor,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'يرجى منح إذن الوصول للكاميرا لمسح رمز الـ QR الخاص بالطبيب.',
            style: TextStyle(
              fontFamily: 'Readex Pro',
              fontSize: 11.sp,
              color: AppColors.secondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
          ElevatedButton(
            onPressed: () async {
              final res = await Permission.camera.request();
              if (res.isGranted && mounted) {
                setState(() {
                  _permissionDenied = false;
                });
                _scannerController.start();
              } else if (res.isPermanentlyDenied) {
                openAppSettings();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            ),
            child: const Text('منح الإذن'),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraErrorView(MobileScannerException error) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16.r),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 44.r, color: Colors.amber.shade700),
          SizedBox(height: 8.h),
          Text(
            'تعذر تشغيل الكاميرا',
            style: TextStyle(
              fontFamily: 'Readex Pro',
              fontWeight: FontWeight.bold,
              fontSize: 13.sp,
              color: AppColors.primaryColor,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'يرجى التحقق من أذونات الكاميرا أو إدخال كود الطبيب يدوياً.',
            style: TextStyle(
              fontFamily: 'Readex Pro',
              fontSize: 11.sp,
              color: AppColors.secondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10.h),
          TextButton(
            onPressed: () {
              _scannerController.start();
            },
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner({required bool isTop, required bool isLeft}) {
    return Container(
      width: 22.r,
      height: 22.r,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: Color(0xff8456D2), width: 3.5)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: Color(0xff8456D2), width: 3.5)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: Color(0xff8456D2), width: 3.5)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: Color(0xff8456D2), width: 3.5)
              : BorderSide.none,
        ),
      ),
    );
  }
}
