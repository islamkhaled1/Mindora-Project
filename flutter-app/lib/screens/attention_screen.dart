import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_colors.dart';
import 'package:sawa/app_icons.dart';
import 'package:sawa/core/attention/attention_audio_service.dart';
import 'package:sawa/core/attention/attention_session_engine.dart';
import 'package:sawa/screens/encouragement_screen.dart';
import 'package:sawa/screens/practise_instruction_movement.dart';
import 'package:sawa/widgets/ai_status_banner.dart';
import 'package:sawa/widgets/back_icon.dart';
import 'package:sawa/widgets/custom_app_bar.dart';
import 'package:sawa/widgets/custom_elevated_button.dart';
import 'package:sawa/widgets/custom_padding.dart';
import 'package:sawa/widgets/custom_title.dart';
import 'package:sawa/widgets/icon_circle_avatar.dart';

class AttentionScreen extends StatefulWidget {
  final AttentionSessionEngine? engine;
  final AttentionAudioService? audioService;

  const AttentionScreen({
    super.key,
    this.engine,
    this.audioService,
  });

  @override
  State<AttentionScreen> createState() => _AttentionScreenState();
}

class _AttentionScreenState extends State<AttentionScreen> {
  late final AttentionSessionEngine _engine;
  late final AttentionAudioService _audioService;
  late final bool _ownsAudioService;

  String? _selectedId;
  AttentionRoundResult? _lastResult;
  bool _isAdvancing = false;
  bool _showResults = false;
  bool _isNavigating = false;
  Timer? _advanceTimer;

  @override
  void initState() {
    super.initState();
    _engine = widget.engine ?? AttentionSessionEngine();
    _audioService = widget.audioService ?? DefaultAttentionAudioService();
    _ownsAudioService = widget.audioService == null;

    // Start timing and instruction audio once shapes are rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startCurrentRoundTimingAndAudio();
      }
    });
  }

  void _startCurrentRoundTimingAndAudio() {
    _engine.startRound();
    _audioService.playInstruction(_engine.currentAudioPath);
  }

  void _onItemSelected(String itemId) {
    if (_isAdvancing || _engine.hasAnsweredCurrentRound || _showResults) {
      return;
    }

    final result = _engine.recordAnswer(itemId);
    if (result == null) return;

    setState(() {
      _selectedId = itemId;
      _lastResult = result;
      _isAdvancing = true;
    });

    // Advance after ~1.2 seconds
    _advanceTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;

      if (_engine.currentRoundIndex < AttentionSessionEngine.totalRounds - 1) {
        _engine.nextRound();
        setState(() {
          _selectedId = null;
          _lastResult = null;
          _isAdvancing = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _startCurrentRoundTimingAndAudio();
          }
        });
      } else {
        // Round 4 completed, transition to final results view
        setState(() {
          _showResults = true;
          _selectedId = null;
          _isAdvancing = false;
        });
      }
    });
  }

  void _replayInstruction() {
    if (_showResults) return;
    _audioService.playInstruction(_engine.currentAudioPath);
  }

  void _restartSession() {
    _advanceTimer?.cancel();
    _engine.startSession();
    setState(() {
      _showResults = false;
      _selectedId = null;
      _lastResult = null;
      _isAdvancing = false;
      _isNavigating = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startCurrentRoundTimingAndAudio();
      }
    });
  }

  void _onNextSessionPressed() {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EncouragementScreen(
          exerciseName: "اسمع وابحث",
          circleAvatarColor: AppColors.lightGreen,
          iconColor: AppColors.darkGreen,
          icon: AppIcons.brain,
          title: 'تمرين: اسمع وابحث',
          description: 'تم إكمال جميع الأنشطة بنجاح',
          targetScreen: PractiseInstructionMovement(),
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() => _isNavigating = false);
      }
    });
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _audioService.stop();
    if (_ownsAudioService) {
      _audioService.dispose();
    }
    super.dispose();
  }

  Color _getCardBorderColor(String itemId) {
    if (_selectedId == null || _selectedId != itemId) {
      return Colors.transparent;
    }
    final isCorrect = itemId == _engine.currentTarget.id;
    return isCorrect ? Colors.green : Colors.red;
  }

  Future<bool> _confirmExit() async {
    if (_showResults) {
      return true;
    }

    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Text(
            'تأكيد الخروج',
            style: TextStyle(
              fontFamily: 'Readex Pro',
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
              color: AppColors.primaryColor,
            ),
          ),
          content: Text(
            'هل تريد حقاً الخروج من التمرين؟ سيتم فقدان التقدم في الجولة الحالية.',
            style: TextStyle(
              fontFamily: 'Readex Pro',
              fontSize: 14.sp,
              color: AppColors.secondaryColor,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'متابعة التمرين',
                style: TextStyle(
                  fontFamily: 'Readex Pro',
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'خروج',
                style: TextStyle(
                  fontFamily: 'Readex Pro',
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _showResults,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldLeave = await _confirmExit();
        if (shouldLeave && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: CustomAppBar(
          leading: BackIcon(
            onTap: () async {
              if (_showResults) {
                Navigator.of(context).pop();
              } else {
                final shouldLeave = await _confirmExit();
                if (shouldLeave && context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
          ),
          title: const CustomTitle(title: 'اسمع وابحث', fontSize: 22),
        ),
        body: SingleChildScrollView(
          child: CustomPadding(
            child: _showResults
                ? _buildCompletionView(context)
                : _buildActiveRoundView(context),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveRoundView(BuildContext context) {
    final currentTarget = _engine.currentTarget;
    final currentOptions = _engine.currentOptions;

    return Column(
      children: [
        SizedBox(height: 12.h),

        // AI Status Banner - Transparent messaging: Training is active now, advanced AI is in development
        const AiStatusBanner(
          compact: true,
          domainName: 'الانتباه',
          title: 'التحليل الذكي المتقدم قريبًا',
          description:
              'نعمل حاليًا على تطوير نموذج AI مخصص لتحليل مهارات الانتباه.',
        ),

        SizedBox(height: 16.h),

        // Round Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.circleAvatarColor,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                'الجولة ${_engine.currentRoundNumber} من ${AttentionSessionEngine.totalRounds}',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                  fontFamily: 'Readex Pro',
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 12.h),

        // Target Prompt & Speaker Replay Row
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: CustomTitle(title: currentTarget.promptText, fontSize: 24),
            ),
            SizedBox(width: 8.w),
            GestureDetector(
              key: const Key('replay_speaker_button'),
              onTap: _replayInstruction,
              child: IconCircleAvatar(
                padding: 6,
                iconSize: 28,
                icon: AppIcons.speaker,
                color: AppColors.primaryColor,
                backgroundColor: AppColors.circleAvatarColor,
              ),
            ),
          ],
        ),

        SizedBox(height: 20.h),

        // Shapes Grid Card
        Container(
          padding: EdgeInsets.all(10.r),
          width: double.infinity,
          height: 280.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: GridView.builder(
            itemCount: currentOptions.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.25,
              mainAxisSpacing: 5.r,
              crossAxisSpacing: 15.r,
            ),
            itemBuilder: (context, index) {
              final item = currentOptions[index];
              final borderColor = _getCardBorderColor(item.id);

              return GestureDetector(
                key: Key('shape_card_${item.id}'),
                behavior: HitTestBehavior.opaque,
                onTap: () => _onItemSelected(item.id),
                child: Container(
                  margin: EdgeInsets.all(8.r),
                  width: 120.w,
                  height: 90.h,
                  decoration: BoxDecoration(
                    color: AppColors.cardsColor,
                    borderRadius: BorderRadius.circular(15.r),
                    border: Border.all(color: borderColor, width: 2.5),
                  ),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(12.r),
                      child: Image.asset(
                        item.imagePath,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        SizedBox(height: 16.h),

        // Feedback Text
        if (_lastResult != null)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: _lastResult!.isCorrect
                  ? AppColors.lightGreen
                  : AppColors.lightRed,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _lastResult!.isCorrect ? Icons.check_circle : Icons.cancel,
                  color: _lastResult!.isCorrect
                      ? AppColors.darkGreen
                      : AppColors.darkRed,
                  size: 20.r,
                ),
                SizedBox(width: 8.w),
                Text(
                  _lastResult!.isCorrect ? 'إجابة صحيحة!' : 'إجابة خاطئة',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: _lastResult!.isCorrect
                        ? AppColors.darkGreen
                        : AppColors.darkRed,
                    fontFamily: 'Readex Pro',
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(height: 38.h),

        SizedBox(height: 20.h),

        // Replay Button
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomElevatedButton(
              backgroundColor: Colors.white,
              textColor: AppColors.primaryColor,
              width: 160,
              title: 'اسمع مرة أخرى',
              onPressed: _replayInstruction,
            ),
          ],
        ),

        SizedBox(height: 24.h),
      ],
    );
  }

  Widget _buildCompletionView(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 12.h),

        // AI Status Banner
        const AiStatusBanner(
          compact: true,
          domainName: 'الانتباه',
          title: 'التحليل الذكي المتقدم قريبًا',
          description:
              'نعمل حاليًا على تطوير نموذج AI مخصص لتحليل مهارات الانتباه.',
        ),

        SizedBox(height: 20.h),

        // Results Card
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                size: 56.r,
                color: AppColors.primaryColor,
              ),
              SizedBox(height: 8.h),
              Text(
                'نتائج التمرين',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                  fontFamily: 'Readex Pro',
                ),
              ),
              SizedBox(height: 20.h),

              // Metrics List
              _buildMetricTile(
                title: 'الإجابات الصحيحة',
                value: '${_engine.correctAnswers} من ${AttentionSessionEngine.totalRounds}',
                icon: Icons.check_circle_outline,
                color: AppColors.darkGreen,
                bgColor: AppColors.lightGreen,
              ),
              SizedBox(height: 12.h),

              _buildMetricTile(
                title: 'الإجابات الخاطئة',
                value: '${_engine.wrongAnswers} من ${AttentionSessionEngine.totalRounds}',
                icon: Icons.highlight_off,
                color: AppColors.darkRed,
                bgColor: AppColors.lightRed,
              ),
              SizedBox(height: 12.h),

              _buildMetricTile(
                title: 'الدقة',
                value: '${_engine.score.toInt()}%',
                icon: Icons.pie_chart_outline,
                color: AppColors.primaryColor,
                bgColor: AppColors.cardsColor,
              ),
              SizedBox(height: 12.h),

              _buildMetricTile(
                title: 'متوسط سرعة الاستجابة',
                value: _engine.formattedAverageReactionTimeSeconds,
                icon: Icons.timer_outlined,
                color: AppColors.secondaryTextColor,
                bgColor: AppColors.notificationColor,
              ),
            ],
          ),
        ),

        SizedBox(height: 28.h),

        // Actions: Restart or Proceed to EncouragementScreen
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomElevatedButton(
              key: const Key('restart_session_button'),
              backgroundColor: Colors.white,
              textColor: AppColors.primaryColor,
              width: 130,
              title: 'إعادة التمرين',
              onPressed: _restartSession,
            ),
            SizedBox(width: 12.w),
            CustomElevatedButton(
              key: const Key('next_session_button'),
              width: 130,
              title: 'التالي',
              onPressed: _onNextSessionPressed,
            ),
          ],
        ),

        SizedBox(height: 24.h),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Readex Pro',
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryColor,
                      fontFamily: 'Readex Pro',
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(icon, color: color, size: 20.r),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
