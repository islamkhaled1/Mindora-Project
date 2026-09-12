import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_text_styles.dart';
import 'package:sawa/app_colors.dart';
import 'package:sawa/screens/new_password_screen.dart';
import 'package:sawa/widgets/auth_action_row.dart';
import 'package:sawa/widgets/back_icon.dart';
import 'package:sawa/widgets/custom_app_bar.dart';
import 'package:sawa/widgets/custom_elevated_button.dart';
import 'package:sawa/widgets/custom_padding.dart';
import 'package:sawa/widgets/description.dart';
import 'package:sawa/widgets/medium_title.dart';
import 'package:sawa/widgets/simi_bold_title.dart';
import 'package:pinput/pinput.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (_otpController.text.trim().length < 6) {
      setState(() => _errorText = 'من فضلك أدخل الرمز كاملاً');
      return;
    }

    setState(() {
      _errorText = null;
      _isLoading = true;
    });

    try {
      // TODO: API Call
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => NewPasswordScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('حدث خطأ، حاول مرة أخرى')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              child: MediumTitle(title: 'example@gmail.com', fontSize: 12),
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
            AuthActionRow(
              question: ' لم يصلك الرمز ؟',
              linkText: 'إعادة إرسال الرمز',
            ),
          ],
        ),
      ),
    );
  }
}
