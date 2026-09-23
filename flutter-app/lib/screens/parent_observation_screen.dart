import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_text_styles.dart';
import 'package:sawa/constants.dart';
import 'package:sawa/core/errors/api_exception.dart';
import 'package:sawa/core/models/activity_models.dart';
import 'package:sawa/core/models/session_models.dart';
import 'package:sawa/core/services/session_service.dart';
import 'package:sawa/screens/home_screen.dart';
import 'package:sawa/screens/session_result_screen.dart';
import 'package:sawa/widgets/custom_app_bar.dart';

/// Screen matching `parent observation.png` for collecting parent sentiment and notes
/// after session completion, strictly using real ASP.NET Core backend integration.
class ParentObservationScreen extends StatefulWidget {
  final CompletedSessionModel completedSession;
  final ActivityModel activity;
  final String? childName;

  const ParentObservationScreen({
    super.key,
    required this.completedSession,
    required this.activity,
    this.childName,
  });

  @override
  State<ParentObservationScreen> createState() => _ParentObservationScreenState();
}

class _ParentObservationScreenState extends State<ParentObservationScreen> {
  final SessionService _sessionService = SessionService();
  final TextEditingController _notesController = TextEditingController();

  ParentSentimentRating? _selectedRating;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedRating = widget.completedSession.parentRatingEnum ?? ParentSentimentRating.medium;
    if (widget.completedSession.parentNotes != null) {
      _notesController.text = widget.completedSession.parentNotes!;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveAndContinue() async {
    if (_selectedRating == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى تحديد تقييمك لأداء الطفل اليوم (سهل / متوسط / صعب)',
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: AppColors.primaryColor,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final notes = _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null;

      // Only call backend API for real (GUID) sessions, skip for local sessions
      final isLocalSession = widget.completedSession.id.startsWith('movement-') ||
          widget.completedSession.id.startsWith('local-');

      if (!isLocalSession) {
        await _sessionService.recordFeedback(
          sessionId: widget.completedSession.id,
          request: RecordFeedbackRequest(
            rating: _selectedRating!,
            notes: notes,
          ),
        );
      }

      final updatedSession = CompletedSessionModel(
        id: widget.completedSession.id,
        childId: widget.completedSession.childId,
        activityId: widget.completedSession.activityId,
        domain: widget.completedSession.domain,
        status: widget.completedSession.status,
        startTimeUtc: widget.completedSession.startTimeUtc,
        endTimeUtc: widget.completedSession.endTimeUtc,
        actualDurationSeconds: widget.completedSession.actualDurationSeconds,
        analysisResult: widget.completedSession.analysisResult,
        metrics: widget.completedSession.metrics,
        parentRating: _selectedRating!.value.toString(),
        parentNotes: notes,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      // Navigate to Session Result Step 2 (session complete.png)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SessionResultScreen(
            completedSession: updatedSession,
            activity: widget.activity,
            initialStep: 2,
            childName: widget.childName,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.firstErrorMessage.isNotEmpty
                ? e.firstErrorMessage
                : 'تعذر حفظ ملاحظات ولي الأمر، يرجى المحاولة لاحقاً',
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'حدث خطأ غير متوقع أثناء حفظ الملاحظات',
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final childDisplay = (widget.childName != null && widget.childName!.trim().isNotEmpty)
        ? widget.childName!.trim()
        : 'الطفل';

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: CustomAppBar(
        leading: Container(
          margin: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.circleAvatarColor),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16.r,
              color: AppColors.primaryColor,
            ),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            },
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 8.h),

              // Title & Subtitle matching parent observation.png
              Text(
                'كيف كان أداء $childDisplay اليوم؟',
                style: AppTextStyles.font700Bold.copyWith(
                  fontSize: 22.sp,
                  color: AppColors.primaryColor,
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
              SizedBox(height: 8.h),
              Text(
                'ملاحظاتك تساعدنا على تحسين الخطة.',
                style: AppTextStyles.font400Regular.copyWith(
                  fontSize: 13.sp,
                  color: AppColors.secondaryColor,
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
              SizedBox(height: 32.h),

              // 3 Reaction Cards matching parent observation.png
              // Note: In RTL row:
              // Right: سهل (green)
              // Middle: متوسط (yellow)
              // Left: صعب (red)
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: _buildSentimentCard(
                      rating: ParentSentimentRating.easy,
                      label: 'سهل',
                      emojiChar: '😊',
                      cardBgColor: const Color(0xffE8F8E8),
                      selectedBorderColor: const Color(0xff4CAF50),
                      textColor: const Color(0xff2E7D32),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: _buildSentimentCard(
                      rating: ParentSentimentRating.medium,
                      label: 'متوسط',
                      emojiChar: '😐',
                      cardBgColor: const Color(0xffFFF8E1),
                      selectedBorderColor: const Color(0xffFFB300),
                      textColor: const Color(0xffE65100),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: _buildSentimentCard(
                      rating: ParentSentimentRating.difficult,
                      label: 'صعب',
                      emojiChar: '😡',
                      cardBgColor: const Color(0xffFFEBEE),
                      selectedBorderColor: const Color(0xffE53935),
                      textColor: const Color(0xffC62828),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 36.h),

              // Notes Section Title matching parent observation.png
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'ملاحظاتك (اختياري)',
                  style: AppTextStyles.font700Bold.copyWith(
                    fontSize: 16.sp,
                    color: AppColors.primaryColor,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
              SizedBox(height: 12.h),

              // Notes Input Container matching parent observation.png
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(
                    color: AppColors.circleAvatarColor.withValues(alpha: 0.8),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      textDirection: TextDirection.rtl,
                      children: [
                        Container(
                          padding: EdgeInsets.all(6.r),
                          decoration: BoxDecoration(
                            color: const Color(0xffF0E8FF),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            Icons.edit_note_rounded,
                            size: 20.r,
                            color: AppColors.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    TextField(
                      controller: _notesController,
                      maxLines: 4,
                      textDirection: TextDirection.rtl,
                      style: AppTextStyles.font400Regular.copyWith(
                        fontSize: 13.sp,
                        color: AppColors.primaryColor,
                        fontFamily: 'Readex Pro',
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'اكتب ملاحظاتك هنا...',
                        hintTextDirection: TextDirection.rtl,
                        hintStyle: AppTextStyles.font400Regular.copyWith(
                          fontSize: 12.5.sp,
                          color: AppColors.secondaryColor.withValues(alpha: 0.6),
                          fontFamily: 'Readex Pro',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 48.h),

              // CTA Button: حفظ ومتابعة
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSaveAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryTextColor,
                    disabledBackgroundColor: AppColors.secondaryTextColor.withValues(alpha: 0.6),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                    elevation: 2,
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          height: 20.r,
                          width: 20.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'حفظ ومتابعة',
                          style: AppTextStyles.font700Bold.copyWith(
                            fontSize: 16.sp,
                            color: Colors.white,
                            fontFamily: 'Readex Pro',
                          ),
                        ),
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSentimentCard({
    required ParentSentimentRating rating,
    required String label,
    required String emojiChar,
    required Color cardBgColor,
    required Color selectedBorderColor,
    required Color textColor,
  }) {
    final isSelected = _selectedRating == rating;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRating = rating;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: isSelected ? selectedBorderColor : selectedBorderColor.withValues(alpha: 0.3),
            width: isSelected ? 2.5 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectedBorderColor.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                emojiChar,
                style: TextStyle(fontSize: 36.sp),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              label,
              style: AppTextStyles.font700Bold.copyWith(
                fontSize: 14.sp,
                color: isSelected ? textColor : AppColors.primaryColor,
                fontFamily: 'Readex Pro',
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }
}
