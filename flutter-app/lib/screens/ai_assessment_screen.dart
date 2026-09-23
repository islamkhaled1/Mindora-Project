import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_text_styles.dart';
import 'package:sawa/constants.dart';
import 'package:sawa/core/errors/api_exception.dart';
import 'package:sawa/core/models/baseline_assessment_models.dart';
import 'package:sawa/core/services/baseline_assessment_service.dart';
import 'package:sawa/core/state/baseline_assessment_state.dart';
import 'package:sawa/screens/celebration_screen.dart';
import 'package:sawa/screens/child_information_first_screen.dart';
import 'package:sawa/screens/treatment_plan_screen.dart';
import 'package:sawa/widgets/animated_gradient_circular_progress.dart';
import 'package:sawa/widgets/back_icon.dart';
import 'package:sawa/widgets/custom_app_bar.dart';
import 'package:sawa/widgets/custom_elevated_button.dart';
import 'package:sawa/widgets/custom_padding.dart';
import 'package:sawa/widgets/custom_title.dart';
import 'package:sawa/widgets/description.dart';

/// Screen managing the supportive initial baseline performance assessment.
///
/// Neutral terminology:
/// - "التقييم الأولي لمستوى الأداء"
/// - Estimates current baseline performance across 4 domains (Motor, Communication, Cognitive, Emotional).
/// - Zero medical or diagnostic claims.
class AiAssessmentScreen extends StatefulWidget {
  final BaselineAssessmentService? service;
  final BaselineAssessmentState? initialState;
  final BaselineAssessmentModel? initialResult;

  const AiAssessmentScreen({
    super.key,
    this.service,
    this.initialState,
    this.initialResult,
  });

  @override
  State<AiAssessmentScreen> createState() => _AiAssessmentScreenState();
}

class _AiAssessmentScreenState extends State<AiAssessmentScreen> {
  late final BaselineAssessmentService _service;
  late final BaselineAssessmentState _assessmentState;

  String? _activeChildId;
  bool _isCheckingChild = true;
  bool _isIntro = true;
  bool _isSubmitting = false;
  BaselineAssessmentModel? _savedResult;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? BaselineAssessmentService();
    _assessmentState = widget.initialState ?? BaselineAssessmentState();
    _savedResult = widget.initialResult;
    if (_savedResult != null) {
      _isCheckingChild = false;
      _isIntro = false;
      _activeChildId = _savedResult!.childId;
    } else {
      _loadActiveChild();
    }
  }

  Future<void> _loadActiveChild() async {
    final childId = await _service.getActiveChildId();
    if (mounted) {
      setState(() {
        _activeChildId = childId;
        _isCheckingChild = false;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_activeChildId == null || _activeChildId!.trim().isEmpty) {
      _showErrorSnackBar(
        'لم يتم العثور على طفل محدد. يرجى إكمال بيانات الطفل أولاً.',
      );
      return;
    }

    if (!_assessmentState.allTasksAnswered) {
      _showErrorSnackBar('يرجى الإجابة على جميع الأسئلة قبل إرسال التقييم.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final request = _assessmentState.toRequest();
      final result = await _service.recordBaselineAssessment(
        childId: _activeChildId!.trim(),
        request: request,
      );

      if (!mounted) return;
      setState(() {
        _savedResult = result;
        _isSubmitting = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CelebrationScreen(result: result),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showErrorSnackBar(
        e.firstErrorMessage.isNotEmpty
            ? e.firstErrorMessage
            : 'تعذر حفظ التقييم الأولي، يرجى المحاولة مجدداً.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showErrorSnackBar('حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى.');
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
      appBar: CustomAppBar(
        leading: _savedResult != null
            ? const SizedBox()
            : const BackIcon(),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_savedResult != null) {
      return _buildResultView(_savedResult!);
    }

    if (_isCheckingChild) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryColor),
      );
    }

    if (_activeChildId == null || _activeChildId!.trim().isEmpty) {
      return _buildMissingChildView();
    }

    if (_isIntro) {
      return _buildIntroView();
    }

    return _buildQuestionView();
  }

  // --- Missing Active Child View ---
  Widget _buildMissingChildView() {
    return CustomPadding(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_rounded,
              size: 64.r,
              color: Colors.red.shade400,
            ),
            SizedBox(height: 16.h),
            const CustomTitle(
              title: 'لم يتم تحديد طفل',
              fontSize: 20,
            ),
            SizedBox(height: 8.h),
            const Description(
              text:
                  'يرجى إكمال خطوات إضافة الطفل لتتمكن من إجراء التقييم الأولي.',
              fontSize: 13,
            ),
            SizedBox(height: 32.h),
            CustomElevatedButton(
              title: 'إضافة بيانات الطفل',
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChildInformationFirstScreen(),
                  ),
                );
              },
              width: 180,
              height: 42,
            ),
          ],
        ),
      ),
    );
  }

  // --- Intro View ---
  Widget _buildIntroView() {
    return CustomPadding(
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 16.h),
            const Center(
              child: CustomTitle(
                title: 'التقييم الأولي لمستوى الأداء',
                fontSize: 21,
              ),
            ),
            SizedBox(height: 8.h),
            const Center(
              child: Description(
                text:
                    'يهدف هذا التقييم إلى قياس مستوى الأداء الحالي لطفلك لمساعدتنا في تخصيص صعوبة التمارين والأنشطة الداعمة.',
                fontSize: 13,
              ),
            ),
            SizedBox(height: 28.h),

            // Information summary card
            Container(
              padding: EdgeInsets.all(18.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.circleAvatarColor, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildIntroDomainRow(
                    icon: Icons.directions_run_rounded,
                    title: 'المهارات الحركية',
                    subtitle: 'التناسق الحركي الدقيق والحركة الكلية للجسم',
                  ),
                  Divider(height: 24.h, color: const Color(0xffF0E8FF)),
                  _buildIntroDomainRow(
                    icon: Icons.record_voice_over_rounded,
                    title: 'مهارات التواصل',
                    subtitle: 'التعبير عن الاحتياجات والاستجابة للتوجيهات',
                  ),
                  Divider(height: 24.h, color: const Color(0xffF0E8FF)),
                  _buildIntroDomainRow(
                    icon: Icons.psychology_rounded,
                    title: 'المهارات المعرفية والتركيز',
                    subtitle: 'الانتباه في النشاط وحل المشكلات البسيطة',
                  ),
                  Divider(height: 24.h, color: const Color(0xffF0E8FF)),
                  _buildIntroDomainRow(
                    icon: Icons.favorite_rounded,
                    title: 'التفاعل الاجتماعي والتنظيم',
                    subtitle: 'المشاركة والتكيف مع التغييرات اليومية',
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: const Color(0xffF8F5FF),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xffE4D4FF)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 20.r,
                    color: AppColors.secondaryTextColor,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'التقييم بسيط ويتكون من 8 أسئلة تعتمد على ملاحظتك اليومية.',
                      style: AppTextStyles.font400Regular.copyWith(
                        fontSize: 11.5.sp,
                        color: AppColors.primaryColor,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 36.h),
            CustomElevatedButton(
              title: 'بدء التقييم الأولي',
              onPressed: () {
                setState(() => _isIntro = false);
              },
              width: 180,
              height: 42,
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroDomainRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Container(
          width: 42.r,
          height: 42.r,
          decoration: BoxDecoration(
            color: AppColors.circleAvatarColor.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primaryColor, size: 22.r),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                title,
                style: AppTextStyles.font600SimiBold.copyWith(
                  fontSize: 13.sp,
                  color: AppColors.primaryColor,
                ),
                textDirection: TextDirection.rtl,
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: AppTextStyles.font400Regular.copyWith(
                  fontSize: 11.sp,
                  color: AppColors.secondaryColor,
                ),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Question Flow View ---
  Widget _buildQuestionView() {
    final task = _assessmentState.currentTask;
    final total = _assessmentState.totalTasks;
    final currentIndex = _assessmentState.currentTaskIndex;
    final selectedOptionIndex =
        _assessmentState.getSelectedOptionIndex(task.id);
    final progressFraction = (currentIndex + 1) / total;

    return CustomPadding(
      child: Column(
        children: [
          // Step Counter and Progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            textDirection: TextDirection.rtl,
            children: [
              Text(
                task.domain.arabicLabel,
                style: AppTextStyles.font600SimiBold.copyWith(
                  fontSize: 12.5.sp,
                  color: AppColors.secondaryTextColor,
                ),
              ),
              Text(
                'السؤال ${currentIndex + 1} من $total',
                style: AppTextStyles.font400Regular.copyWith(
                  fontSize: 12.sp,
                  color: AppColors.secondaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: LinearProgressIndicator(
              value: progressFraction,
              minHeight: 6.h,
              backgroundColor: const Color(0xffE4D4FF),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.secondaryTextColor,
              ),
            ),
          ),
          SizedBox(height: 20.h),

          // Question Card & Options (Scrollable)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: const Color(0xffE4D4FF),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          task.title,
                          style: AppTextStyles.font700Bold.copyWith(
                            fontSize: 15.sp,
                            color: AppColors.primaryColor,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          task.description,
                          style: AppTextStyles.font400Regular.copyWith(
                            fontSize: 12.sp,
                            color: AppColors.secondaryColor,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // 4 Selectable Rating Options
                  ...List.generate(task.options.length, (optIdx) {
                    final option = task.options[optIdx];
                    final isSelected = selectedOptionIndex == optIdx;

                    return Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _assessmentState.selectOption(task.id, optIdx);
                          });
                        },
                        borderRadius: BorderRadius.circular(14.r),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 12.h,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xffF1EBFC)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.secondaryTextColor
                                  : const Color(0xffE6E1F0),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_off_rounded,
                                size: 20.r,
                                color: isSelected
                                    ? AppColors.secondaryTextColor
                                    : AppColors.secondaryColor,
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Text(
                                  option.label,
                                  style: AppTextStyles.font400Regular.copyWith(
                                    fontSize: 12.sp,
                                    color: isSelected
                                        ? AppColors.primaryColor
                                        : const Color(0xff2D2D2D),
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  SizedBox(height: 12.h),
                ],
              ),
            ),
          ),

          // Bottom Navigation Row
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Row(
              children: [
                // Left: back button or placeholder
                if (!_assessmentState.isFirstTask)
                  TextButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            setState(() => _assessmentState.previousTask());
                          },
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                    label: const Text('السابق'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryColor,
                    ),
                  )
                else
                  const SizedBox(width: 80),

                SizedBox(width: 12.w),

                // Right: main action button takes remaining space
                Expanded(
                  child: CustomElevatedButton(
                    title: _assessmentState.isLastTask
                        ? 'إرسال التقييم'
                        : 'التالي',
                    isLoading: _isSubmitting,
                    onPressed: !_assessmentState.isCurrentTaskAnswered ||
                            _isSubmitting
                        ? null
                        : () {
                            if (_assessmentState.isLastTask) {
                              _handleSubmit();
                            } else {
                              setState(() => _assessmentState.nextTask());
                            }
                          },
                    height: 40,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Authoritative Result Summary View matching Result AI.png ---
  Widget _buildResultView(BaselineAssessmentModel result) {
    final overallPercent = result.overallScore.clamp(0.0, 100.0);
    final ratingLabel = _getQualitativeScoreText(overallPercent);

    return CustomPadding(
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 10.h),
            Center(
              child: Text(
                'النتيجة الإجماليه',
                style: AppTextStyles.font700Bold.copyWith(
                  fontSize: 22.sp,
                  color: AppColors.primaryColor,
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
            SizedBox(height: 24.h),

            // Circular Gradient Progress Gauge (matches Result AI.png)
            Center(
              child: AnimatedGradientCircularProgress(
                percent: overallPercent,
                size: 140.r,
                strokeWidth: 12.r,
                labelBuilder: (animatedPercent) => Text(
                  '${animatedPercent.round()}%',
                  style: TextStyle(
                    fontSize: 34.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E1B2E),
                    fontFamily: 'Readex Pro',
                  ),
                ),
              ),
            ),
            SizedBox(height: 14.h),
            Center(
              child: Text(
                ratingLabel,
                style: AppTextStyles.font700Bold.copyWith(
                  fontSize: 20.sp,
                  color: AppColors.primaryColor,
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
            SizedBox(height: 24.h),

            // Domain Scores Breakdown Card (Cognitive, Communication, Motor, Emotional)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 20.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22.r),
                border: Border.all(
                  color: const Color(0xffE4D4FF).withValues(alpha: 0.6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildDomainRow(
                    label: 'المهارات الإدراكية',
                    score: result.cognitiveScore,
                  ),
                  SizedBox(height: 16.h),
                  _buildDomainRow(
                    label: 'التواصل',
                    score: result.communicationScore,
                  ),
                  SizedBox(height: 16.h),
                  _buildDomainRow(
                    label: 'المهارات الحركية',
                    score: result.motorScore,
                  ),
                  SizedBox(height: 16.h),
                  _buildDomainRow(
                    label: 'المهارات العاطفية',
                    score: result.emotionalScore,
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // Encouragement Banner (matches Result AI.png bottom card)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: const Color(0xffF3EDFD),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                textDirection: TextDirection.rtl,
                children: [
                  Icon(
                    Icons.favorite_rounded,
                    color: const Color(0xff432F62),
                    size: 26.r,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'يحرز طفلك تقدماً رائعاً.\nاستمر في تشجيعه',
                      style: AppTextStyles.font600SimiBold.copyWith(
                        fontSize: 12.5.sp,
                        color: const Color(0xff432F62),
                        height: 1.4,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // Action Button: "عرض خطة الأنشطة"
            CustomElevatedButton(
              title: 'عرض خطة الأنشطة',
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TreatmentPlanScreen(
                      initialBaseline: result,
                    ),
                  ),
                );
              },
              width: double.infinity,
              height: 48,
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  String _getQualitativeScoreText(double score) {
    if (score >= 85) return 'ممتاز جداً';
    if (score >= 70) return 'جيد جدًا';
    if (score >= 50) return 'جيد';
    return 'يحتاج إلى دعم';
  }

  Widget _buildDomainRow({
    required String label,
    required double score,
  }) {
    final clamped = (score / 100.0).clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          textDirection: TextDirection.rtl,
          children: [
            Text(
              label,
              style: AppTextStyles.font600SimiBold.copyWith(
                fontSize: 13.sp,
                color: AppColors.primaryColor,
              ),
            ),
            Text(
              '${score.round()}%',
              style: AppTextStyles.font600SimiBold.copyWith(
                fontSize: 13.sp,
                color: AppColors.primaryColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(6.r),
          child: LinearProgressIndicator(
            value: clamped,
            minHeight: 8.h,
            backgroundColor: const Color(0xffEDEAF7),
            valueColor: const AlwaysStoppedAnimation<Color>(
              Color(0xff7C3AC6),
            ),
          ),
        ),
      ],
    );
  }
}
