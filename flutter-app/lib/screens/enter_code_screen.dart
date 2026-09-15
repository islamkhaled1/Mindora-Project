import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconify_flutter/icons/radix_icons.dart';
import 'package:sawa/constants.dart';
import 'package:sawa/core/errors/api_exception.dart';
import 'package:sawa/core/models/doctor_linking_models.dart';
import 'package:sawa/core/services/doctor_linking_service.dart';
import 'package:sawa/screens/connected_successfuly_screen.dart';
import 'package:sawa/widgets/back_icon.dart';
import 'package:sawa/widgets/custom_app_bar.dart';
import 'package:sawa/widgets/custom_elevated_button.dart';
import 'package:sawa/widgets/custom_note.dart';
import 'package:sawa/widgets/custom_padding.dart';
import 'package:sawa/widgets/custom_title.dart';
import 'package:sawa/widgets/description.dart';
import 'package:sawa/widgets/simi_bold_title.dart';

class EnterCodeScreen extends StatefulWidget {
  final DoctorLinkingService? linkingService;

  const EnterCodeScreen({super.key, this.linkingService});

  @override
  State<EnterCodeScreen> createState() => _EnterCodeScreenState();
}

class _EnterCodeScreenState extends State<EnterCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  late final DoctorLinkingService _linkingService;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _linkingService = widget.linkingService ?? DoctorLinkingService();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submitCode() async {
    if (_isLoading) return;

    // 1. Local form validation
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final rawInput = _codeController.text;
    final fullCode = LinkDoctorRequest.formatFullCode(rawInput);
    if (fullCode.isEmpty) {
      _showErrorSnackBar('يرجى إدخال رمز الطبيب.');
      return;
    }

    // 2. Retrieve active child ID
    final activeChildId = await _linkingService.getActiveChildId();
    if (activeChildId == null || activeChildId.trim().isEmpty) {
      if (!mounted) return;
      _showErrorSnackBar(
        'لم يتم العثور على طفل محدد. يرجى إكمال إدخال بيانات الطفل أولاً.',
      );
      return;
    }

    // 3. Submit request
    setState(() {
      _isLoading = true;
    });

    try {
      final assignment = await _linkingService.linkDoctorByCode(
        childId: activeChildId.trim(),
        doctorCode: fullCode,
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
      final errorMessage = _mapApiExceptionToMessage(e);
      _showErrorSnackBar(errorMessage);
    } catch (_) {
      if (!mounted) return;
      _showErrorSnackBar('حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Center(
                  child: CustomTitle(
                    title: 'إدخال رمز الطبيب',
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 8.h),
                const Center(
                  child: Description(
                    text: 'أدخل رمز طبيبك',
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 64.h),
                const Align(
                  alignment: AlignmentGeometry.centerRight,
                  child: SimiBoldTitle(
                    title: 'رمز الطبيب',
                    fontSize: 12,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 4.0.r, top: 8.0.r),
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Container(
                      height: 58.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15.r),
                        border: Border.all(color: AppColors.frameColor, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 14.w),
                            decoration: BoxDecoration(
                              color: AppColors.circleAvatarColor.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(13.r),
                                bottomLeft: Radius.circular(13.r),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'DR-',
                              style: TextStyle(
                                fontFamily: 'Readex Pro',
                                fontWeight: FontWeight.bold,
                                fontSize: 16.sp,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                          Container(
                            width: 1.5,
                            height: 30.h,
                            color: AppColors.frameColor,
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: _codeController,
                              onChanged: (val) {
                                final cleaned = LinkDoctorRequest.cleanCodePart(val);
                                if (cleaned != val) {
                                  _codeController.value = TextEditingValue(
                                    text: cleaned,
                                    selection: TextSelection.collapsed(offset: cleaned.length),
                                  );
                                }
                              },
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'يرجى إدخال كود الطبيب';
                                }
                                if (!LinkDoctorRequest.isValidCodePart(val)) {
                                  return 'صيغة الكود غير صحيحة (أحرف وأرقام فقط)';
                                }
                                return null;
                              },
                              style: TextStyle(
                                fontFamily: 'Readex Pro',
                                fontWeight: FontWeight.w600,
                                fontSize: 16.sp,
                                color: AppColors.primaryColor,
                                letterSpacing: 1.5,
                              ),
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                hintText: '7B6780AA',
                                hintStyle: TextStyle(
                                  fontFamily: 'Readex Pro',
                                  color: AppColors.secondaryColor.withValues(alpha: 0.5),
                                  fontSize: 14.sp,
                                  letterSpacing: 1.0,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 32.h),
                const CustomNote(
                  title: 'يمكنك الحصول على الرمز من طبيبك أو العيادة.',
                  icon: RadixIcons.info_circled,
                ),
                SizedBox(height: 50.h),
                CustomElevatedButton(
                  title: 'متابعة',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _submitCode,
                  width: 165,
                  height: 40,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
