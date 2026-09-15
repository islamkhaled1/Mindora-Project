import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_text_styles.dart';
import 'package:sawa/constants.dart';
import 'package:sawa/core/errors/api_exception.dart';
import 'package:sawa/core/services/auth_service.dart';
import 'package:sawa/screens/new_password_screen.dart';
import 'package:sawa/widgets/back_icon.dart';
import 'package:sawa/widgets/custom_app_bar.dart';
import 'package:sawa/widgets/custom_elevated_button.dart';
import 'package:sawa/widgets/custom_padding.dart';
import 'package:sawa/widgets/description.dart';
import 'package:sawa/widgets/medium_title.dart';
import 'package:sawa/widgets/simi_bold_title.dart';
import 'package:pinput/pinput.dart';
import 'package:sawa/features/auth/widgets/auth_action_row.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({
    super.key,
    this.email = 'example@gmail.com',
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  int _resendCountdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _resendCountdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (_isLoading) return;

    final otp = _otpController.text.trim();
    if (otp.length < 6) {
      setState(() => _errorText = 'من فضلك أدخل الرمز كاملاً (6 أرقام)');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final resetToken = await AuthService().verifyOtp(widget.email, otp);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NewPasswordScreen(resetToken: resetToken),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.firstErrorMessage;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorText = 'حدث خطأ أثناء التحقق من الرمز، يرجى المحاولة مجدداً.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleResendOtp() async {
    if (_resendCountdown > 0) return;

    try {
      await AuthService().forgotPassword(widget.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال رمز تحقق جديد إلى بريدك الإلكتروني.'),
          backgroundColor: AppColors.primaryColor,
        ),
      );
      _startCountdown();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.firstErrorMessage),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر إعادة إرسال الرمز، يرجى المحاولة بعد قليل.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: CustomAppBar(leading: BackIcon()),
      body: CustomPadding(
        child: Column(
          children: [
            Center(
              child: SimiBoldTitle(title: 'تحقق من صندوق الوارد', fontSize: 23),
            ),
            SizedBox(height: 12.h),
            Center(
              child: Description(
                text: 'لقد أرسلنا رمز تحقق مكون من 6 أرقام الي',
                fontSize: 12,
              ),
            ),
            Center(
              child: MediumTitle(title: widget.email, fontSize: 12),
            ),
            Center(
              child: Description(
                text: 'يرجى إدخال الرمز أدناه لتأكيد هويتك.',
                fontSize: 12,
              ),
            ),
            SizedBox(height: 56.h),
            Pinput(
              controller: _otpController,
              length: 6,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              preFilledWidget: Text(
                '-',
                style: AppTextStyles.font600SimiBold.copyWith(
                  fontSize: 20,
                  color: AppColors.frameColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              defaultPinTheme: PinTheme(
                width: 54.w,
                height: 65.h,
                textStyle: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
                decoration: BoxDecoration(
                  backgroundBlendMode: BlendMode.screen,
                  color: Colors.transparent,
                  border: Border.all(color: AppColors.frameColor, width: 3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              errorPinTheme: PinTheme(
                width: 54.w,
                height: 65.h,
                textStyle: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: Colors.red, width: 3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              forceErrorState: _errorText != null,
              onChanged: (_) {
                if (_errorText != null) {
                  setState(() => _errorText = null);
                }
              },
            ),
            if (_errorText != null) ...[
              SizedBox(height: 8.h),
              Text(
                _errorText!,
                style: AppTextStyles.font400Regular.copyWith(
                  color: Colors.red,
                  fontSize: 11.sp,
                ),
              ),
            ],
            SizedBox(height: 56.h),
            CustomElevatedButton(
              title: 'تأكيد',
              isLoading: _isLoading,
              onPressed: _handleVerify,
            ),
            SizedBox(height: 16.h),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              textDirection: TextDirection.rtl,
              children: [
                Text(
                  'لم يصلك الرمز؟ ',
                  style: AppTextStyles.font400Regular.copyWith(
                    fontSize: 12.sp,
                    color: AppColors.secondaryColor,
                  ),
                ),
                GestureDetector(
                  onTap: _resendCountdown > 0 ? null : _handleResendOtp,
                  child: Text(
                    _resendCountdown > 0
                        ? 'إعادة الإرسال بعد ($_resendCountdown ثانية)'
                        : 'إعادة إرسال الرمز',
                    style: AppTextStyles.font600SimiBold.copyWith(
                      fontSize: 12.sp,
                      color: _resendCountdown > 0
                          ? AppColors.secondaryColor
                          : AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
