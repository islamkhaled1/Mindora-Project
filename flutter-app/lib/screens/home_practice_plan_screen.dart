import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_colors.dart';
import 'package:sawa/app_text_styles.dart';
import 'package:sawa/core/models/home_practice_models.dart';
import 'package:sawa/core/services/home_practice_service.dart';
import 'package:sawa/core/storage/secure_storage_service.dart';
import 'package:sawa/screens/activities_screen.dart';
import 'package:sawa/screens/treatment_plan_screen.dart';

/// Preliminary Home Practice Plan Screen.
///
/// PRODUCT POSITIONING:
/// This screen presents a preliminary performance profile and personalized
/// home-practice suggestions derived from the child's initial assessment scores.
/// It is NOT a medical treatment plan, clinical prescription, or diagnosis.
///
/// FALLBACK CONTRACT:
/// If the recommendation endpoint fails, this screen automatically falls back
/// to the existing TreatmentPlanScreen. No crash. No data loss.
class HomePracticePlanScreen extends StatefulWidget {
  final bool showBackButton;

  const HomePracticePlanScreen({
    super.key,
    this.showBackButton = false,
  });

  @override
  State<HomePracticePlanScreen> createState() => _HomePracticePlanScreenState();
}

class _HomePracticePlanScreenState extends State<HomePracticePlanScreen> {
  final HomePracticeService _service = HomePracticeService();
  final SecureStorageService _storage = SecureStorageService();

  bool _isLoading = true;
  HomePracticeRecommendationModel? _recommendation;

  // Fallback state: if endpoint fails, show TreatmentPlanScreen instead
  bool _useFallback = false;

  @override
  void initState() {
    super.initState();
    _loadRecommendation();
  }

  Future<void> _loadRecommendation() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final childId = await _storage.getActiveChildId();
      if (childId == null || childId.trim().isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final result = await _service.getRecommendation(childId.trim());

      if (!mounted) return;
      setState(() {
        _recommendation = result;
        _isLoading = false;
        // If service returned null, activate fallback (TreatmentPlanScreen)
        _useFallback = result == null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _useFallback = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Graceful fallback to existing screen on any failure
    if (_useFallback && !_isLoading) {
      return const TreatmentPlanScreen(showBackButton: false);
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryColor,
              ),
            )
          : _recommendation == null
              ? _buildNoAssessmentState()
              : _buildPlanContent(_recommendation!),
    );
  }

  // ─── No Assessment State ─────────────────────────────────────────────────

  Widget _buildNoAssessmentState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80.r,
              height: 80.r,
              decoration: BoxDecoration(
                color: AppColors.circleAvatarColor,
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Icon(
                Icons.assignment_outlined,
                size: 40.r,
                color: AppColors.primaryColor,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'أكمل التقييم الأولي أولاً',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.font700Bold.copyWith(
                fontSize: 18.sp,
                color: AppColors.primaryColor,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'بعد إكمال التقييم الأولي، ستظهر هنا خطة الأنشطة المنزلية المخصصة لطفلك.',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.font400Regular.copyWith(
                fontSize: 13.sp,
                color: AppColors.secondaryColor,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Main Plan Content ────────────────────────────────────────────────────

  Widget _buildPlanContent(HomePracticeRecommendationModel rec) {
    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          backgroundColor: AppColors.backgroundColor,
          expandedHeight: 100.h,
          floating: false,
          pinned: true,
          automaticallyImplyLeading: widget.showBackButton,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: EdgeInsets.only(right: 20.w, bottom: 12.h),
            title: Text(
              'خطة الأنشطة المنزلية',
              textDirection: TextDirection.rtl,
              style: AppTextStyles.font700Bold.copyWith(
                fontSize: 16.sp,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ),

        SliverPadding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── A: Overall Score Card ─────────────────────────────────────
              _buildOverallScoreCard(rec.overallScore),
              SizedBox(height: 20.h),

              // ── B: Strengths ─────────────────────────────────────────────
              if (rec.strengths.isNotEmpty) ...[
                _buildSectionHeader('نقاط القوة', Icons.star_rounded,
                    AppColors.darkGreen),
                SizedBox(height: 10.h),
                ...rec.strengths.map((d) => _buildDomainProfileCard(
                      domain: d,
                      isStrength: true,
                    )),
                SizedBox(height: 20.h),
              ],

              // ── C: Focus Areas ────────────────────────────────────────────
              if (rec.focusAreas.isNotEmpty) ...[
                _buildSectionHeader(
                    'مجالات التركيز', Icons.flag_rounded, AppColors.dartOrange),
                SizedBox(height: 10.h),
                ...rec.focusAreas.map((d) => _buildDomainProfileCard(
                      domain: d,
                      isStrength: false,
                    )),
                SizedBox(height: 20.h),
              ],

              // ── D: Recommended Activities ────────────────────────────────
              _buildSectionHeader('الأنشطة المنزلية المقترحة',
                  Icons.play_circle_rounded, AppColors.primaryColor),
              SizedBox(height: 10.h),

              if (rec.recommendedActivities.isEmpty)
                _buildEmptyActivitiesState()
              else
                ...rec.recommendedActivities
                    .map((a) => _buildActivityCard(a)),

              SizedBox(height: 20.h),

              // ── E: Disclaimer ─────────────────────────────────────────────
              _buildDisclaimerCard(rec.disclaimer),
              SizedBox(height: 16.h),

              // Browse all activities CTA
              _buildBrowseAllButton(),
              SizedBox(height: 24.h),
            ]),
          ),
        ),
      ],
    );
  }

  // ─── Section: Overall Score Card ─────────────────────────────────────────

  Widget _buildOverallScoreCard(double score) {
    final int scoreInt = score.round();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'الملف الأولي للأداء',
            textDirection: TextDirection.rtl,
            style: AppTextStyles.font600SimiBold.copyWith(
              fontSize: 13.sp,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 64.r,
                height: 64.r,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Center(
                  child: Text(
                    '$scoreInt',
                    style: AppTextStyles.font700Bold.copyWith(
                      fontSize: 26.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'المستوى الأولي العام',
                      textDirection: TextDirection.rtl,
                      style: AppTextStyles.font700Bold.copyWith(
                        fontSize: 16.sp,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6.r),
                      child: LinearProgressIndicator(
                        value: score / 100.0,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        color: Colors.white,
                        minHeight: 6.h,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          // Preliminary badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              'تقييم أولي — ليس تشخيصاً طبياً',
              textDirection: TextDirection.rtl,
              style: AppTextStyles.font400Regular.copyWith(
                fontSize: 10.sp,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section: Domain Profile Card ────────────────────────────────────────

  Widget _buildDomainProfileCard({
    required DomainProfileModel domain,
    required bool isStrength,
  }) {
    final Color bgColor =
        isStrength ? AppColors.lightGreen : AppColors.lightOrange;
    final Color accentColor =
        isStrength ? AppColors.darkGreen : AppColors.dartOrange;
    final IconData icon = _domainIcon(domain.assessmentDomain);

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(icon, color: accentColor, size: 22.r),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  domain.assessmentDomainArabic,
                  textDirection: TextDirection.rtl,
                  style: AppTextStyles.font700Bold.copyWith(
                    fontSize: 14.sp,
                    color: AppColors.primaryColor,
                  ),
                ),
                SizedBox(height: 3.h),
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    // Level pill
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        domain.level,
                        style: AppTextStyles.font600SimiBold.copyWith(
                          fontSize: 10.sp,
                          color: accentColor,
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    // No-mapping note for Emotional
                    if (!domain.hasActivityMapping)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: AppColors.cardsColor,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          'متابعة مع المختص',
                          style: AppTextStyles.font400Regular.copyWith(
                            fontSize: 9.sp,
                            color: AppColors.secondaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          // Score circle
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                domain.score.round().toString(),
                style: AppTextStyles.font700Bold.copyWith(
                  fontSize: 15.sp,
                  color: accentColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section: Recommended Activity Card ──────────────────────────────────

  Widget _buildActivityCard(RecommendedActivityModel activity) {
    final bool isHigh = activity.isHighPriority;
    final Color accentColor =
        isHigh ? AppColors.primaryColor : AppColors.darkGreen;
    final Color bgColor =
        isHigh ? AppColors.cardsColor : AppColors.lightGreen;

    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Header row: icon + title + priority badge
            Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46.r,
                  height: 46.r,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(
                    _activityDomainIcon(activity.activityDomain),
                    color: accentColor,
                    size: 22.r,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        activity.title,
                        textDirection: TextDirection.rtl,
                        style: AppTextStyles.font700Bold.copyWith(
                          fontSize: 14.sp,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        activity.activityDomainArabic,
                        textDirection: TextDirection.rtl,
                        style: AppTextStyles.font400Regular.copyWith(
                          fontSize: 11.sp,
                          color: AppColors.secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // Priority badge
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    activity.priorityArabic,
                    style: AppTextStyles.font600SimiBold.copyWith(
                      fontSize: 9.sp,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 10.h),

            // Description
            Text(
              activity.description,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.font400Regular.copyWith(
                fontSize: 12.sp,
                color: AppColors.secondaryColor,
                height: 1.5,
              ),
            ),

            SizedBox(height: 10.h),
            Divider(color: AppColors.circleAvatarColor.withValues(alpha: 0.5), height: 1),
            SizedBox(height: 10.h),

            // Reason row
            Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 14.r, color: AppColors.secondaryTextColor),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    activity.reason,
                    textDirection: TextDirection.rtl,
                    style: AppTextStyles.font400Regular.copyWith(
                      fontSize: 11.sp,
                      color: AppColors.secondaryTextColor,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 10.h),

            // Tags row: difficulty + frequency
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              textDirection: TextDirection.rtl,
              children: [
                _buildTag(
                  icon: Icons.bar_chart_rounded,
                  label: activity.baseDifficultyArabic,
                  color: AppColors.secondaryColor,
                ),
                _buildTag(
                  icon: Icons.calendar_today_rounded,
                  label: 'عدد مرات الممارسة المقترحة: ${activity.suggestedPracticeFrequency}',
                  color: AppColors.primaryColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          Icon(icon, size: 11.r, color: color),
          SizedBox(width: 4.w),
          Text(
            label,
            style: AppTextStyles.font400Regular.copyWith(
              fontSize: 10.sp,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section: Empty Activities ────────────────────────────────────────────

  Widget _buildEmptyActivitiesState() {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.circleAvatarColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Icon(Icons.sports_esports_rounded,
              size: 36.r, color: AppColors.secondaryColor),
          SizedBox(height: 10.h),
          Text(
            'لا تتوفر أنشطة مقترحة حالياً',
            textDirection: TextDirection.rtl,
            style: AppTextStyles.font600SimiBold.copyWith(
              fontSize: 13.sp,
              color: AppColors.secondaryColor,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'يمكنك تصفح جميع الأنشطة المتاحة من الزر أدناه.',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: AppTextStyles.font400Regular.copyWith(
              fontSize: 11.sp,
              color: AppColors.secondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section: Disclaimer ─────────────────────────────────────────────────

  Widget _buildDisclaimerCard(String disclaimer) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.lightYellow,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.darkYellow.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_rounded,
              size: 18.r, color: AppColors.dartOrange),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              disclaimer,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.font400Regular.copyWith(
                fontSize: 12.sp,
                color: const Color(0xFF7A5200),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Browse All Button ────────────────────────────────────────────────────

  Widget _buildBrowseAllButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ActivitiesScreen(showBackButton: true),
            ),
          );
        },
        icon: Icon(Icons.grid_view_rounded,
            size: 18.r, color: AppColors.primaryColor),
        label: Text(
          'تصفح جميع الأنشطة',
          textDirection: TextDirection.rtl,
          style: AppTextStyles.font600SimiBold.copyWith(
            fontSize: 13.sp,
            color: AppColors.primaryColor,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          side: BorderSide(color: AppColors.primaryColor.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
      ),
    );
  }

  // ─── Section Header ───────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Icon(icon, size: 18.r, color: color),
        SizedBox(width: 8.w),
        Text(
          title,
          textDirection: TextDirection.rtl,
          style: AppTextStyles.font700Bold.copyWith(
            fontSize: 15.sp,
            color: AppColors.primaryColor,
          ),
        ),
      ],
    );
  }

  // ─── Domain Icon Helpers ──────────────────────────────────────────────────

  IconData _domainIcon(String domain) {
    switch (domain) {
      case 'Motor':
        return Icons.directions_run_rounded;
      case 'Communication':
        return Icons.record_voice_over_rounded;
      case 'Cognitive':
        return Icons.psychology_rounded;
      case 'Emotional':
        return Icons.favorite_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  IconData _activityDomainIcon(String activityDomain) {
    switch (activityDomain) {
      case 'Movement':
        return Icons.directions_run_rounded;
      case 'Speech':
        return Icons.record_voice_over_rounded;
      case 'Attention':
        return Icons.psychology_rounded;
      default:
        return Icons.sports_esports_rounded;
    }
  }
}
