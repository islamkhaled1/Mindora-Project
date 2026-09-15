import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_text_styles.dart';
import 'package:sawa/app_colors.dart';
import 'package:sawa/app_icons.dart';
import 'package:sawa/constants.dart';
import 'package:sawa/core/errors/api_exception.dart';
import 'package:sawa/core/models/activity_models.dart';
import 'package:sawa/core/models/baseline_assessment_models.dart';
import 'package:sawa/core/models/child_model.dart';
import 'package:sawa/core/services/activity_service.dart';
import 'package:sawa/core/services/baseline_assessment_service.dart';
import 'package:sawa/core/services/children_service.dart';
import 'package:sawa/core/storage/secure_storage_service.dart';
import 'package:sawa/screens/activities_screen.dart';
import 'package:sawa/screens/activity_details_screen.dart';
import 'package:sawa/screens/ai_assessment_screen.dart';
import 'package:sawa/screens/ai_chat_screen.dart';
import 'package:sawa/screens/child_information_first_screen.dart';
import 'package:sawa/screens/practise_screen.dart';
import 'package:sawa/screens/profile_screen.dart';
import 'package:sawa/screens/progress_screen.dart';
import 'package:sawa/screens/treatment_plan_screen.dart';
import 'package:sawa/widgets/animated_gradient_circular_progress.dart';
import 'package:sawa/widgets/custom_app_bar.dart';
import 'package:sawa/widgets/custom_elevated_button.dart';
import 'package:sawa/widgets/custom_padding.dart';
import 'package:sawa/widgets/custom_title.dart';
import 'package:sawa/widgets/description.dart';
import 'package:sawa/widgets/home_card.dart';
import 'package:sawa/widgets/image_circle_avatar.dart';
import 'package:sawa/widgets/medium_title.dart';
import 'package:sawa/widgets/notification_leading.dart';
import 'package:sawa/widgets/simi_bold_title.dart';
import 'package:sawa/widgets/welcome_card.dart';

class HomeScreen extends StatefulWidget {
  final ChildModel? initialChild;
  final BaselineAssessmentModel? initialBaseline;
  final List<ActivityModel>? initialActivities;

  const HomeScreen({
    super.key,
    this.initialChild,
    this.initialBaseline,
    this.initialActivities,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0;

  final SecureStorageService _storage = SecureStorageService();
  final ChildrenService _childrenService = ChildrenService();
  final BaselineAssessmentService _baselineService =
      BaselineAssessmentService();
  final ActivityService _activityService = ActivityService();

  String? _activeChildId;
  ChildModel? _child;
  BaselineAssessmentModel? _baseline;
  List<ActivityModel> _activities = [];

  bool _isLoading = true;
  String? _errorMessage;
  bool _hasNoActiveChild = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialChild != null) {
      _child = widget.initialChild;
      _activeChildId = widget.initialChild!.id;
      _baseline = widget.initialBaseline;
      _activities = widget.initialActivities ?? [];
      _isLoading = false;
    } else {
      _loadHomeData();
    }
  }

  Future<void> _loadHomeData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasNoActiveChild = false;
    });

    try {
      var childId = await _storage.getActiveChildId();
      ChildModel? currentChild;

      if (childId != null && childId.trim().isNotEmpty) {
        try {
          currentChild = await _childrenService.getChildById(childId.trim());
        } catch (_) {
          currentChild = null;
        }
      }

      if (currentChild == null) {
        final children = await _childrenService.getChildren();
        if (children.isNotEmpty) {
          final first = children.first;
          currentChild = first;
          childId = first.id;
          await _storage.saveActiveChildId(childId);
        } else {
          if (mounted) {
            setState(() {
              _hasNoActiveChild = true;
              _isLoading = false;
            });
          }
          return;
        }
      }

      _activeChildId = childId!.trim();
      _child = currentChild;

      final baselineFuture =
          _baselineService.getLatestBaselineAssessment(_activeChildId!);
      final activitiesFuture = _activityService.getActivities();

      final results = await Future.wait([
        baselineFuture,
        activitiesFuture,
      ]);

      if (mounted) {
        setState(() {
          _baseline = results[0] as BaselineAssessmentModel?;
          _activities = results[1] as List<ActivityModel>;
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'تعذر تحميل بيانات الصفحة الرئيسية. يرجى المحاولة مرة أخرى.';
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToActivitiesCatalog({String? domainFilter}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivitiesScreen(
          initialDomain: domainFilter,
          showBackButton: true,
        ),
      ),
    );
  }

  void _navigateToProgress() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProgressScreen(
          showBackButton: true,
        ),
      ),
    );
  }

  double _calculateProgressPercent() {
    if (_baseline != null) {
      if (_baseline!.overallScore > 0) {
        return _baseline!.overallScore.clamp(10.0, 100.0);
      }
      final total = _baseline!.motorScore +
          _baseline!.communicationScore +
          _baseline!.cognitiveScore;
      return (total / 300.0 * 100.0).clamp(10.0, 100.0);
    }
    return 75.0;
  }

  @override
  Widget build(BuildContext context) {
    final childFullName = _child?.fullName.isNotEmpty == true
        ? _child!.fullName
        : 'البطل';
    final childFirstName = childFullName.split(' ').first;

    return PopScope(
      canPop: _currentTabIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentTabIndex > 0) {
          setState(() {
            _currentTabIndex = 0;
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: _currentTabIndex == 0 ? _buildHomeAppBar(childFirstName) : null,
        bottomNavigationBar: _buildBottomNavigationBar(),
        floatingActionButton: _currentTabIndex == 0
            ? FloatingActionButton.extended(
                onPressed: () {
                  setState(() {
                    _currentTabIndex = 2;
                  });
                },
                backgroundColor: AppColors.primaryColor,
                elevation: 3,
                icon: const Icon(Icons.smart_toy_rounded, color: Colors.white),
                label: Text(
                  'استشر المساعد الذكي',
                  style: AppTextStyles.font600SimiBold.copyWith(
                    fontSize: 12.sp,
                    color: Colors.white,
                    fontFamily: 'Readex Pro',
                  ),
                ),
              )
            : null,
        body: IndexedStack(
          index: _currentTabIndex,
          children: [
            SafeArea(
              child: CustomPadding(
                child: _buildBody(),
              ),
            ),
            TreatmentPlanScreen(
              showBackButton: false,
              initialBaseline: _baseline,
              initialActivities: _activities,
            ),
            const AiChatScreen(
              showBackButton: false,
            ),
            PractiseScreen(
              showBackButton: false,
              gender: _child?.gender,
              avatarUrl: _child?.avatarUrl,
            ),
            ProfileScreen(
              showBackButton: false,
              initialChild: _child,
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildHomeAppBar(String childFirstName) {
    return CustomAppBar(
      height: 70.h,
      leadingWidth: 56.w,
      leading: Center(
        child: NotificationLeading(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('لا توجد إشعارات جديدة حاليًا'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 8.w, left: 4.w),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SimiBoldTitle(title: 'مرحباً ', fontSize: 13),
                  MediumTitle(
                    title: 'إزاي حال $childFirstName النهاردة؟',
                    fontSize: 12,
                    color: AppColors.secondaryColor,
                  ),
                ],
              ),
              SizedBox(width: 8.w),
              ImageCircleAvatar(
                gender: _child?.gender,
                avatarUrl: _child?.avatarUrl,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 68.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavTabItem(
              index: 0,
              activeIcon: Icons.home_rounded,
              inactiveIcon: Icons.home_outlined,
              tooltip: 'الرئيسية',
            ),
            _buildNavTabItem(
              index: 1,
              activeIcon: Icons.assignment_rounded,
              inactiveIcon: Icons.assignment_outlined,
              tooltip: 'الخطة العلاجية',
            ),
            _buildNavTabItem(
              index: 2,
              activeIcon: Icons.auto_awesome,
              inactiveIcon: Icons.auto_awesome_outlined,
              tooltip: 'المساعد الذكي',
            ),
            _buildNavTabItem(
              index: 3,
              activeIcon: Icons.ads_click,
              inactiveIcon: Icons.ads_click_outlined,
              tooltip: 'التمارين',
            ),
            _buildNavTabItem(
              index: 4,
              activeIcon: Icons.account_circle,
              inactiveIcon: Icons.account_circle_outlined,
              tooltip: 'الملف الشخصي',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTabItem({
    required int index,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required String tooltip,
  }) {
    final isSelected = _currentTabIndex == index;
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: () {
            setState(() {
              _currentTabIndex = index;
            });
          },
          borderRadius: BorderRadius.circular(16.r),
          child: Center(
            child: Icon(
              isSelected ? activeIcon : inactiveIcon,
              size: 26.r,
              color: isSelected
                  ? AppColors.primaryColor
                  : AppColors.primaryColor.withValues(alpha: 0.5),
            ),
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
              'جارٍ تحميل البيانات...',
              style: AppTextStyles.font400Regular.copyWith(
                fontSize: 13.sp,
                color: AppColors.secondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasNoActiveChild) {
      return _buildNoActiveChildState();
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
              onPressed: _loadHomeData,
              width: 140,
              height: 38,
            ),
          ],
        ),
      );
    }

    final childFullName = _child?.fullName.isNotEmpty == true
        ? _child!.fullName
        : 'البطل';
    final childName = childFullName.split(' ').first;

    return RefreshIndicator(
      onRefresh: _loadHomeData,
      color: AppColors.primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 12.h),

            // 1. Welcome Card from GitHub Design
            WelcomeCard(
              title: 'نتابع رحلة $childFullName معاً',
              descripion: 'كل يوم خطوة جديدة نحو تطور أفضل لمستقبله.',
              image: 'assets/images/firstBot.png',
            ),
            SizedBox(height: 16.h),

            // 2. Today's Exercises Card from GitHub Design
            HomeCard(
              icon: AppIcons.star,
              iconColor: const Color(0xff5BAC34),
              circleAvatarColor: const Color(0xffDFF3D2),
              title: 'تمرينات اليوم المخصصة',
              description:
                  'أنشطة وتمارين مختارة خصيصاً لـ $childName بناءً على خطة العلاج.',
              iconText: 'ابدأ الان',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PractiseScreen(
                      gender: _child?.gender,
                      avatarUrl: _child?.avatarUrl,
                    ),
                  ),
                );
              },
              lastWidget: Image.asset(
                'assets/images/toy.png',
                width: 65.w,
                height: 100.h,
              ),
            ),
            SizedBox(height: 16.h),

            // 3. Progress Overview Card with Circular Progress from GitHub Design
            HomeCard(
              icon: AppIcons.chartStroke,
              circleAvatarColor: AppColors.circleAvatarColor,
              iconColor: AppColors.primaryColor,
              title: 'نظرة على التقدم',
              description:
                  'تابعي أحدث نتائج $childName\nوتطوره في المهارات المختلفة.',
              iconText: 'عرض التقدم',
              onTap: _navigateToProgress,
              lastWidget: AnimatedGradientCircularProgress(
                percent: _calculateProgressPercent(),
                size: 60.r,
                strokeWidth: 10,
                labelBuilder: (animatedPercent) => Text(
                  '${animatedPercent.round()}%',
                  style: AppTextStyles.font600SimiBold.copyWith(
                    color: AppColors.primaryColor,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // 4. Smart Insights Card from GitHub Design
            HomeCard(
              icon: AppIcons.bulb,
              iconColor: AppColors.primaryColor,
              circleAvatarColor: AppColors.circleAvatarColor,
              title: 'رؤى ذكية',
              description:
                  'ملاحظات وتحليلات ذكية تساعدك على فهم احتياجات $childName بشكل أفضل.',
              iconText: 'عرض الرؤى',
              onTap: () {
                if (_activeChildId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TreatmentPlanScreen(
                        initialBaseline: _baseline,
                        initialActivities: _activities,
                      ),
                    ),
                  );
                } else {
                  _navigateToProgress();
                }
              },
              lastWidget: Image.asset(
                'assets/images/book.png',
                width: 65.w,
                height: 100.h,
              ),
            ),
            SizedBox(height: 24.h),

            // Baseline Assessment Summary Card (Real initial scores)
            _buildBaselineAssessmentCard(),
            SizedBox(height: 24.h),

            // Progress Shortcut Card
            _buildProgressShortcutCard(),
            SizedBox(height: 24.h),

            // Domain Category Shortcuts
            _buildDomainCategoriesSection(),
            SizedBox(height: 24.h),

            // AI Consultation Assistant Card
            _buildAiConsultationCard(),
            SizedBox(height: 24.h),

            // Featured Activities
            _buildActivitiesCatalogSection(),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildNoActiveChildState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.child_care_rounded,
              size: 64.r,
              color: AppColors.secondaryTextColor,
            ),
            SizedBox(height: 16.h),
            const CustomTitle(
              title: 'لم يتم تحديد طفل نشط بعد',
              fontSize: 20,
            ),
            SizedBox(height: 8.h),
            const Description(
              text:
                  'يرجى إعداد ملف الطفل للبدء في استخدام التطبيق والوصول للأنشطة والتقييمات.',
              fontSize: 13,
            ),
            SizedBox(height: 24.h),
            CustomElevatedButton(
              title: 'إعداد ملف الطفل',
              onPressed: () {
                Navigator.push(
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

  Widget _buildProgressShortcutCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xffE4D4FF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: _navigateToProgress,
          child: Padding(
            padding: EdgeInsets.all(14.r),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                CircleAvatar(
                  radius: 20.r,
                  backgroundColor: const Color(0xffF0E8FF),
                  child: Icon(
                    Icons.insights_rounded,
                    size: 20.r,
                    color: AppColors.secondaryTextColor,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: TextDirection.rtl,
                    children: [
                      Text(
                        'عرض التقدم وسجل الجلسات',
                        style: AppTextStyles.font600SimiBold.copyWith(
                          fontSize: 13.sp,
                          color: AppColors.primaryColor,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'متابعة أداء الطفل في التمارين وإحصائيات المهارات المكتسبة',
                        style: AppTextStyles.font400Regular.copyWith(
                          fontSize: 11.sp,
                          color: AppColors.secondaryColor,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14.r,
                  color: AppColors.secondaryTextColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBaselineAssessmentCard() {
    final baseline = _baseline;

    if (baseline == null) {
      return Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: const Color(0xffE4D4FF), width: 1.2),
        ),
        child: Column(
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 22.r,
                  color: AppColors.secondaryTextColor,
                ),
                SizedBox(width: 8.w),
                Text(
                  'التقييم الأولي لمستوى الأداء',
                  style: AppTextStyles.font600SimiBold.copyWith(
                    fontSize: 14.sp,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              'لم يتم إجراء التقييم المبدئي بعد. يساعد هذا التقييم في ضبط صعوبة التمارين الموصى بها.',
              style: AppTextStyles.font400Regular.copyWith(
                fontSize: 12.sp,
                color: AppColors.secondaryColor,
                height: 1.4,
              ),
              textDirection: TextDirection.rtl,
            ),
            SizedBox(height: 12.h),
            CustomElevatedButton(
              title: 'بدء التقييم الأولي',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AiAssessmentScreen(),
                  ),
                );
              },
              width: 160,
              height: 38,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xffE4D4FF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: TextDirection.rtl,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  textDirection: TextDirection.rtl,
                  children: [
                    Icon(
                      Icons.insights_rounded,
                      size: 20.r,
                      color: AppColors.secondaryTextColor,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'التقييم الأولي للأداء المبدئي',
                        style: AppTextStyles.font600SimiBold.copyWith(
                          fontSize: 14.sp,
                          color: AppColors.primaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xffF0E8FF),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '${baseline.overallScore.toStringAsFixed(1)}%',
                  style: AppTextStyles.font700Bold.copyWith(
                    fontSize: 13.sp,
                    color: AppColors.secondaryTextColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            'نتائج التقييم المبدئي المحسوبة لمستوى الطفل (تُستخدم لضبط صعوبة التمارين)',
            style: AppTextStyles.font400Regular.copyWith(
              fontSize: 11.sp,
              color: AppColors.secondaryColor,
            ),
            textDirection: TextDirection.rtl,
          ),
          SizedBox(height: 14.h),
          _buildScoreRow(
            label: 'المهارات الحركية',
            score: baseline.motorScore,
            icon: Icons.directions_run_rounded,
          ),
          SizedBox(height: 8.h),
          _buildScoreRow(
            label: 'مهارات التواصل',
            score: baseline.communicationScore,
            icon: Icons.record_voice_over_rounded,
          ),
          SizedBox(height: 8.h),
          _buildScoreRow(
            label: 'المهارات المعرفية والتركيز',
            score: baseline.cognitiveScore,
            icon: Icons.psychology_rounded,
          ),
          SizedBox(height: 8.h),
          _buildScoreRow(
            label: 'التفاعل الاجتماعي والتنظيم',
            score: baseline.emotionalScore,
            icon: Icons.favorite_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRow({
    required String label,
    required double score,
    required IconData icon,
  }) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Icon(icon, size: 16.r, color: AppColors.primaryColor),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.font400Regular.copyWith(
              fontSize: 12.sp,
              color: AppColors.primaryColor,
            ),
            textDirection: TextDirection.rtl,
          ),
        ),
        SizedBox(
          width: 80.w,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: (score / 100.0).clamp(0.0, 1.0),
              minHeight: 6.h,
              backgroundColor: const Color(0xffF0E8FF),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.secondaryTextColor,
              ),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          '${score.toStringAsFixed(0)}%',
          style: AppTextStyles.font600SimiBold.copyWith(
            fontSize: 11.sp,
            color: AppColors.secondaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDomainCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      textDirection: TextDirection.rtl,
      children: [
        Text(
          'مجالات الأنشطة',
          style: AppTextStyles.font600SimiBold.copyWith(
            fontSize: 15.sp,
            color: AppColors.primaryColor,
          ),
          textDirection: TextDirection.rtl,
        ),
        SizedBox(height: 12.h),
        Row(
          children: ActivityDomainEnum.values.map((domain) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: _buildCategoryCard(
                  title: domain.arabicLabel,
                  icon: domain.icon,
                  onTap: () => _navigateToActivitiesCatalog(
                    domainFilter: domain.backendValue,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xffE4D4FF), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 20.r,
              backgroundColor: const Color(0xffF0E8FF),
              child: Icon(
                icon,
                size: 20.r,
                color: AppColors.primaryColor,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              title,
              style: AppTextStyles.font500Medium.copyWith(
                fontSize: 11.sp,
                color: AppColors.primaryColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiConsultationCard() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primaryColor,
            AppColors.secondaryTextColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'استشارة المساعد الذكي Mindora AI',
                  style: AppTextStyles.font600SimiBold.copyWith(
                    fontSize: 13.5.sp,
                    color: Colors.white,
                    fontFamily: 'Readex Pro',
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'استشر الذكاء الاصطناعي حول تمارين وتأهيل طفلك مباشرة.',
                  style: AppTextStyles.font400Regular.copyWith(
                    fontSize: 11.5.sp,
                    color: Colors.white.withOpacity(0.85),
                    fontFamily: 'Readex Pro',
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AiChatScreen(),
                ),
              );
            },
            child: Text(
              'تحدث الآن',
              style: AppTextStyles.font600SimiBold.copyWith(
                fontSize: 11.sp,
                color: AppColors.primaryColor,
                fontFamily: 'Readex Pro',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesCatalogSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      textDirection: TextDirection.rtl,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          textDirection: TextDirection.rtl,
          children: [
            Text(
              'الأنشطة المتاحة',
              style: AppTextStyles.font600SimiBold.copyWith(
                fontSize: 15.sp,
                color: AppColors.primaryColor,
              ),
            ),
            GestureDetector(
              onTap: () => _navigateToActivitiesCatalog(),
              child: Text(
                'عرض الكل',
                style: AppTextStyles.font600SimiBold.copyWith(
                  fontSize: 12.sp,
                  color: AppColors.secondaryTextColor,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        if (_activities.isEmpty)
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xffE4D4FF), width: 1),
            ),
            child: Center(
              child: Text(
                'لا توجد أنشطة متوفرة في النظام حاليًا',
                style: AppTextStyles.font400Regular.copyWith(
                  fontSize: 13.sp,
                  color: AppColors.secondaryColor,
                ),
              ),
            ),
          )
        else
          Column(
            children: _activities.take(3).map((act) {
              return Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: _buildHomeActivityCard(act),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildHomeActivityCard(ActivityModel activity) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xffE4D4FF), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: () {
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
            padding: EdgeInsets.all(12.r),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                CircleAvatar(
                  radius: 20.r,
                  backgroundColor: AppColors.circleAvatarColor,
                  child: Icon(
                    activity.domainIcon,
                    size: 20.r,
                    color: AppColors.primaryColor,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: TextDirection.rtl,
                    children: [
                      Text(
                        activity.title,
                        style: AppTextStyles.font600SimiBold.copyWith(
                          fontSize: 13.sp,
                          color: AppColors.primaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.rtl,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '${activity.domainArabicLabel} • ${activity.difficultyArabicLabel}',
                        style: AppTextStyles.font400Regular.copyWith(
                          fontSize: 11.sp,
                          color: AppColors.secondaryColor,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14.r,
                  color: AppColors.secondaryTextColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
