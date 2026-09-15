import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_text_styles.dart';
import 'package:sawa/constants.dart';
import 'package:sawa/core/models/activity_models.dart';
import 'package:sawa/core/models/session_models.dart';
import 'package:sawa/screens/home_screen.dart';
import 'package:sawa/screens/parent_observation_screen.dart';
import 'package:sawa/screens/progress_screen.dart';
import 'package:sawa/widgets/animated_gradient_circular_progress.dart';
import 'package:sawa/widgets/custom_app_bar.dart';

/// Screen managing post-session results according to SAWA design:
/// - Step 1 (`Result.png`): Daily performance circular gauge and domain badges, leading to ParentObservationScreen.
/// - Step 2 (`session complete.png`): Session summary breakdown and completed exercises, leading to Home or Progress.
class SessionResultScreen extends StatefulWidget {
  final CompletedSessionModel completedSession;
  final ActivityModel activity;
  final int initialStep;
  final String? childName;

  const SessionResultScreen({
    super.key,
    required this.completedSession,
    required this.activity,
    this.initialStep = 1,
    this.childName,
  });

  @override
  State<SessionResultScreen> createState() => _SessionResultScreenState();
}

class _SessionResultScreenState extends State<SessionResultScreen> {
  late int _currentStep;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
  }

  double _getOverallScore() {
    final analysis = widget.completedSession.analysisResult;
    if (analysis != null && analysis.overallPerformanceScore > 0) {
      return analysis.overallPerformanceScore;
    }
    return 85.0;
  }

  String _getQualitativeScoreLabel(double score) {
    if (score >= 85) return 'أداء جيد جداً';
    if (score >= 70) return 'أداء جيد';
    if (score >= 50) return 'مستوى مقبول';
    return 'يحتاج إلى تشجيع';
  }

  String _formatDuration(int? seconds) {
    final sec = seconds ?? 615; // default 10:15
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
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
              if (_currentStep == 2) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
                );
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ),
      ),
      body: SafeArea(
        child: _currentStep == 1 ? _buildStep1ResultView() : _buildStep2CompleteView(),
      ),
    );
  }

  // ==========================================
  // STEP 1: Matching Result.png
  // ==========================================
  Widget _buildStep1ResultView() {
    final overallScore = _getOverallScore();

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 4.h),

          // Header Title & Subtitle
          Text(
            'نتائج تمارين اليوم',
            style: AppTextStyles.font700Bold.copyWith(
              fontSize: 22.sp,
              color: AppColors.primaryColor,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          SizedBox(height: 6.h),
          Text(
            'شاطر جدا\nأكملت جميع تمارين اليوم',
            style: AppTextStyles.font400Regular.copyWith(
              fontSize: 13.sp,
              color: AppColors.secondaryColor,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          SizedBox(height: 24.h),

          // Card 1: النتيجة الإجمالية (Gauge Card)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(
                color: AppColors.circleAvatarColor.withValues(alpha: 0.6),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'النتيجة الإجمالية',
                  style: AppTextStyles.font700Bold.copyWith(
                    fontSize: 16.sp,
                    color: AppColors.primaryColor,
                  ),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
                SizedBox(height: 20.h),

                // Circular Gradient Gauge
                AnimatedGradientCircularProgress(
                  percent: overallScore,
                  size: 165.r,
                  strokeWidth: 12.r,
                  labelBuilder: (animatedPercent) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${animatedPercent.round()}%',
                        style: AppTextStyles.font700Bold.copyWith(
                          fontSize: 28.sp,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        _getQualitativeScoreLabel(animatedPercent),
                        style: AppTextStyles.font600SimiBold.copyWith(
                          fontSize: 12.sp,
                          color: AppColors.primaryColor,
                        ),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'استمري في هذا التقدم',
                        style: AppTextStyles.font400Regular.copyWith(
                          fontSize: 10.sp,
                          color: AppColors.secondaryColor,
                        ),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
              ],
            ),
          ),
          SizedBox(height: 20.h),

          // Card 2: تمارين اليوم (3 Domain Badges)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(
                color: AppColors.circleAvatarColor.withValues(alpha: 0.6),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'تمارين اليوم',
                  style: AppTextStyles.font700Bold.copyWith(
                    fontSize: 16.sp,
                    color: AppColors.primaryColor,
                  ),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
                SizedBox(height: 18.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  textDirection: TextDirection.rtl,
                  children: [
                    Expanded(
                      child: _buildResultDomainItem(
                        icon: Icons.directions_run_rounded,
                        iconColor: const Color(0xffFDB62C),
                        bgColor: const Color(0xffFDF4E9),
                        label: 'الحركة',
                      ),
                    ),
                    Expanded(
                      child: _buildResultDomainItem(
                        icon: Icons.psychology_rounded,
                        iconColor: const Color(0xff6DAA60),
                        bgColor: const Color(0xffEEF3EE),
                        label: 'الفهم والإدراك',
                      ),
                    ),
                    Expanded(
                      child: _buildResultDomainItem(
                        icon: Icons.chat_bubble_rounded,
                        iconColor: AppColors.secondaryTextColor,
                        bgColor: const Color(0xffEDE5FC),
                        label: 'التواصل',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 36.h),

          // CTA Button: التالي (leads to ParentObservationScreen)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ParentObservationScreen(
                      completedSession: widget.completedSession,
                      activity: widget.activity,
                      childName: widget.childName,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryTextColor,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
                elevation: 2,
              ),
              child: Text(
                'التالي',
                style: AppTextStyles.font700Bold.copyWith(
                  fontSize: 16.sp,
                  color: Colors.white,
                  fontFamily: 'Readex Pro',
                ),
              ),
            ),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildResultDomainItem({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          width: 54.r,
          height: 54.r,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Icon(icon, color: iconColor, size: 28.r),
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          style: AppTextStyles.font600SimiBold.copyWith(
            fontSize: 12.sp,
            color: AppColors.primaryColor,
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        ),
      ],
    );
  }

  // ==========================================
  // STEP 2: Matching session complete.png
  // ==========================================
  Widget _buildStep2CompleteView() {
    final childDisplay = (widget.childName != null && widget.childName!.trim().isNotEmpty)
        ? widget.childName!.trim()
        : 'البطل';
    final overallScore = _getOverallScore().round();
    final durationFormatted = _formatDuration(widget.completedSession.actualDurationSeconds);
    final completedCount = widget.completedSession.metrics.isNotEmpty
        ? widget.completedSession.metrics.length
        : 3;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 4.h),

          // Header Title & Subtitle matching session complete.png
          Text(
            'انتهت الجلسة',
            style: AppTextStyles.font700Bold.copyWith(
              fontSize: 22.sp,
              color: AppColors.primaryColor,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          SizedBox(height: 6.h),
          Text(
            'أحسنت يا $childDisplay، عمل رائع اليوم',
            style: AppTextStyles.font400Regular.copyWith(
              fontSize: 13.sp,
              color: AppColors.secondaryColor,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          SizedBox(height: 24.h),

          // Container 1: ملخص الجلسة with 3 stat cards
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 18.h),
            decoration: BoxDecoration(
              color: const Color(0xffF9F6FF),
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(
                color: const Color(0xffE2D7F7),
                width: 1.2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'ملخص الجلسة',
                  style: AppTextStyles.font700Bold.copyWith(
                    fontSize: 16.sp,
                    color: AppColors.primaryColor,
                  ),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
                SizedBox(height: 16.h),
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    // 1. Right in RTL: الوقت الكلي
                    Expanded(
                      child: _buildSummaryMetricCard(
                        icon: Icons.access_time_rounded,
                        iconColor: AppColors.primaryColor,
                        value: durationFormatted,
                        label: 'الوقت الكلي',
                      ),
                    ),
                    SizedBox(width: 10.w),
                    // 2. Middle: متوسط الأداء
                    Expanded(
                      child: _buildSummaryMetricCard(
                        icon: Icons.star_border_rounded,
                        iconColor: AppColors.primaryColor,
                        value: '$overallScore%',
                        label: 'متوسط الأداء',
                      ),
                    ),
                    SizedBox(width: 10.w),
                    // 3. Left in RTL: تمارين مكتملة
                    Expanded(
                      child: _buildSummaryMetricCard(
                        icon: Icons.assignment_turned_in_outlined,
                        iconColor: AppColors.primaryColor,
                        value: '$completedCount',
                        label: 'تمارين مكتملة',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          // Container 2: التمارين التي أكملها عمر
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'التمارين التي أكملها $childDisplay',
              style: AppTextStyles.font700Bold.copyWith(
                fontSize: 16.sp,
                color: AppColors.primaryColor,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
          SizedBox(height: 12.h),

          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: AppColors.circleAvatarColor.withValues(alpha: 0.7),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildCompletedExerciseRow(
                  title: widget.activity.title.isNotEmpty
                      ? widget.activity.title
                      : 'قولها معايا',
                  score: 80,
                  icon: Icons.chat_bubble_rounded,
                  iconColor: AppColors.secondaryTextColor,
                  iconBg: const Color(0xffEDE5FC),
                ),
                Divider(height: 1, color: AppColors.circleAvatarColor.withValues(alpha: 0.5)),
                _buildCompletedExerciseRow(
                  title: 'اسمع وابحث',
                  score: 70,
                  icon: Icons.psychology_rounded,
                  iconColor: const Color(0xff6DAA60),
                  iconBg: const Color(0xffEEF3EE),
                ),
                Divider(height: 1, color: AppColors.circleAvatarColor.withValues(alpha: 0.5)),
                _buildCompletedExerciseRow(
                  title: 'اتبع الحركة',
                  score: 85,
                  icon: Icons.directions_run_rounded,
                  iconColor: const Color(0xffFDB62C),
                  iconBg: const Color(0xffFDF4E9),
                ),
              ],
            ),
          ),
          SizedBox(height: 36.h),

          // Bottom Action Buttons: [عرض التقدم] & [العوده للرئيسية]
          Row(
            textDirection: TextDirection.rtl,
            children: [
              // Button 1 (RTL right): العوده للرئيسية
              Expanded(
                flex: 6,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryTextColor,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'العوده للرئيسية',
                    style: AppTextStyles.font700Bold.copyWith(
                      fontSize: 15.sp,
                      color: Colors.white,
                      fontFamily: 'Readex Pro',
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),

              // Button 2 (RTL left): عرض التقدم
              Expanded(
                flex: 5,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProgressScreen(
                          showBackButton: true,
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    side: const BorderSide(color: Color(0xffE2D7F7), width: 1.5),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                  ),
                  child: Text(
                    'عرض التقدم',
                    style: AppTextStyles.font700Bold.copyWith(
                      fontSize: 15.sp,
                      color: AppColors.primaryColor,
                      fontFamily: 'Readex Pro',
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildSummaryMetricCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 26.r),
          SizedBox(height: 8.h),
          Text(
            value,
            style: AppTextStyles.font700Bold.copyWith(
              fontSize: 17.sp,
              color: AppColors.primaryColor,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: AppTextStyles.font500Medium.copyWith(
              fontSize: 10.5.sp,
              color: AppColors.secondaryColor,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedExerciseRow({
    required String title,
    required int score,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: iconColor, size: 22.r),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.font600SimiBold.copyWith(
                fontSize: 14.sp,
                color: AppColors.primaryColor,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
          Text(
            '%$score',
            style: AppTextStyles.font700Bold.copyWith(
              fontSize: 15.sp,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
