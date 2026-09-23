import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_text_styles.dart';
import 'package:sawa/constants.dart';
import 'package:sawa/core/models/activity_models.dart';
import 'package:sawa/core/models/baseline_assessment_models.dart';
import 'package:sawa/core/services/activity_service.dart';
import 'package:sawa/core/services/baseline_assessment_service.dart';
import 'package:sawa/core/storage/secure_storage_service.dart';
import 'package:sawa/screens/activities_screen.dart';

class TreatmentPlanScreen extends StatefulWidget {
  final BaselineAssessmentModel? initialBaseline;
  final List<ActivityModel>? initialActivities;
  final bool showBackButton;

  const TreatmentPlanScreen({
    super.key,
    this.initialBaseline,
    this.initialActivities,
    this.showBackButton = true,
  });

  @override
  State<TreatmentPlanScreen> createState() => _TreatmentPlanScreenState();
}

class _TreatmentPlanScreenState extends State<TreatmentPlanScreen> {
  final BaselineAssessmentService _baselineService = BaselineAssessmentService();
  final ActivityService _activityService = ActivityService();
  final SecureStorageService _storage = SecureStorageService();

  bool _isLoading = true;
  String? _errorMessage;
  BaselineAssessmentModel? _baseline;
  List<ActivityModel> _activities = [];

  @override
  void initState() {
    super.initState();
    _baseline = widget.initialBaseline;
    _activities = widget.initialActivities ?? [];
    if (_baseline != null && _activities.isNotEmpty) {
      _isLoading = false;
    } else {
      _loadPlanData();
    }
  }

  Future<void> _loadPlanData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final childId = await _storage.getActiveChildId();
      if (childId == null || childId.isEmpty) {
        setState(() {
          _errorMessage = 'لا يوجد طفل نشط مسجل حالياً.';
          _isLoading = false;
        });
        return;
      }

      final baselineFuture = _baseline != null
          ? Future.value(_baseline)
          : _baselineService.getLatestBaselineAssessment(childId);
      final activitiesFuture = _activityService.getActivities();

      final results = await Future.wait([baselineFuture, activitiesFuture]);

      if (mounted) {
        setState(() {
          _baseline = results[0] as BaselineAssessmentModel?;
          _activities = results[1] as List<ActivityModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'تعذر تحميل بيانات خطة الأنشطة: $e';
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildDomainCard({
    required String title,
    required String description,
    required String levelLabel,
    required int activitiesCount,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.circleAvatarColor.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Domain Icon box
                Container(
                  width: 48.r,
                  height: 48.r,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Icon(icon, color: iconColor, size: 24.r),
                ),
                SizedBox(width: 14.w),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: TextDirection.rtl,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.font700Bold.copyWith(
                          fontSize: 15.sp,
                          color: AppColors.primaryColor,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        description,
                        style: AppTextStyles.font400Regular.copyWith(
                          fontSize: 11.sp,
                          color: AppColors.secondaryColor,
                          height: 1.4,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      SizedBox(height: 10.h),

                      // Level Tag & Activities Count pill
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 6.h,
                        textDirection: TextDirection.rtl,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: AppColors.circleAvatarColor.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              levelLabel,
                              style: AppTextStyles.font600SimiBold.copyWith(
                                fontSize: 11.sp,
                                color: AppColors.primaryColor,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundColor,
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(color: AppColors.circleAvatarColor),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              textDirection: TextDirection.rtl,
                              children: [
                                Icon(Icons.timer_outlined, size: 13.r, color: AppColors.secondaryTextColor),
                                SizedBox(width: 4.w),
                                Text(
                                  '$activitiesCount تمارين متوفرة',
                                  style: AppTextStyles.font500Medium.copyWith(
                                    fontSize: 11.sp,
                                    color: AppColors.secondaryTextColor,
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final movementActivities = _activities.where((a) => a.domain.toLowerCase().contains('movement')).length;
    final speechActivities = _activities.where((a) => a.domain.toLowerCase().contains('speech')).length;
    final cognitiveActivities = _activities.where((a) => a.domain.toLowerCase().contains('cognitive')).length;
    final socialActivities = _activities.where((a) => a.domain.toLowerCase().contains('social')).length;

    String getScoreLevel(double? score) {
      if (score == null) return 'مستوى تمهيدي';
      if (score >= 75) return 'مستوى متقدم';
      if (score >= 50) return 'مستوى متوسط';
      return 'مستوى أولي';
    }

    final speechLevel = getScoreLevel(_baseline?.communicationScore);
    final movementLevel = getScoreLevel(_baseline?.motorScore);
    final attentionLevel = getScoreLevel(_baseline?.cognitiveScore);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: widget.showBackButton
            ? Container(
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
                  onPressed: () => Navigator.pop(context),
                ),
              )
            : const SizedBox.shrink(),
        title: Text(
          'خطة الأنشطة',
          style: AppTextStyles.font700Bold.copyWith(
            fontSize: 18.sp,
            color: AppColors.primaryColor,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.secondaryTextColor))
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.r),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline_rounded, size: 48.r, color: Colors.redAccent),
                          SizedBox(height: 12.h),
                          Text(
                            _errorMessage!,
                            style: AppTextStyles.font500Medium.copyWith(
                              fontSize: 14.sp,
                              color: AppColors.primaryColor,
                            ),
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                          ),
                          SizedBox(height: 16.h),
                          ElevatedButton(
                            onPressed: _loadPlanData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondaryTextColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                            ),
                            child: const Text('إعادة المحاولة', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    children: [
                      // Subtitle Header
                      Text(
                        'خطة أنشطة منزلية مبدئية لطفلك بناءً على نتائج التقييم الأولي، لمساعدته على التطور خطوة بخطوة.',
                        style: AppTextStyles.font400Regular.copyWith(
                          fontSize: 13.sp,
                          color: AppColors.secondaryColor,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                      ),
                      SizedBox(height: 20.h),

                      // Section Title
                      Text(
                        'مجالات الأنشطة',
                        style: AppTextStyles.font700Bold.copyWith(
                          fontSize: 16.sp,
                          color: AppColors.primaryColor,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      SizedBox(height: 12.h),

                      // 1. Speech & Language (التواصل واللغة)
                      _buildDomainCard(
                        title: 'التواصل واللغة',
                        description: 'تحسين مهارات التواصل والتعبير عن الاحتياجات وفهم اللغة.',
                        levelLabel: 'المستوى: $speechLevel',
                        activitiesCount: speechActivities > 0 ? speechActivities : 2,
                        icon: Icons.chat_bubble_rounded,
                        iconColor: AppColors.secondaryTextColor,
                        iconBgColor: AppColors.circleAvatarColor.withValues(alpha: 0.5),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ActivitiesScreen()),
                          );
                        },
                      ),

                      // 2. Motor Skills (المهارات الحركية)
                      _buildDomainCard(
                        title: 'المهارات الحركية',
                        description: 'تطوير التوازن، التنسيق الحركي، والمهارات الحركية الدقيقة والكبيرة.',
                        levelLabel: 'المستوى: $movementLevel',
                        activitiesCount: movementActivities > 0 ? movementActivities : 2,
                        icon: Icons.directions_run_rounded,
                        iconColor: const Color(0xffFDB62C),
                        iconBgColor: const Color(0xffFFF3DC),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ActivitiesScreen()),
                          );
                        },
                      ),

                      // 3. Cognitive & Learning (الإدراك والتعلم)
                      _buildDomainCard(
                        title: 'الإدراك والتعلم',
                        description: 'تنمية الانتباه، الذاكرة، حل المشكلات والاستقلالية في التعلم.',
                        levelLabel: 'المستوى: $attentionLevel',
                        activitiesCount: cognitiveActivities > 0 ? cognitiveActivities : 1,
                        icon: Icons.psychology_rounded,
                        iconColor: const Color(0xff6DAA60),
                        iconBgColor: const Color(0xffEAF5E8),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ActivitiesScreen()),
                          );
                        },
                      ),

                      // 4. Social & Emotional (المهارات الاجتماعية والعاطفية)
                      _buildDomainCard(
                        title: 'المهارات الاجتماعية والعاطفية',
                        description: 'تعزيز التفاعل الاجتماعي، بناء العلاقات، والتعبير عن المشاعر بشكل إيجابي.',
                        levelLabel: 'المستوى: مستقر',
                        activitiesCount: socialActivities > 0 ? socialActivities : 1,
                        icon: Icons.handshake_rounded,
                        iconColor: const Color(0xffBD3737),
                        iconBgColor: const Color(0xffFDEAEA),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ActivitiesScreen()),
                          );
                        },
                      ),

                      SizedBox(height: 12.h),

                      // Bottom Informational Card
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                        decoration: BoxDecoration(
                          color: AppColors.circleAvatarColor.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(18.r),
                          border: Border.all(color: AppColors.circleAvatarColor),
                        ),
                        child: Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            Icon(
                              Icons.favorite_rounded,
                              size: 24.r,
                              color: AppColors.primaryColor,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                'تُراجع الخطة بشكل دوري وتُعدّل حسب تقدم طفلك واحتياجاته لتحقيق أفضل النتائج.',
                                style: AppTextStyles.font500Medium.copyWith(
                                  fontSize: 12.sp,
                                  color: AppColors.primaryColor,
                                  height: 1.4,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
                    ],
                  ),
      ),
    );
  }
}
