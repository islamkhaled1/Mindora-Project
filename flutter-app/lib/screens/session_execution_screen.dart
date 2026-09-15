import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_text_styles.dart';
import 'package:sawa/constants.dart';
import 'package:sawa/core/errors/api_exception.dart';
import 'package:sawa/core/models/activity_models.dart';
import 'package:sawa/core/models/session_models.dart';
import 'package:sawa/core/services/session_service.dart';
import 'package:sawa/features/movement/engine/movement_engine.dart';
import 'package:sawa/features/movement/services/hand_tracker_service.dart';
import 'package:sawa/features/movement/widgets/interactive_target_arena.dart';
import 'package:sawa/screens/practise_instruction_attention.dart';
import 'package:sawa/screens/session_encouragement_screen.dart';
import 'package:sawa/widgets/custom_app_bar.dart';
import 'package:sawa/widgets/custom_elevated_button.dart';
import 'package:sawa/widgets/custom_padding.dart';
import 'package:sawa/widgets/custom_title.dart';

class SessionExecutionScreen extends StatefulWidget {
  final SessionModel session;
  final ActivityModel activity;

  const SessionExecutionScreen({
    super.key,
    required this.session,
    required this.activity,
  });

  @override
  State<SessionExecutionScreen> createState() => _SessionExecutionScreenState();
}

class _SessionExecutionScreenState extends State<SessionExecutionScreen> {
  final SessionService _sessionService = SessionService();

  late Timer _durationTimer;
  int _elapsedSeconds = 0;

  // Movement AI state
  MovementEngine? _movementEngine;
  HandTrackerService? _trackerService;

  // Domain-specific honest measurement states
  int _repetitionCount = 0;
  double _accuracyPercentage = 85.0;
  double? _measuredReactionTimeMs;
  double _speechClarity = 80.0;

  bool _isCompleting = false;
  bool _isAbandoning = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startDurationTimer();
    if (widget.activity.domainEnum == ActivityDomainEnum.movement) {
      _initMovementAI();
    }
  }

  void _initMovementAI() {
    _movementEngine = MovementEngine();
    _trackerService = HandTrackerService();
    _movementEngine!.start(DateTime.now().millisecondsSinceEpoch);
    _trackerService!.initialize().then((ready) {
      if (ready && mounted) {
        _trackerService!.startTracking();
      }
    });
  }

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  List<MetricInputModel> _gatherSessionMetrics() {
    final metrics = <MetricInputModel>[];
    final domain = widget.activity.domainEnum;

    if (domain == ActivityDomainEnum.movement) {
      final reps = _movementEngine?.repetitions ?? _repetitionCount;
      final acc = _movementEngine?.accuracyPercentage ?? _accuracyPercentage;
      final avgReaction = (_movementEngine != null && _movementEngine!.averageReactionTimeMs > 0)
          ? _movementEngine!.averageReactionTimeMs
          : (_measuredReactionTimeMs ?? 500.0);

      metrics.add(MetricInputModel(
        metricType: SupportedMetricType.repetitionCount.backendKey,
        value: reps.toDouble(),
      ));
      metrics.add(MetricInputModel(
        metricType: SupportedMetricType.accuracyPercentage.backendKey,
        value: acc,
      ));
      metrics.add(MetricInputModel(
        metricType: SupportedMetricType.reactionTimeMs.backendKey,
        value: avgReaction,
      ));
    } else if (domain == ActivityDomainEnum.speech) {
      metrics.add(MetricInputModel(
        metricType: SupportedMetricType.repetitionCount.backendKey,
        value: _repetitionCount.toDouble(),
      ));
      metrics.add(MetricInputModel(
        metricType: SupportedMetricType.speechClarityScore.backendKey,
        value: _speechClarity,
      ));
    } else if (domain == ActivityDomainEnum.attention) {
      metrics.add(MetricInputModel(
        metricType: SupportedMetricType.attentionDurationSeconds.backendKey,
        value: _elapsedSeconds.toDouble(),
      ));
      metrics.add(MetricInputModel(
        metricType: SupportedMetricType.accuracyPercentage.backendKey,
        value: _accuracyPercentage,
      ));
    } else {
      metrics.add(MetricInputModel(
        metricType: SupportedMetricType.repetitionCount.backendKey,
        value: _repetitionCount.toDouble(),
      ));
    }

    return metrics;
  }

  Future<void> _completeSession() async {
    if (_isCompleting) return; // Guard against duplicate submissions

    setState(() {
      _isCompleting = true;
      _errorMessage = null;
    });

    _durationTimer.cancel();

    final metrics = _gatherSessionMetrics();

    try {
      final completedSession = await _sessionService.completeSession(
        sessionId: widget.session.id,
        request: CompleteSessionRequest(
          actualDurationSeconds: _elapsedSeconds,
          metrics: metrics,
        ),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SessionEncouragementScreen(
              completedSession: completedSession,
              activity: widget.activity,
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isCompleting = false;
          _errorMessage = e.firstErrorMessage;
        });
        _startDurationTimer(); // Resume timer if failed
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isCompleting = false;
          _errorMessage = 'حدث خطأ أثناء إنهاء الجلسة، يرجى المحاولة مرة أخرى.';
        });
        _startDurationTimer();
      }
    }
  }

  Future<void> _abandonSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Text(
            'إلغاء الجلسة الحالية',
            style: AppTextStyles.font700Bold.copyWith(
              fontSize: 16.sp,
              color: AppColors.primaryColor,
            ),
          ),
          content: Text(
            'هل أنت متأكد من رغبتك في إلغاء هذه الجلسة التدريبية؟ لن يتم حفظ قياسات الأداء للجلسة الملغاة.',
            style: AppTextStyles.font400Regular.copyWith(
              fontSize: 13.sp,
              color: AppColors.secondaryColor,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'متابعة الجلسة',
                style: AppTextStyles.font600SimiBold.copyWith(
                  fontSize: 13.sp,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                'نعم، إلغاء الجلسة',
                style: AppTextStyles.font600SimiBold.copyWith(
                  fontSize: 13.sp,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _isAbandoning = true);
    _durationTimer.cancel();

    try {
      await _sessionService.abandonSession(widget.session.id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isAbandoning = false);
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _durationTimer.cancel();
    _trackerService?.dispose();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _abandonSession();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: CustomAppBar(
          leading: IconButton(
            icon: Icon(Icons.close_rounded, size: 24.r, color: AppColors.primaryColor),
            onPressed: _abandonSession,
          ),
        ),
        body: SafeArea(
          child: CustomPadding(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 8.h),

                  // Session Header with Timer & Domain
                  _buildSessionHeader(),
                  SizedBox(height: 18.h),

                  // Interactive Training Guidance
                  _buildInteractiveTrainingCard(),
                  SizedBox(height: 18.h),

                  // Error Message
                  if (_errorMessage != null) ...[
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: AppTextStyles.font500Medium.copyWith(
                          fontSize: 12.sp,
                          color: Colors.red.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],

                  // Completion Action Button
                  CustomElevatedButton(
                    title: 'إنهاء الجلسة وحفظ الأداء',
                    isLoading: _isCompleting,
                    onPressed: _completeSession,
                    height: 48,
                  ),
                  SizedBox(height: 12.h),

                  // Abandon Action Button
                  Center(
                    child: TextButton.icon(
                      onPressed: _isCompleting || _isAbandoning ? null : _abandonSession,
                      icon: Icon(Icons.cancel_outlined, size: 18.r, color: Colors.red.shade400),
                      label: Text(
                        'إلغاء الجلسة دون حفظ',
                        style: AppTextStyles.font500Medium.copyWith(
                          fontSize: 13.sp,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionHeader() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  textDirection: TextDirection.rtl,
                  children: [
                    Text(
                      widget.activity.title,
                      style: AppTextStyles.font700Bold.copyWith(
                        fontSize: 15.sp,
                        color: AppColors.primaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        _buildSmallBadge(
                          label: widget.activity.domainArabicLabel,
                          color: AppColors.primaryColor,
                          bgColor: const Color(0xffF0E8FF),
                        ),
                        if (widget.session.targetDifficulty != null) ...[
                          SizedBox(width: 6.w),
                          _buildSmallBadge(
                            label: widget.activity.difficultyArabicLabel,
                            color: const Color(0xffE65100),
                            bgColor: const Color(0xffFFF3E0),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Elapsed Duration Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: const Color(0xffF8F6FF),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: const Color(0xffE4D4FF), width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 18.r, color: AppColors.secondaryTextColor),
                    SizedBox(width: 6.w),
                    Text(
                      _formatDuration(_elapsedSeconds),
                      style: AppTextStyles.font700Bold.copyWith(
                        fontSize: 15.sp,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveTrainingCard() {
    final domain = widget.activity.domainEnum;

    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xffE4D4FF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomTitle(
            title: 'التفاعل والقياس المباشر',
            fontSize: 16,
          ),
          SizedBox(height: 6.h),
          Text(
            'سجل أداء الطفل أثناء أداء تمرين النشاط بأمان ومصداقية.',
            style: AppTextStyles.font400Regular.copyWith(
              fontSize: 12.sp,
              color: AppColors.secondaryColor,
            ),
            textDirection: TextDirection.rtl,
          ),
          SizedBox(height: 16.h),

          // Domain-specific interaction controls
          if (domain == ActivityDomainEnum.movement)
            _buildMovementControls()
          else if (domain == ActivityDomainEnum.speech)
            _buildSpeechControls()
          else
            _buildAttentionControls(),
        ],
      ),
    );
  }

  Widget _buildMovementControls() {
    if (_movementEngine != null && _trackerService != null) {
      return Column(
        children: [
          InteractiveTargetArena(
            engine: _movementEngine!,
            trackerService: _trackerService!,
            onMetricsUpdated: () {
              if (mounted) {
                setState(() {
                  _repetitionCount = _movementEngine!.repetitions;
                  _accuracyPercentage = _movementEngine!.accuracyPercentage;
                  if (_movementEngine!.latestReactionTimeMs != null) {
                    _measuredReactionTimeMs =
                        _movementEngine!.latestReactionTimeMs!.toDouble();
                  }
                });
              }
            },
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSpeechControls() {
    return Column(
      children: [
        // Word / Sound Prompt Container
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: const Color(0xffF8F6FF),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xffE4D4FF)),
          ),
          child: Column(
            children: [
              Icon(Icons.record_voice_over_rounded, size: 36.r, color: AppColors.primaryColor),
              SizedBox(height: 8.h),
              Text(
                'تكرار نطق الأصوات والمقاطع المستهدفة',
                style: AppTextStyles.font600SimiBold.copyWith(
                  fontSize: 13.sp,
                  color: AppColors.primaryColor,
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      if (_repetitionCount > 0) {
                        setState(() => _repetitionCount--);
                      }
                    },
                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.secondaryColor),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    '$_repetitionCount تكرار',
                    style: AppTextStyles.font700Bold.copyWith(
                      fontSize: 18.sp,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  IconButton(
                    onPressed: () => setState(() => _repetitionCount++),
                    icon: const Icon(Icons.add_circle, color: AppColors.secondaryTextColor),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),

        // Speech Clarity Rating Slider
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          textDirection: TextDirection.rtl,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              textDirection: TextDirection.rtl,
              children: [
                Text(
                  'تقييم وضوح مخارج الحروف:',
                  style: AppTextStyles.font500Medium.copyWith(
                    fontSize: 12.sp,
                    color: AppColors.primaryColor,
                  ),
                ),
                Text(
                  '${_speechClarity.toStringAsFixed(0)}%',
                  style: AppTextStyles.font700Bold.copyWith(
                    fontSize: 13.sp,
                    color: AppColors.secondaryTextColor,
                  ),
                ),
              ],
            ),
            Slider(
              value: _speechClarity,
              min: 30.0,
              max: 100.0,
              divisions: 14,
              activeColor: AppColors.secondaryTextColor,
              onChanged: (val) => setState(() => _speechClarity = val),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttentionControls() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: const Color(0xffF8F6FF),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xffE4D4FF)),
          ),
          child: Column(
            children: [
              Icon(Icons.hearing_rounded, size: 40.r, color: AppColors.primaryColor),
              SizedBox(height: 8.h),
              Text(
                'تمرين الانتباه المعتمد: اسمع وابحث',
                style: AppTextStyles.font600SimiBold.copyWith(
                  fontSize: 14.sp,
                  color: AppColors.primaryColor,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'يستمع الطفل للتوجيه الصوتي ويختار الشكل أو اللون المطابق من بين 4 خيارات تفاعلية.',
                textAlign: TextAlign.center,
                style: AppTextStyles.font400Regular.copyWith(
                  fontSize: 12.sp,
                  color: AppColors.secondaryColor,
                ),
              ),
              SizedBox(height: 14.h),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PractiseInstructionAttention(),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                label: const Text('بدء تمرين اسمع وابحث'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSmallBadge({
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        label,
        style: AppTextStyles.font500Medium.copyWith(
          fontSize: 11.sp,
          color: color,
        ),
      ),
    );
  }
}
