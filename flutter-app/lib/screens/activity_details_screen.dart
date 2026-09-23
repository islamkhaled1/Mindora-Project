import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_text_styles.dart';
import 'package:sawa/constants.dart';
import 'package:sawa/core/errors/api_exception.dart';
import 'package:sawa/core/models/activity_models.dart';
import 'package:sawa/core/services/activity_service.dart';
import 'package:sawa/core/services/children_service.dart';
import 'package:sawa/core/models/session_models.dart';
import 'package:sawa/core/services/session_service.dart';
import 'package:sawa/core/storage/secure_storage_service.dart';
import 'package:sawa/screens/practise_instruction_attention.dart';
import 'package:sawa/screens/session_execution_screen.dart';
import 'package:sawa/widgets/back_icon.dart';
import 'package:sawa/widgets/custom_app_bar.dart';
import 'package:sawa/widgets/custom_elevated_button.dart';
import 'package:sawa/widgets/custom_padding.dart';
import 'package:sawa/widgets/custom_title.dart';

class ActivityDetailsScreen extends StatefulWidget {
  final String activityId;
  final ActivityModel? initialActivity;

  const ActivityDetailsScreen({
    super.key,
    required this.activityId,
    this.initialActivity,
  });

  @override
  State<ActivityDetailsScreen> createState() => _ActivityDetailsScreenState();
}

class _ActivityDetailsScreenState extends State<ActivityDetailsScreen> {
  final ActivityService _activityService = ActivityService();
  final SessionService _sessionService = SessionService();
  final ChildrenService _childrenService = ChildrenService();
  final SecureStorageService _storage = SecureStorageService();
  ActivityModel? _activity;
  bool _isLoading = false;
  bool _isStartingSession = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _activity = widget.initialActivity;
    if (_activity == null) {
      _fetchActivity();
    }
  }

  Future<void> _fetchActivity() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final activity =
          await _activityService.getActivityById(widget.activityId);
      if (mounted) {
        setState(() {
          _activity = activity;
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
          _errorMessage = 'تعذر تحميل تفاصيل النشاط. يرجى التحقق من الاتصال بالإنترنت.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startSession() async {
    if (_isStartingSession) return;

    final isSpeech = widget.initialActivity?.domainEnum == ActivityDomainEnum.speech ||
        _activity?.domainEnum == ActivityDomainEnum.speech ||
        (_activity?.domain.toLowerCase() == 'speech');
    if (isSpeech) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تدريب النطق غير متاح حاليًا.')),
      );
      return;
    }

    setState(() => _isStartingSession = true);

    try {
      int? focusDurationMinutes;
      var activeChildId = await _storage.getActiveChildId();
      if (activeChildId == null || activeChildId.trim().isEmpty) {
        final children = await _childrenService.getChildren();
        if (children.isNotEmpty) {
          activeChildId = children.first.id;
          focusDurationMinutes = children.first.focusDurationMinutes;
          await _storage.saveActiveChildId(activeChildId);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('لم يتم تحديد طفل نشط بعد. يرجى إعداد أو اختيار طفل أولاً.'),
                backgroundColor: AppColors.primaryColor,
              ),
            );
            setState(() => _isStartingSession = false);
          }
          return;
        }
      } else {
        try {
          final child = await _childrenService.getChildById(activeChildId.trim());
          focusDurationMinutes = child.focusDurationMinutes;
        } catch (_) {}
      }

      SessionModel session;
      try {
        session = await _sessionService.startSession(
          StartSessionRequest(
            childId: activeChildId.trim(),
            activityId: widget.activityId,
          ),
        );
      } on ApiException catch (e) {
        if (e.statusCode == 404 ||
            e.message.contains('not found') ||
            e.firstErrorMessage.contains('not found')) {
          final children = await _childrenService.getChildren();
          if (children.isNotEmpty) {
            activeChildId = children.first.id;
            focusDurationMinutes = children.first.focusDurationMinutes;
            await _storage.saveActiveChildId(activeChildId);
            session = await _sessionService.startSession(
              StartSessionRequest(
                childId: activeChildId.trim(),
                activityId: widget.activityId,
              ),
            );
          } else {
            rethrow;
          }
        } else {
          rethrow;
        }
      }

      if (mounted) {
        setState(() => _isStartingSession = false);
        final isAttention = session.domain.toLowerCase() == 'attention' ||
            widget.initialActivity?.domainEnum == ActivityDomainEnum.attention ||
            _activity?.domainEnum == ActivityDomainEnum.attention;

        if (isAttention) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PractiseInstructionAttention(),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SessionExecutionScreen(
                session: session,
                focusDurationMinutes: focusDurationMinutes,
                activity: _activity ?? widget.initialActivity ?? ActivityModel(
                  id: widget.activityId,
                  title: 'النشاط التدريبي',
                  description: '',
                  domain: session.domain,
                  baseDifficulty: session.targetDifficulty ?? 'Beginner',
                ),
              ),
            ),
          );
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _isStartingSession = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.firstErrorMessage),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isStartingSession = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر بدء الجلسة التدريبية، يرجى المحاولة مرة أخرى'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: const CustomAppBar(leading: BackIcon()),
      body: CustomPadding(
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
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
              'جارٍ تحميل تفاصيل النشاط...',
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
              onPressed: _fetchActivity,
              width: 140,
              height: 38,
            ),
          ],
        ),
      );
    }

    final act = _activity;
    if (act == null) {
      return Center(
        child: Text(
          'النشاط غير موجود أو لم يتم العثور عليه.',
          style: AppTextStyles.font500Medium.copyWith(
            fontSize: 14.sp,
            color: AppColors.secondaryColor,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 12.h),

          // Activity Header Card
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: const Color(0xffE4D4FF), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 32.r,
                  backgroundColor: AppColors.circleAvatarColor,
                  child: Icon(
                    act.domainIcon,
                    size: 34.r,
                    color: AppColors.primaryColor,
                  ),
                ),
                SizedBox(height: 14.h),
                CustomTitle(
                  title: act.title,
                  fontSize: 19,
                ),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildBadge(
                      label: act.domainArabicLabel,
                      icon: act.domainIcon,
                      bgColor: const Color(0xffF0E8FF),
                      textColor: AppColors.primaryColor,
                    ),
                    SizedBox(width: 8.w),
                    _buildBadge(
                      label: act.difficultyArabicLabel,
                      icon: Icons.speed_rounded,
                      bgColor: const Color(0xffFFF3E0),
                      textColor: const Color(0xffE65100),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 18.h),

          // Description Card
          Container(
            padding: EdgeInsets.all(18.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xffE4D4FF), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: TextDirection.rtl,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 18.r,
                      color: AppColors.secondaryTextColor,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'وصف النشاط',
                      style: AppTextStyles.font600SimiBold.copyWith(
                        fontSize: 14.sp,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Text(
                  act.description,
                  style: AppTextStyles.font400Regular.copyWith(
                    fontSize: 13.sp,
                    color: AppColors.secondaryColor,
                    height: 1.6,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),

          // Adaptive Settings Card (Defensive rendering if present)
          if (act.adaptiveSettingsJson != null &&
              act.adaptiveSettingsJson!.trim().isNotEmpty) ...[
            SizedBox(height: 18.h),
            _buildAdaptiveSettingsCard(act.adaptiveSettingsJson!),
          ],

          SizedBox(height: 32.h),

          // Practice/Start Button
          CustomElevatedButton(
            title: 'بدء النشاط',
            isLoading: _isStartingSession,
            onPressed: _startSession,
            height: 48,
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required String label,
    required IconData icon,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          Icon(icon, size: 14.r, color: textColor),
          SizedBox(width: 4.w),
          Text(
            label,
            style: AppTextStyles.font500Medium.copyWith(
              fontSize: 11.sp,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdaptiveSettingsCard(String jsonString) {
    Map<String, dynamic>? parsedMap;
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) {
        parsedMap = decoded;
      }
    } catch (_) {
      // Invalid JSON is handled defensively without crashing
    }

    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xffE4D4FF), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: TextDirection.rtl,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                Icons.tune_rounded,
                size: 18.r,
                color: AppColors.secondaryTextColor,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  'إعدادات التكيف الديناميكي',
                  style: AppTextStyles.font600SimiBold.copyWith(
                    fontSize: 14.sp,
                    color: AppColors.primaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          if (parsedMap != null && parsedMap.isNotEmpty)
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              textDirection: TextDirection.rtl,
              children: parsedMap.entries.map((entry) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffF8F6FF),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: const Color(0xffE4D4FF),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    '${entry.key}: ${entry.value}',
                    style: AppTextStyles.font400Regular.copyWith(
                      fontSize: 11.sp,
                      color: AppColors.primaryColor,
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                );
              }).toList(),
            )
          else
            Text(
              jsonString,
              style: AppTextStyles.font400Regular.copyWith(
                fontSize: 11.sp,
                color: AppColors.secondaryColor,
              ),
              textDirection: TextDirection.ltr,
            ),
        ],
      ),
    );
  }
}
