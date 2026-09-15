import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_text_styles.dart';
import 'package:sawa/constants.dart';
import 'package:sawa/core/errors/api_exception.dart';
import 'package:sawa/core/models/child_model.dart';
import 'package:sawa/core/models/progress_models.dart';
import 'package:sawa/core/services/children_service.dart';
import 'package:sawa/core/services/progress_service.dart';
import 'package:sawa/screens/child_information_first_screen.dart';
import 'package:sawa/widgets/back_icon.dart';
import 'package:sawa/widgets/custom_app_bar.dart';
import 'package:sawa/widgets/custom_elevated_button.dart';
import 'package:sawa/widgets/custom_padding.dart';
import 'package:sawa/widgets/custom_title.dart';
import 'package:sawa/widgets/description.dart';

class ProgressScreen extends StatefulWidget {
  final bool showBackButton;
  final ChildModel? initialChild;
  final ChildProgressSummaryModel? initialSummary;

  const ProgressScreen({
    super.key,
    this.showBackButton = false,
    this.initialChild,
    this.initialSummary,
  });

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final ProgressService _progressService = ProgressService();
  final ChildrenService _childrenService = ChildrenService();

  String? _activeChildId;
  ChildModel? _child;

  // Overview Summary State
  ChildProgressSummaryModel? _summary;
  bool _isLoadingSummary = false;
  String? _summaryError;

  // History State & Pagination
  List<SessionHistoryPointModel> _history = [];
  int _historyPage = 1;
  static const int _historyPageSize = 20;
  bool _hasMoreHistory = true;
  bool _isLoadingHistory = false;
  bool _isLoadingMoreHistory = false;
  String? _historyError;
  String? _historyMoreError;
  String? _selectedDomainFilter; // null = الكل

  // Activity Performance State
  List<ActivityPerformanceModel> _performances = [];
  bool _isLoadingPerformance = false;
  String? _performanceError;

  // General State
  bool _isInitialLoading = true;
  bool _hasNoActiveChild = false;
  String? _generalError;

  @override
  void initState() {
    super.initState();
    if (widget.initialChild != null) {
      _child = widget.initialChild;
      _activeChildId = widget.initialChild!.id;
      _summary = widget.initialSummary;
      _isInitialLoading = false;
    } else {
      _loadInitialData();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isInitialLoading = true;
      _hasNoActiveChild = false;
      _generalError = null;
    });

    try {
      final childId = await _progressService.getActiveChildId();
      if (childId == null || childId.trim().isEmpty) {
        if (mounted) {
          setState(() {
            _hasNoActiveChild = true;
            _isInitialLoading = false;
          });
        }
        return;
      }

      _activeChildId = childId.trim();

      // Fetch Child profile for name display
      try {
        _child = await _childrenService.getChildById(_activeChildId!);
      } catch (_) {
        // Non-blocking if child details fail, continue with progress
      }

      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }

      // Fetch data sections in parallel with independent error isolation
      await Future.wait([
        _fetchSummary(),
        _fetchHistoryPage(page: 1, reset: true),
        _fetchPerformance(),
      ]);
    } catch (e) {
      if (mounted) {
        setState(() {
          _generalError = 'تعذر الاتصال بالخادم لتحميل سجل التقدم.';
          _isInitialLoading = false;
        });
      }
    }
  }

  Future<void> _fetchSummary() async {
    if (_activeChildId == null) return;
    setState(() {
      _isLoadingSummary = true;
      _summaryError = null;
    });

    try {
      final summary = await _progressService.getChildProgress(_activeChildId!);
      if (mounted) {
        setState(() {
          _summary = summary;
          _isLoadingSummary = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _summaryError = e.firstErrorMessage;
          _isLoadingSummary = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _summaryError = 'تعذر تحميل ملخص التقدم العام.';
          _isLoadingSummary = false;
        });
      }
    }
  }

  Future<void> _fetchHistoryPage({required int page, bool reset = false}) async {
    if (_activeChildId == null) return;

    setState(() {
      _isLoadingHistory = true;
      _historyError = null;
      _historyMoreError = null;
    });

    try {
      final points = await _progressService.getProgressHistory(
        _activeChildId!,
        domain: _selectedDomainFilter,
        page: page,
        pageSize: _historyPageSize,
      );

      if (mounted) {
        setState(() {
          if (reset) {
            _history = points;
          } else {
            _history.addAll(points);
          }
          _historyPage = page;
          _hasMoreHistory = points.length >= _historyPageSize;
          _isLoadingHistory = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _historyError = e.firstErrorMessage;
          _isLoadingHistory = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _historyError = 'تعذر تحميل سجل الجلسات السابقة.';
          _isLoadingHistory = false;
        });
      }
    }
  }

  Future<void> _loadMoreHistory() async {
    if (_isLoadingMoreHistory || !_hasMoreHistory || _activeChildId == null) {
      return;
    }

    final nextPage = _historyPage + 1;
    setState(() {
      _isLoadingMoreHistory = true;
      _historyMoreError = null;
    });

    try {
      final points = await _progressService.getProgressHistory(
        _activeChildId!,
        domain: _selectedDomainFilter,
        page: nextPage,
        pageSize: _historyPageSize,
      );

      if (mounted) {
        setState(() {
          _history.addAll(points);
          _historyPage = nextPage;
          _hasMoreHistory = points.length >= _historyPageSize;
          _isLoadingMoreHistory = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _historyMoreError = e.firstErrorMessage;
          _isLoadingMoreHistory = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _historyMoreError = 'تعذر تحميل المزيد من الجلسات.';
          _isLoadingMoreHistory = false;
        });
      }
    }
  }

  Future<void> _fetchPerformance() async {
    if (_activeChildId == null) return;
    setState(() {
      _isLoadingPerformance = true;
      _performanceError = null;
    });

    try {
      final perfs =
          await _progressService.getActivityPerformance(_activeChildId!);
      if (mounted) {
        setState(() {
          _performances = perfs;
          _isLoadingPerformance = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _performanceError = e.firstErrorMessage;
          _isLoadingPerformance = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _performanceError = 'تعذر تحميل إحصائيات أداء الأنشطة.';
          _isLoadingPerformance = false;
        });
      }
    }
  }

  void _onDomainFilterSelected(String? domain) {
    if (_selectedDomainFilter == domain) return;
    setState(() {
      _selectedDomainFilter = domain;
      _historyPage = 1;
      _hasMoreHistory = true;
    });
    _fetchHistoryPage(page: 1, reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: CustomAppBar(
        leading: widget.showBackButton ? const BackIcon() : const SizedBox.shrink(),
        title: Text(
          'التقدم وسجل الجلسات',
          style: AppTextStyles.font600SimiBold.copyWith(
            fontSize: 16.sp,
            color: AppColors.primaryColor,
          ),
        ),
      ),
      body: SafeArea(
        child: CustomPadding(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isInitialLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
            SizedBox(height: 16.h),
            Text(
              'جارٍ تحميل بيانات التقدم...',
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

    if (_generalError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48.r, color: Colors.red.shade400),
            SizedBox(height: 12.h),
            Text(
              _generalError!,
              textAlign: TextAlign.center,
              style: AppTextStyles.font500Medium.copyWith(
                fontSize: 13.sp,
                color: AppColors.primaryColor,
              ),
            ),
            SizedBox(height: 16.h),
            CustomElevatedButton(
              title: 'إعادة المحاولة',
              onPressed: _loadInitialData,
              width: 140,
              height: 38,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => Future.wait([
        _fetchSummary(),
        _fetchHistoryPage(page: 1, reset: true),
        _fetchPerformance(),
      ]),
      color: AppColors.primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 10.h),

            // Child greeting header
            _buildChildHeader(),
            SizedBox(height: 18.h),

            // Section 1: Overview Summary Cards
            _buildOverviewSummarySection(),
            SizedBox(height: 22.h),

            // Section 2: Domain Progress Breakdown
            _buildDomainProgressSection(),
            SizedBox(height: 22.h),

            // Section 3: Performance Trend Visualization
            _buildTrendVisualizationSection(),
            SizedBox(height: 22.h),

            // Section 4: Session History with Pagination & Domain Filtering
            _buildSessionHistorySection(),
            SizedBox(height: 22.h),

            // Section 5: Activity Performance Metrics
            _buildActivityPerformanceSection(),
            SizedBox(height: 26.h),
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
              Icons.insights_rounded,
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
                  'يرجى إعداد ملف الطفل للبدء في استعراض تقدمه ومتابعة مؤشرات أدائه التدريبي.',
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

  Widget _buildChildHeader() {
    final childName = _child?.fullName.isNotEmpty == true
        ? _child!.fullName
        : 'بطلنا الصغير';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
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
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          CircleAvatar(
            radius: 22.r,
            backgroundColor: const Color(0xffF0E8FF),
            child: Icon(
              Icons.trending_up_rounded,
              size: 24.r,
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
                  'التقدم لطفلنا: $childName',
                  style: AppTextStyles.font700Bold.copyWith(
                    fontSize: 15.sp,
                    color: AppColors.primaryColor,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                SizedBox(height: 2.h),
                Text(
                  'متابعة أداء الجلسات والتطور المهاري وفق التقييم الفعلي',
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
      ),
    );
  }

  // ============================================================
  // SECTION 1: OVERVIEW SUMMARY
  // ============================================================

  Widget _buildOverviewSummarySection() {
    if (_isLoadingSummary) {
      return Container(
        height: 120.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xffE4D4FF), width: 1),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
          ),
        ),
      );
    }

    if (_summaryError != null) {
      return Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.red.shade200, width: 1),
        ),
        child: Column(
          children: [
            Text(
              _summaryError!,
              style: AppTextStyles.font500Medium.copyWith(
                fontSize: 12.sp,
                color: Colors.red.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            CustomElevatedButton(
              title: 'إعادة المحاولة',
              onPressed: _fetchSummary,
              width: 120,
              height: 32,
            ),
          ],
        ),
      );
    }

    final summary = _summary;
    if (summary == null) {
      return const SizedBox.shrink();
    }

    final trend = summary.trendEnum;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      textDirection: TextDirection.rtl,
      children: [
        Text(
          'نظرة عامة على التقدم',
          style: AppTextStyles.font600SimiBold.copyWith(
            fontSize: 15.sp,
            color: AppColors.primaryColor,
          ),
          textDirection: TextDirection.rtl,
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'الجلسات المكتملة',
                value: '${summary.totalCompletedSessions}',
                subtitle: 'جلسة تدريبية',
                icon: Icons.check_circle_outline_rounded,
                iconColor: const Color(0xff2E7D32),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildMetricTile(
                title: 'وقت التدريب',
                value: ProgressFormatters.formatPracticeMinutes(
                    summary.totalPracticeMinutes),
                subtitle: 'إجمالي الوقت',
                icon: Icons.timer_outlined,
                iconColor: AppColors.secondaryTextColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'متوسط الأداء العام',
                value: '${summary.overallAverageScore.toStringAsFixed(1)}%',
                subtitle: 'مستوى الإنجاز',
                icon: Icons.grade_rounded,
                iconColor: const Color(0xffF57C00),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildMetricTile(
                title: 'أيام الاستمرار',
                value: '${summary.currentStreakDays} يوم',
                subtitle: 'تتابع الجلسات',
                icon: Icons.local_fire_department_rounded,
                iconColor: const Color(0xffD32F2F),
              ),
            ),
          ],
        ),
        if (trend != null) ...[
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: trend.bgColor,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: trend.color.withValues(alpha: 0.3)),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(trend.icon, size: 20.r, color: trend.color),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: TextDirection.rtl,
                    children: [
                      Text(
                        'الاتجاه العام للأداء: ${trend.arabicLabel}',
                        style: AppTextStyles.font600SimiBold.copyWith(
                          fontSize: 12.sp,
                          color: trend.color,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      Text(
                        'مبني على تحليل الجلسات التدريبية المكتملة الفترات الأخيرة',
                        style: AppTextStyles.font400Regular.copyWith(
                          fontSize: 10.sp,
                          color: trend.color.withValues(alpha: 0.9),
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xffE4D4FF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
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
                child: Text(
                  title,
                  style: AppTextStyles.font400Regular.copyWith(
                    fontSize: 11.sp,
                    color: AppColors.secondaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 4.w),
              Icon(icon, size: 18.r, color: iconColor),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            value,
            style: AppTextStyles.font700Bold.copyWith(
              fontSize: 15.sp,
              color: AppColors.primaryColor,
            ),
            textDirection: TextDirection.rtl,
          ),
          SizedBox(height: 2.h),
          Text(
            subtitle,
            style: AppTextStyles.font400Regular.copyWith(
              fontSize: 10.sp,
              color: AppColors.secondaryColor.withValues(alpha: 0.8),
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION 2: DOMAIN PROGRESS
  // ============================================================

  Widget _buildDomainProgressSection() {
    final summaries = _summary?.domainSummaries ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      textDirection: TextDirection.rtl,
      children: [
        Text(
          'التقدم حسب مجالات المهارات',
          style: AppTextStyles.font600SimiBold.copyWith(
            fontSize: 15.sp,
            color: AppColors.primaryColor,
          ),
          textDirection: TextDirection.rtl,
        ),
        SizedBox(height: 10.h),
        if (summaries.isEmpty)
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: const Color(0xffE4D4FF), width: 1),
            ),
            child: Center(
              child: Text(
                'لا توجد جلسات مكتملة كافية بعد لعرض تفاصيل المجالات.',
                style: AppTextStyles.font400Regular.copyWith(
                  fontSize: 12.sp,
                  color: AppColors.secondaryColor,
                ),
              ),
            ),
          )
        else
          Column(
            children: summaries.map((domain) {
              final trend = domain.trendEnum;
              return Container(
                margin: EdgeInsets.only(bottom: 10.h),
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: const Color(0xffE4D4FF), width: 1.2),
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
                            textDirection: TextDirection.rtl,
                            children: [
                              CircleAvatar(
                                radius: 16.r,
                                backgroundColor: const Color(0xffF0E8FF),
                                child: Icon(
                                  domain.domainIcon,
                                  size: 16.r,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  domain.domainArabicLabel,
                                  style: AppTextStyles.font600SimiBold.copyWith(
                                    fontSize: 13.sp,
                                    color: AppColors.primaryColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        if (trend != null)
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: trend.bgColor,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(trend.icon, size: 12.r, color: trend.color),
                                SizedBox(width: 4.w),
                                Text(
                                  trend.arabicLabel,
                                  style: AppTextStyles.font600SimiBold.copyWith(
                                    fontSize: 10.sp,
                                    color: trend.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      textDirection: TextDirection.rtl,
                      children: [
                        _buildSubStat(
                          label: 'الجلسات',
                          value: '${domain.completedSessions}',
                        ),
                        _buildSubStat(
                          label: 'متوسط الأداء',
                          value: '${domain.averageScore.toStringAsFixed(1)}%',
                        ),
                        _buildSubStat(
                          label: 'آخر نتيجة',
                          value: '${domain.latestScore.toStringAsFixed(1)}%',
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3.r),
                      child: LinearProgressIndicator(
                        value: (domain.averageScore / 100.0).clamp(0.0, 1.0),
                        minHeight: 6.h,
                        backgroundColor: const Color(0xffF0E8FF),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.secondaryTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildSubStat({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      textDirection: TextDirection.rtl,
      children: [
        Text(
          label,
          style: AppTextStyles.font400Regular.copyWith(
            fontSize: 10.sp,
            color: AppColors.secondaryColor,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: AppTextStyles.font600SimiBold.copyWith(
            fontSize: 12.sp,
            color: AppColors.primaryColor,
          ),
          textDirection: TextDirection.rtl,
        ),
      ],
    );
  }

  // ============================================================
  // SECTION 3: TREND VISUALIZATION
  // ============================================================

  Widget _buildTrendVisualizationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      textDirection: TextDirection.rtl,
      children: [
        Text(
          'مخطط تطور الأداء الزمني',
          style: AppTextStyles.font600SimiBold.copyWith(
            fontSize: 15.sp,
            color: AppColors.primaryColor,
          ),
          textDirection: TextDirection.rtl,
        ),
        SizedBox(height: 10.h),
        Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xffE4D4FF), width: 1.2),
          ),
          child: _history.length < 2
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    child: Column(
                      children: [
                        Icon(
                          Icons.show_chart_rounded,
                          size: 32.r,
                          color: AppColors.secondaryColor.withValues(alpha: 0.5),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'لا توجد بيانات كافية لعرض الاتجاه (يلزم إكمال جلستين على الأقل)',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.font400Regular.copyWith(
                            fontSize: 12.sp,
                            color: AppColors.secondaryColor,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),
                  ),
                )
              : _buildHistorySparkline(),
        ),
      ],
    );
  }

  Widget _buildHistorySparkline() {
    // Chronological order (oldest to newest for visual timeline)
    final points = List<SessionHistoryPointModel>.from(_history)
      ..sort((a, b) => a.completedAtUtc.compareTo(b.completedAtUtc));

    // Show up to the latest 8 sessions for readability
    final displayPoints = points.length > 8
        ? points.sublist(points.length - 8)
        : points;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          textDirection: TextDirection.rtl,
          children: [
            Text(
              'تتابع درجات آخر ${displayPoints.length} جلسات',
              style: AppTextStyles.font500Medium.copyWith(
                fontSize: 12.sp,
                color: AppColors.primaryColor,
              ),
              textDirection: TextDirection.rtl,
            ),
            Text(
              'من الأقدم إلى الأحدث ⬅️',
              style: AppTextStyles.font400Regular.copyWith(
                fontSize: 10.sp,
                color: AppColors.secondaryColor,
              ),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
        SizedBox(height: 16.h),
        SizedBox(
          height: 90.h,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: displayPoints.map((pt) {
              final heightFactor = (pt.score / 100.0).clamp(0.1, 1.0);
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${pt.score.toStringAsFixed(0)}%',
                    style: AppTextStyles.font600SimiBold.copyWith(
                      fontSize: 9.sp,
                      color: AppColors.secondaryTextColor,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Container(
                    width: 22.w,
                    height: 56.h * heightFactor,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryTextColor,
                      borderRadius: BorderRadius.circular(5.r),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${pt.completedAtUtc.toLocal().month}/${pt.completedAtUtc.toLocal().day}',
                    style: AppTextStyles.font400Regular.copyWith(
                      fontSize: 8.sp,
                      color: AppColors.secondaryColor,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SECTION 4: SESSION HISTORY WITH PAGINATION & FILTERING
  // ============================================================

  Widget _buildSessionHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      textDirection: TextDirection.rtl,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          textDirection: TextDirection.rtl,
          children: [
            Text(
              'سجل الجلسات',
              style: AppTextStyles.font600SimiBold.copyWith(
                fontSize: 15.sp,
                color: AppColors.primaryColor,
              ),
              textDirection: TextDirection.rtl,
            ),
            if (_history.isNotEmpty)
              Text(
                'عرض ${_history.length} جلسة',
                style: AppTextStyles.font400Regular.copyWith(
                  fontSize: 11.sp,
                  color: AppColors.secondaryColor,
                ),
                textDirection: TextDirection.rtl,
              ),
          ],
        ),
        SizedBox(height: 10.h),

        // Domain Filter Chips
        _buildDomainFilterChips(),
        SizedBox(height: 12.h),

        if (_isLoadingHistory)
          Container(
            height: 120.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xffE4D4FF), width: 1),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              ),
            ),
          )
        else if (_historyError != null)
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.red.shade200, width: 1),
            ),
            child: Column(
              children: [
                Text(
                  _historyError!,
                  style: AppTextStyles.font500Medium.copyWith(
                    fontSize: 12.sp,
                    color: Colors.red.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                CustomElevatedButton(
                  title: 'إعادة المحاولة',
                  onPressed: () => _fetchHistoryPage(page: 1, reset: true),
                  width: 120,
                  height: 32,
                ),
              ],
            ),
          )
        else if (_history.isEmpty)
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xffE4D4FF), width: 1),
            ),
            child: Center(
              child: Text(
                'لا توجد جلسات مسجلة في هذا التصنيف بعد.',
                style: AppTextStyles.font400Regular.copyWith(
                  fontSize: 12.sp,
                  color: AppColors.secondaryColor,
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
          )
        else
          Column(
            children: [
              ..._buildSortedDisplayHistory().map((point) {
                return _buildHistoryCard(point);
              }),
              SizedBox(height: 8.h),
              _buildPaginationControls(),
            ],
          ),
      ],
    );
  }

  List<SessionHistoryPointModel> _buildSortedDisplayHistory() {
    // Presenting newest sessions first within loaded pages for intuitive viewing
    final sorted = List<SessionHistoryPointModel>.from(_history)
      ..sort((a, b) => b.completedAtUtc.compareTo(a.completedAtUtc));
    return sorted;
  }

  Widget _buildDomainFilterChips() {
    final filters = [
      {'label': 'الكل', 'value': null},
      {'label': 'حركي', 'value': 'Movement'},
      {'label': 'لغوي ونطق', 'value': 'Speech'},
      {'label': 'انتباه وتركيز', 'value': 'Attention'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      physics: const BouncingScrollPhysics(),
      child: Row(
        textDirection: TextDirection.rtl,
        children: filters.map((f) {
          final isSelected = _selectedDomainFilter == f['value'];
          return Padding(
            padding: EdgeInsets.only(left: 8.w),
            child: ChoiceChip(
              label: Text(
                f['label'] as String,
                style: AppTextStyles.font500Medium.copyWith(
                  fontSize: 11.sp,
                  color: isSelected ? Colors.white : AppColors.primaryColor,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primaryColor,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isSelected
                    ? AppColors.primaryColor
                    : const Color(0xffE4D4FF),
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              onSelected: (_) => _onDomainFilterSelected(f['value']),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHistoryCard(SessionHistoryPointModel point) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xffE4D4FF), width: 1),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          CircleAvatar(
            radius: 20.r,
            backgroundColor: const Color(0xffF0E8FF),
            child: Icon(
              point.domainIcon,
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
                  point.activityTitle,
                  style: AppTextStyles.font600SimiBold.copyWith(
                    fontSize: 13.sp,
                    color: AppColors.primaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.rtl,
                ),
                SizedBox(height: 4.h),
                Wrap(
                  spacing: 6.w,
                  runSpacing: 4.h,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  textDirection: TextDirection.rtl,
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: const Color(0xffF0E8FF),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        point.domainArabicLabel,
                        style: AppTextStyles.font500Medium.copyWith(
                          fontSize: 10.sp,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                    Text(
                      ProgressFormatters.formatDurationSeconds(
                          point.durationSeconds),
                      style: AppTextStyles.font400Regular.copyWith(
                        fontSize: 10.sp,
                        color: AppColors.secondaryColor,
                      ),
                    ),
                    Text(
                      '• ${ProgressFormatters.formatCompletedDate(point.completedAtUtc)}',
                      style: AppTextStyles.font400Regular.copyWith(
                        fontSize: 10.sp,
                        color: AppColors.secondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xffE8F5E9),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: const Color(0xff81C784), width: 0.8),
            ),
            child: Text(
              '${point.score.toStringAsFixed(0)}%',
              style: AppTextStyles.font700Bold.copyWith(
                fontSize: 12.sp,
                color: const Color(0xff2E7D32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    if (_isLoadingMoreHistory) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
          ),
        ),
      );
    }

    if (_historyMoreError != null) {
      return Center(
        child: Column(
          children: [
            Text(
              _historyMoreError!,
              style: AppTextStyles.font400Regular.copyWith(
                fontSize: 11.sp,
                color: Colors.red.shade700,
              ),
            ),
            SizedBox(height: 6.h),
            TextButton(
              onPressed: _loadMoreHistory,
              child: Text(
                'إعادة محاولة التحميل',
                style: AppTextStyles.font600SimiBold.copyWith(
                  fontSize: 12.sp,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_hasMoreHistory) {
      return Center(
        child: OutlinedButton(
          onPressed: _loadMoreHistory,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryColor,
            side: const BorderSide(color: Color(0xffE4D4FF)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          ),
          child: Text(
            'تحميل المزيد من الجلسات',
            style: AppTextStyles.font500Medium.copyWith(
              fontSize: 12.sp,
              color: AppColors.primaryColor,
            ),
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Text(
          'تم عرض جميع الجلسات المسجلة',
          style: AppTextStyles.font400Regular.copyWith(
            fontSize: 11.sp,
            color: AppColors.secondaryColor,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION 5: ACTIVITY PERFORMANCE
  // ============================================================

  Widget _buildActivityPerformanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      textDirection: TextDirection.rtl,
      children: [
        Text(
          'إحصائيات أداء الأنشطة',
          style: AppTextStyles.font600SimiBold.copyWith(
            fontSize: 15.sp,
            color: AppColors.primaryColor,
          ),
          textDirection: TextDirection.rtl,
        ),
        SizedBox(height: 10.h),
        if (_isLoadingPerformance)
          Container(
            height: 120.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xffE4D4FF), width: 1),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              ),
            ),
          )
        else if (_performanceError != null)
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.red.shade200, width: 1),
            ),
            child: Column(
              children: [
                Text(
                  _performanceError!,
                  style: AppTextStyles.font500Medium.copyWith(
                    fontSize: 12.sp,
                    color: Colors.red.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                CustomElevatedButton(
                  title: 'إعادة المحاولة',
                  onPressed: _fetchPerformance,
                  width: 120,
                  height: 32,
                ),
              ],
            ),
          )
        else if (_performances.isEmpty)
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: const Color(0xffE4D4FF), width: 1),
            ),
            child: Center(
              child: Text(
                'لم يتم تسجيل أداء تفصيلي للأنشطة بعد.',
                style: AppTextStyles.font400Regular.copyWith(
                  fontSize: 12.sp,
                  color: AppColors.secondaryColor,
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
          )
        else
          Column(
            children: _performances.map((perf) {
              return Container(
                margin: EdgeInsets.only(bottom: 10.h),
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: const Color(0xffE4D4FF), width: 1.2),
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
                          child: Text(
                            perf.activityTitle,
                            style: AppTextStyles.font600SimiBold.copyWith(
                              fontSize: 13.sp,
                              color: AppColors.primaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: const Color(0xffF0E8FF),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            '${perf.domainArabicLabel} • ${perf.difficultyArabicLabel}',
                            style: AppTextStyles.font500Medium.copyWith(
                              fontSize: 10.sp,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      textDirection: TextDirection.rtl,
                      children: [
                        _buildSubStat(
                          label: 'مرات اللعب',
                          value: '${perf.timesPlayed} مرة',
                        ),
                        _buildSubStat(
                          label: 'متوسط الأداء',
                          value: '${perf.averageScore.toStringAsFixed(1)}%',
                        ),
                        _buildSubStat(
                          label: 'أفضل نتيجة',
                          value: '${perf.bestScore.toStringAsFixed(1)}%',
                        ),
                        _buildSubStat(
                          label: 'آخر نتيجة',
                          value: '${perf.latestScore.toStringAsFixed(1)}%',
                        ),
                      ],
                    ),
                    if (perf.averageAccuracyPercentage != null ||
                        perf.averageReactionTimeMs != null ||
                        perf.averageRepetitions != null) ...[
                      SizedBox(height: 8.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 4.h,
                        textDirection: TextDirection.rtl,
                        children: [
                          if (perf.averageAccuracyPercentage != null)
                            _buildTelemetryTag(
                              'الدقة: ${perf.averageAccuracyPercentage!.toStringAsFixed(1)}%',
                            ),
                          if (perf.averageReactionTimeMs != null)
                            _buildTelemetryTag(
                              'زمن الاستجابة: ${perf.averageReactionTimeMs!.toStringAsFixed(0)} مللي ثانية',
                            ),
                          if (perf.averageRepetitions != null)
                            _buildTelemetryTag(
                              'التكرارات: ${perf.averageRepetitions!.toStringAsFixed(1)}',
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildTelemetryTag(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: const Color(0xffF8F6FF),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: const Color(0xffE4D4FF), width: 0.8),
      ),
      child: Text(
        label,
        style: AppTextStyles.font400Regular.copyWith(
          fontSize: 10.sp,
          color: AppColors.secondaryColor,
        ),
      ),
    );
  }
}
