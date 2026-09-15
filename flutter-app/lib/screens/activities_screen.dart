import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_text_styles.dart';
import 'package:sawa/constants.dart';
import 'package:sawa/core/errors/api_exception.dart';
import 'package:sawa/core/models/activity_models.dart';
import 'package:sawa/core/services/activity_service.dart';
import 'package:sawa/screens/activity_details_screen.dart';
import 'package:sawa/widgets/back_icon.dart';
import 'package:sawa/widgets/custom_app_bar.dart';
import 'package:sawa/widgets/custom_elevated_button.dart';
import 'package:sawa/widgets/custom_padding.dart';
import 'package:sawa/widgets/custom_title.dart';

class ActivitiesScreen extends StatefulWidget {
  final String? initialDomain;
  final bool showBackButton;
  final List<ActivityModel>? initialActivities;

  const ActivitiesScreen({
    super.key,
    this.initialDomain,
    this.showBackButton = true,
    this.initialActivities,
  });

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  final ActivityService _activityService = ActivityService();

  String? _selectedDomain;
  String? _selectedDifficulty;

  List<ActivityModel> _activities = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedDomain = widget.initialDomain;
    if (widget.initialActivities != null && widget.initialActivities!.isNotEmpty) {
      _activities = widget.initialActivities!;
      _isLoading = false;
    } else {
      _fetchActivities();
    }
  }

  Future<void> _fetchActivities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await _activityService.getActivities(
        domain: _selectedDomain,
        difficulty: _selectedDifficulty,
      );
      if (mounted) {
        setState(() {
          _activities = results;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.firstErrorMessage;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'تعذر تحميل قائمة الأنشطة. يرجى التحقق من الاتصال بالإنترنت.';
          _isLoading = false;
        });
      }
    }
  }

  void _onDomainChanged(String? domain) {
    if (_selectedDomain == domain) return;
    setState(() {
      _selectedDomain = domain;
    });
    _fetchActivities();
  }

  void _onDifficultyChanged(String? difficulty) {
    if (_selectedDifficulty == difficulty) return;
    setState(() {
      _selectedDifficulty = difficulty;
    });
    _fetchActivities();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: CustomAppBar(
        leading: widget.showBackButton ? const BackIcon() : const SizedBox.shrink(),
      ),
      body: CustomPadding(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 8.h),
            const Center(
              child: CustomTitle(
                title: 'دليل الأنشطة والتمارين',
                fontSize: 20,
              ),
            ),
            SizedBox(height: 4.h),
            Center(
              child: Text(
                'استكشف الأنشطة التأهيلية المعتمدة والمصنفة حسب المهارة والصعوبة',
                style: AppTextStyles.font400Regular.copyWith(
                  fontSize: 12.sp,
                  color: AppColors.secondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 16.h),

            // Domain Filter Chips
            _buildDomainFilterSection(),
            SizedBox(height: 10.h),

            // Difficulty Filter Chips
            _buildDifficultyFilterSection(),
            SizedBox(height: 16.h),

            // Activity List / States
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDomainFilterSection() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      reverse: true, // RTL order
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          _buildFilterChip(
            label: 'كل المجالات',
            isSelected: _selectedDomain == null,
            onTap: () => _onDomainChanged(null),
          ),
          ...ActivityDomainEnum.values.map(
            (domain) => _buildFilterChip(
              label: domain.arabicLabel,
              icon: domain.icon,
              isSelected: _selectedDomain == domain.backendValue,
              onTap: () => _onDomainChanged(domain.backendValue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyFilterSection() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      reverse: true, // RTL order
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          _buildFilterChip(
            label: 'كل المستويات',
            isSelected: _selectedDifficulty == null,
            onTap: () => _onDifficultyChanged(null),
            isSecondary: true,
          ),
          ...ActivityDifficultyEnum.values.map(
            (diff) => _buildFilterChip(
              label: diff.arabicLabel,
              isSelected: _selectedDifficulty == diff.backendValue,
              onTap: () => _onDifficultyChanged(diff.backendValue),
              isSecondary: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
    bool isSecondary = false,
  }) {
    final activeBgColor =
        isSecondary ? AppColors.primaryColor : AppColors.secondaryTextColor;
    return Padding(
      padding: EdgeInsets.only(left: 6.w),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: isSelected ? activeBgColor : Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isSelected ? activeBgColor : const Color(0xffE4D4FF),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeBgColor.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14.r,
                  color: isSelected ? Colors.white : AppColors.secondaryTextColor,
                ),
                SizedBox(width: 4.w),
              ],
              Text(
                label,
                style: AppTextStyles.font500Medium.copyWith(
                  fontSize: 11.sp,
                  color: isSelected ? Colors.white : AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
            SizedBox(height: 16.h),
            Text(
              'جارٍ تحميل الأنشطة من الخادم...',
              style: AppTextStyles.font400Regular.copyWith(
                fontSize: 13.sp,
                color: AppColors.secondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48.r,
              color: Colors.red.shade400,
            ),
            SizedBox(height: 12.h),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: AppTextStyles.font500Medium.copyWith(
                fontSize: 13.sp,
                color: AppColors.primaryColor,
              ),
            ),
            SizedBox(height: 16.h),
            CustomElevatedButton(
              title: 'إعادة المحاولة',
              onPressed: _fetchActivities,
              width: 140,
              height: 38,
            ),
          ],
        ),
      );
    }

    if (_activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_esports_outlined,
              size: 56.r,
              color: AppColors.secondaryColor.withValues(alpha: 0.5),
            ),
            SizedBox(height: 12.h),
            Text(
              'لا توجد أنشطة متوفرة لهذا التصنيف حاليًا',
              style: AppTextStyles.font600SimiBold.copyWith(
                fontSize: 14.sp,
                color: AppColors.primaryColor,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'جرب تغيير خيارات التصفية لعرض أنشطة أخرى',
              style: AppTextStyles.font400Regular.copyWith(
                fontSize: 12.sp,
                color: AppColors.secondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchActivities,
      color: AppColors.primaryColor,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: _activities.length,
        separatorBuilder: (context, index) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          final activity = _activities[index];
          return _buildActivityCard(activity);
        },
      ),
    );
  }

  Widget _buildActivityCard(ActivityModel activity) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xffE4D4FF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () {
            if (activity.domainEnum == ActivityDomainEnum.speech ||
                activity.domain.toLowerCase() == 'speech') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تدريب النطق غير متاح حاليًا.')),
              );
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ActivityDetailsScreen(
                  activityId: activity.id,
                  initialActivity: activity,
                ),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Domain Icon Badge
                Container(
                  width: 46.r,
                  height: 46.r,
                  decoration: BoxDecoration(
                    color: AppColors.circleAvatarColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    activity.domainIcon,
                    size: 24.r,
                    color: AppColors.primaryColor,
                  ),
                ),
                SizedBox(width: 12.w),

                // Details Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: TextDirection.rtl,
                    children: [
                      Text(
                        activity.title,
                        style: AppTextStyles.font600SimiBold.copyWith(
                          fontSize: 14.sp,
                          color: AppColors.primaryColor,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        activity.description,
                        maxLines: 2,
                        overflow: TextDirection.rtl == TextDirection.rtl
                            ? TextOverflow.ellipsis
                            : TextOverflow.ellipsis,
                        style: AppTextStyles.font400Regular.copyWith(
                          fontSize: 12.sp,
                          color: AppColors.secondaryColor,
                          height: 1.4,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      SizedBox(height: 10.h),
                      Wrap(
                        textDirection: TextDirection.rtl,
                        spacing: 6.w,
                        runSpacing: 4.h,
                        children: [
                          _buildCardBadge(
                            label: (activity.domainEnum == ActivityDomainEnum.speech ||
                                    activity.domain.toLowerCase() == 'speech')
                                ? 'غير متاح حاليًا'
                                : 'متاح الآن',
                            bgColor: (activity.domainEnum == ActivityDomainEnum.speech ||
                                    activity.domain.toLowerCase() == 'speech')
                                ? const Color(0xffFFEBEE)
                                : const Color(0xffE8F5E9),
                            textColor: (activity.domainEnum == ActivityDomainEnum.speech ||
                                    activity.domain.toLowerCase() == 'speech')
                                ? const Color(0xffC62828)
                                : const Color(0xff2E7D32),
                          ),
                          _buildCardBadge(
                            label: activity.domainArabicLabel,
                            bgColor: const Color(0xffF0E8FF),
                            textColor: AppColors.primaryColor,
                          ),
                          _buildCardBadge(
                            label: activity.difficultyArabicLabel,
                            bgColor: const Color(0xffFFF3E0),
                            textColor: const Color(0xffE65100),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),

                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16.r,
                  color: AppColors.secondaryTextColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardBadge({
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        label,
        style: AppTextStyles.font500Medium.copyWith(
          fontSize: 10.sp,
          color: textColor,
        ),
      ),
    );
  }
}
