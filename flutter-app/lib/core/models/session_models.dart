import 'package:flutter/material.dart';

/// Supported performance metric types strictly validated by ASP.NET Core backend.
enum SupportedMetricType {
  repetitionCount('RepetitionCount', 'عدد التكرارات', 'تكرار', Icons.repeat_rounded),
  accuracyPercentage('AccuracyPercentage', 'نسبة الدقة', '%', Icons.check_circle_outline_rounded),
  reactionTimeMs('ReactionTimeMs', 'زمن الاستجابة', 'مللي ثانية', Icons.timer_outlined),
  speechClarityScore('SpeechClarityScore', 'وضوح النطق والكلام', '%', Icons.record_voice_over_outlined),
  responseLatencyMs('ResponseLatencyMs', 'زمن استجابة الطفل', 'مللي ثانية', Icons.hourglass_empty_rounded),
  attentionDurationSeconds('AttentionDurationSeconds', 'مدة التركيز المتواصل', 'ثانية', Icons.visibility_outlined);

  final String backendKey;
  final String arabicLabel;
  final String unit;
  final IconData icon;

  const SupportedMetricType(this.backendKey, this.arabicLabel, this.unit, this.icon);

  static SupportedMetricType? fromKey(String key) {
    for (final type in values) {
      if (type.backendKey.toLowerCase() == key.toLowerCase()) {
        return type;
      }
    }
    return null;
  }
}

/// Parent sentiment evaluation strictly mapped to ASP.NET Core `ParentSentimentRating`.
enum ParentSentimentRating {
  easy(1, 'سهل ومريح'),
  medium(2, 'مناسب ومتوازن'),
  difficult(3, 'تطلب مجهودًا إضافيًا');

  final int value;
  final String arabicLabel;

  const ParentSentimentRating(this.value, this.arabicLabel);

  static ParentSentimentRating? fromValue(dynamic val) {
    if (val == null) return null;
    if (val is int) {
      for (final r in values) {
        if (r.value == val) return r;
      }
    }
    if (val is String) {
      final normalized = val.trim().toLowerCase();
      if (normalized == 'easy' || normalized == '1') return ParentSentimentRating.easy;
      if (normalized == 'medium' || normalized == '2') return ParentSentimentRating.medium;
      if (normalized == 'difficult' || normalized == '3') return ParentSentimentRating.difficult;
    }
    return null;
  }
}

/// Adaptive difficulty adjustment recommendation strictly mapped to ASP.NET Core `DifficultyAdjustment`.
enum DifficultyAdjustment {
  decrease(
    -1,
    'تخفيف الصعوبة',
    'تخفيف مستوى التحدي للجلسة القادمة لمزيد من التمكن والراحة',
    Icons.trending_down_rounded,
    Color(0xffE65100),
    Color(0xffFFF3E0),
  ),
  maintain(
    0,
    'تثبيت المستوى',
    'الاستمرار على نفس المستوى التدريبي لتثبيت المهارة المكتسبة',
    Icons.trending_flat_rounded,
    Color(0xff2E7D32),
    Color(0xffE8F5E9),
  ),
  increase(
    1,
    'زيادة الصعوبة',
    'رفع مستوى التحدي تدريجيًا لتحفيز تطور مهارات الطفل',
    Icons.trending_up_rounded,
    Color(0xff8456D2),
    Color(0xffF0E8FF),
  );

  final int value;
  final String badgeText;
  final String description;
  final IconData icon;
  final Color textColor;
  final Color bgColor;

  const DifficultyAdjustment(
    this.value,
    this.badgeText,
    this.description,
    this.icon,
    this.textColor,
    this.bgColor,
  );

  static DifficultyAdjustment fromString(String? val) {
    if (val == null || val.trim().isEmpty) return DifficultyAdjustment.maintain;
    final normalized = val.trim().toLowerCase();
    if (normalized == 'increase' || normalized == '1') return DifficultyAdjustment.increase;
    if (normalized == 'decrease' || normalized == '-1') return DifficultyAdjustment.decrease;
    return DifficultyAdjustment.maintain;
  }
}

/// Request model strictly mapping to ASP.NET Core `StartSessionRequest`.
class StartSessionRequest {
  final String childId;
  final String activityId;

  const StartSessionRequest({
    required this.childId,
    required this.activityId,
  });

  Map<String, dynamic> toJson() => {
        'childId': childId,
        'activityId': activityId,
      };
}

/// Strongly typed session model mapping to ASP.NET Core `SessionDto`.
class SessionModel {
  final String id;
  final String childId;
  final String activityId;
  final String domain;
  final String status;
  final DateTime startTimeUtc;
  final String? targetDifficulty;
  final String? adaptiveSettingsJson;

  const SessionModel({
    required this.id,
    required this.childId,
    required this.activityId,
    required this.domain,
    required this.status,
    required this.startTimeUtc,
    this.targetDifficulty,
    this.adaptiveSettingsJson,
  });

  bool get isStarted => status.toLowerCase() == 'started';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isAbandoned => status.toLowerCase() == 'abandoned';

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    final rawStart = json['startTimeUtc'] ?? json['StartTimeUtc'];
    DateTime parsedStart = DateTime.now().toUtc();
    if (rawStart != null) {
      parsedStart = DateTime.tryParse(rawStart.toString())?.toUtc() ?? DateTime.now().toUtc();
    }

    return SessionModel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      childId: (json['childId'] ?? json['ChildId'] ?? '').toString(),
      activityId: (json['activityId'] ?? json['ActivityId'] ?? '').toString(),
      domain: (json['domain'] ?? json['Domain'] ?? '').toString(),
      status: (json['status'] ?? json['Status'] ?? 'Started').toString(),
      startTimeUtc: parsedStart,
      targetDifficulty: (json['targetDifficulty'] ?? json['TargetDifficulty'])?.toString(),
      adaptiveSettingsJson: (json['adaptiveSettingsJson'] ?? json['AdaptiveSettingsJson'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'childId': childId,
        'activityId': activityId,
        'domain': domain,
        'status': status,
        'startTimeUtc': startTimeUtc.toIso8601String(),
        if (targetDifficulty != null) 'targetDifficulty': targetDifficulty,
        if (adaptiveSettingsJson != null) 'adaptiveSettingsJson': adaptiveSettingsJson,
      };
}

/// Input model strictly mapping to ASP.NET Core `MetricInputDto`.
class MetricInputModel {
  final String metricType;
  final double value;

  const MetricInputModel({
    required this.metricType,
    required this.value,
  });

  Map<String, dynamic> toJson() => {
        'metricType': metricType,
        'value': value,
      };
}

/// Request model strictly mapping to ASP.NET Core `RecordMetricsRequest`.
class RecordMetricsRequest {
  final List<MetricInputModel> metrics;

  const RecordMetricsRequest({required this.metrics});

  Map<String, dynamic> toJson() => {
        'metrics': metrics.map((m) => m.toJson()).toList(),
      };
}

/// Strongly typed performance metric mapping to ASP.NET Core `PerformanceMetricDto`.
class PerformanceMetricModel {
  final String id;
  final String sessionId;
  final String metricType;
  final double value;
  final DateTime timestampUtc;

  const PerformanceMetricModel({
    required this.id,
    required this.sessionId,
    required this.metricType,
    required this.value,
    required this.timestampUtc,
  });

  SupportedMetricType? get metricTypeEnum => SupportedMetricType.fromKey(metricType);

  String get localizedTitle => metricTypeEnum?.arabicLabel ?? metricType;
  String get unit => metricTypeEnum?.unit ?? '';
  IconData get icon => metricTypeEnum?.icon ?? Icons.analytics_outlined;

  factory PerformanceMetricModel.fromJson(Map<String, dynamic> json) {
    double parseVal(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    final rawTime = json['timestampUtc'] ?? json['TimestampUtc'];
    DateTime parsedTime = DateTime.now().toUtc();
    if (rawTime != null) {
      parsedTime = DateTime.tryParse(rawTime.toString())?.toUtc() ?? DateTime.now().toUtc();
    }

    return PerformanceMetricModel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      sessionId: (json['sessionId'] ?? json['SessionId'] ?? '').toString(),
      metricType: (json['metricType'] ?? json['MetricType'] ?? '').toString(),
      value: parseVal(json['value'] ?? json['Value']),
      timestampUtc: parsedTime,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'metricType': metricType,
        'value': value,
        'timestampUtc': timestampUtc.toIso8601String(),
      };
}

/// Request model strictly mapping to ASP.NET Core `CompleteSessionRequest`.
class CompleteSessionRequest {
  final int actualDurationSeconds;
  final List<MetricInputModel>? metrics;
  final ParentSentimentRating? parentRating;
  final String? parentNotes;

  const CompleteSessionRequest({
    required this.actualDurationSeconds,
    this.metrics,
    this.parentRating,
    this.parentNotes,
  });

  Map<String, dynamic> toJson() => {
        'actualDurationSeconds': actualDurationSeconds,
        if (metrics != null && metrics!.isNotEmpty)
          'metrics': metrics!.map((m) => m.toJson()).toList(),
        if (parentRating != null) 'parentRating': parentRating!.value,
        if (parentNotes != null && parentNotes!.trim().isNotEmpty)
          'parentNotes': parentNotes!.trim(),
      };
}

/// Request model strictly mapping to ASP.NET Core `RecordFeedbackRequest`.
class RecordFeedbackRequest {
  final ParentSentimentRating rating;
  final String? notes;

  const RecordFeedbackRequest({
    required this.rating,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'rating': rating.value,
        if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
      };
}

/// Strongly typed AI analysis result mapping to ASP.NET Core `SessionAnalysisResultDto`.
class SessionAnalysisResultModel {
  final String id;
  final String sessionId;
  final double overallPerformanceScore;
  final double domainScore;
  final String supportiveObservations;
  final bool fatigueObserved;
  final String recommendedDifficultyAdjustment;
  final String? adaptiveParametersJson;
  final DateTime analyzedAtUtc;
  final bool isFallbackResult;

  const SessionAnalysisResultModel({
    required this.id,
    required this.sessionId,
    required this.overallPerformanceScore,
    required this.domainScore,
    required this.supportiveObservations,
    required this.fatigueObserved,
    required this.recommendedDifficultyAdjustment,
    this.adaptiveParametersJson,
    required this.analyzedAtUtc,
    required this.isFallbackResult,
  });

  DifficultyAdjustment get difficultyAdjustmentEnum =>
      DifficultyAdjustment.fromString(recommendedDifficultyAdjustment);

  factory SessionAnalysisResultModel.fromJson(Map<String, dynamic> json) {
    double parseVal(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    bool parseBool(dynamic v) {
      if (v is bool) return v;
      if (v is String) return v.toLowerCase() == 'true';
      return false;
    }

    final rawTime = json['analyzedAtUtc'] ?? json['AnalyzedAtUtc'];
    DateTime parsedTime = DateTime.now().toUtc();
    if (rawTime != null) {
      parsedTime = DateTime.tryParse(rawTime.toString())?.toUtc() ?? DateTime.now().toUtc();
    }

    return SessionAnalysisResultModel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      sessionId: (json['sessionId'] ?? json['SessionId'] ?? '').toString(),
      overallPerformanceScore: parseVal(json['overallPerformanceScore'] ?? json['OverallPerformanceScore']),
      domainScore: parseVal(json['domainScore'] ?? json['DomainScore']),
      supportiveObservations: (json['supportiveObservations'] ?? json['SupportiveObservations'] ?? '').toString(),
      fatigueObserved: parseBool(json['fatigueObserved'] ?? json['FatigueObserved']),
      recommendedDifficultyAdjustment:
          (json['recommendedDifficultyAdjustment'] ?? json['RecommendedDifficultyAdjustment'] ?? 'Maintain')
              .toString(),
      adaptiveParametersJson:
          (json['adaptiveParametersJson'] ?? json['AdaptiveParametersJson'])?.toString(),
      analyzedAtUtc: parsedTime,
      isFallbackResult: parseBool(json['isFallbackResult'] ?? json['IsFallbackResult']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'overallPerformanceScore': overallPerformanceScore,
        'domainScore': domainScore,
        'supportiveObservations': supportiveObservations,
        'fatigueObserved': fatigueObserved,
        'recommendedDifficultyAdjustment': recommendedDifficultyAdjustment,
        if (adaptiveParametersJson != null) 'adaptiveParametersJson': adaptiveParametersJson,
        'analyzedAtUtc': analyzedAtUtc.toIso8601String(),
        'isFallbackResult': isFallbackResult,
      };
}

/// Strongly typed completed session model mapping to ASP.NET Core `CompletedSessionDto`.
class CompletedSessionModel {
  final String id;
  final String childId;
  final String activityId;
  final String domain;
  final String status;
  final DateTime startTimeUtc;
  final DateTime? endTimeUtc;
  final int? actualDurationSeconds;
  final SessionAnalysisResultModel? analysisResult;
  final List<PerformanceMetricModel> metrics;
  final String? parentRating;
  final String? parentNotes;

  const CompletedSessionModel({
    required this.id,
    required this.childId,
    required this.activityId,
    required this.domain,
    required this.status,
    required this.startTimeUtc,
    this.endTimeUtc,
    this.actualDurationSeconds,
    this.analysisResult,
    required this.metrics,
    this.parentRating,
    this.parentNotes,
  });

  ParentSentimentRating? get parentRatingEnum => ParentSentimentRating.fromValue(parentRating);

  factory CompletedSessionModel.fromJson(Map<String, dynamic> json) {
    final rawStart = json['startTimeUtc'] ?? json['StartTimeUtc'];
    DateTime parsedStart = DateTime.now().toUtc();
    if (rawStart != null) {
      parsedStart = DateTime.tryParse(rawStart.toString())?.toUtc() ?? DateTime.now().toUtc();
    }

    final rawEnd = json['endTimeUtc'] ?? json['EndTimeUtc'];
    DateTime? parsedEnd;
    if (rawEnd != null) {
      parsedEnd = DateTime.tryParse(rawEnd.toString())?.toUtc();
    }

    int? parsedDuration;
    final rawDuration = json['actualDurationSeconds'] ?? json['ActualDurationSeconds'];
    if (rawDuration is int) {
      parsedDuration = rawDuration;
    } else if (rawDuration is num) {
      parsedDuration = rawDuration.toInt();
    } else if (rawDuration is String) {
      parsedDuration = int.tryParse(rawDuration);
    }

    SessionAnalysisResultModel? analysis;
    final rawAnalysis = json['analysisResult'] ?? json['AnalysisResult'];
    if (rawAnalysis is Map<String, dynamic>) {
      analysis = SessionAnalysisResultModel.fromJson(rawAnalysis);
    } else if (rawAnalysis is Map) {
      analysis = SessionAnalysisResultModel.fromJson(Map<String, dynamic>.from(rawAnalysis));
    }

    final metricList = <PerformanceMetricModel>[];
    final rawMetrics = json['metrics'] ?? json['Metrics'];
    if (rawMetrics is List) {
      for (final m in rawMetrics) {
        if (m is Map) {
          metricList.add(PerformanceMetricModel.fromJson(Map<String, dynamic>.from(m)));
        }
      }
    }

    return CompletedSessionModel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      childId: (json['childId'] ?? json['ChildId'] ?? '').toString(),
      activityId: (json['activityId'] ?? json['ActivityId'] ?? '').toString(),
      domain: (json['domain'] ?? json['Domain'] ?? '').toString(),
      status: (json['status'] ?? json['Status'] ?? 'Completed').toString(),
      startTimeUtc: parsedStart,
      endTimeUtc: parsedEnd,
      actualDurationSeconds: parsedDuration,
      analysisResult: analysis,
      metrics: metricList,
      parentRating: (json['parentRating'] ?? json['ParentRating'])?.toString(),
      parentNotes: (json['parentNotes'] ?? json['ParentNotes'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'childId': childId,
        'activityId': activityId,
        'domain': domain,
        'status': status,
        'startTimeUtc': startTimeUtc.toIso8601String(),
        if (endTimeUtc != null) 'endTimeUtc': endTimeUtc!.toIso8601String(),
        if (actualDurationSeconds != null) 'actualDurationSeconds': actualDurationSeconds,
        if (analysisResult != null) 'analysisResult': analysisResult!.toJson(),
        'metrics': metrics.map((m) => m.toJson()).toList(),
        if (parentRating != null) 'parentRating': parentRating,
        if (parentNotes != null) 'parentNotes': parentNotes,
      };
}

/// Activity summary inside `SessionDetailsDto`.
class SessionActivitySummaryModel {
  final String id;
  final String title;
  final String domain;
  final String baseDifficulty;

  const SessionActivitySummaryModel({
    required this.id,
    required this.title,
    required this.domain,
    required this.baseDifficulty,
  });

  factory SessionActivitySummaryModel.fromJson(Map<String, dynamic> json) {
    return SessionActivitySummaryModel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      title: (json['title'] ?? json['Title'] ?? '').toString(),
      domain: (json['domain'] ?? json['Domain'] ?? '').toString(),
      baseDifficulty: (json['baseDifficulty'] ?? json['BaseDifficulty'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'domain': domain,
        'baseDifficulty': baseDifficulty,
      };
}

/// Strongly typed session details model mapping to ASP.NET Core `SessionDetailsDto`.
class SessionDetailsModel {
  final String id;
  final String childId;
  final SessionActivitySummaryModel activity;
  final String domain;
  final String status;
  final DateTime startTimeUtc;
  final DateTime? endTimeUtc;
  final int? actualDurationSeconds;
  final SessionAnalysisResultModel? analysisResult;
  final List<PerformanceMetricModel> metrics;
  final String? parentRating;
  final String? parentNotes;

  const SessionDetailsModel({
    required this.id,
    required this.childId,
    required this.activity,
    required this.domain,
    required this.status,
    required this.startTimeUtc,
    this.endTimeUtc,
    this.actualDurationSeconds,
    this.analysisResult,
    required this.metrics,
    this.parentRating,
    this.parentNotes,
  });

  factory SessionDetailsModel.fromJson(Map<String, dynamic> json) {
    final rawStart = json['startTimeUtc'] ?? json['StartTimeUtc'];
    DateTime parsedStart = DateTime.now().toUtc();
    if (rawStart != null) {
      parsedStart = DateTime.tryParse(rawStart.toString())?.toUtc() ?? DateTime.now().toUtc();
    }

    final rawEnd = json['endTimeUtc'] ?? json['EndTimeUtc'];
    DateTime? parsedEnd;
    if (rawEnd != null) {
      parsedEnd = DateTime.tryParse(rawEnd.toString())?.toUtc();
    }

    int? parsedDuration;
    final rawDuration = json['actualDurationSeconds'] ?? json['ActualDurationSeconds'];
    if (rawDuration is int) {
      parsedDuration = rawDuration;
    } else if (rawDuration is num) {
      parsedDuration = rawDuration.toInt();
    } else if (rawDuration is String) {
      parsedDuration = int.tryParse(rawDuration);
    }

    SessionActivitySummaryModel act;
    final rawAct = json['activity'] ?? json['Activity'];
    if (rawAct is Map<String, dynamic>) {
      act = SessionActivitySummaryModel.fromJson(rawAct);
    } else if (rawAct is Map) {
      act = SessionActivitySummaryModel.fromJson(Map<String, dynamic>.from(rawAct));
    } else {
      act = const SessionActivitySummaryModel(id: '', title: 'Activity', domain: '', baseDifficulty: '');
    }

    SessionAnalysisResultModel? analysis;
    final rawAnalysis = json['analysisResult'] ?? json['AnalysisResult'];
    if (rawAnalysis is Map<String, dynamic>) {
      analysis = SessionAnalysisResultModel.fromJson(rawAnalysis);
    } else if (rawAnalysis is Map) {
      analysis = SessionAnalysisResultModel.fromJson(Map<String, dynamic>.from(rawAnalysis));
    }

    final metricList = <PerformanceMetricModel>[];
    final rawMetrics = json['metrics'] ?? json['Metrics'];
    if (rawMetrics is List) {
      for (final m in rawMetrics) {
        if (m is Map) {
          metricList.add(PerformanceMetricModel.fromJson(Map<String, dynamic>.from(m)));
        }
      }
    }

    return SessionDetailsModel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      childId: (json['childId'] ?? json['ChildId'] ?? '').toString(),
      activity: act,
      domain: (json['domain'] ?? json['Domain'] ?? '').toString(),
      status: (json['status'] ?? json['Status'] ?? '').toString(),
      startTimeUtc: parsedStart,
      endTimeUtc: parsedEnd,
      actualDurationSeconds: parsedDuration,
      analysisResult: analysis,
      metrics: metricList,
      parentRating: (json['parentRating'] ?? json['ParentRating'])?.toString(),
      parentNotes: (json['parentNotes'] ?? json['ParentNotes'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'childId': childId,
        'activity': activity.toJson(),
        'domain': domain,
        'status': status,
        'startTimeUtc': startTimeUtc.toIso8601String(),
        if (endTimeUtc != null) 'endTimeUtc': endTimeUtc!.toIso8601String(),
        if (actualDurationSeconds != null) 'actualDurationSeconds': actualDurationSeconds,
        if (analysisResult != null) 'analysisResult': analysisResult!.toJson(),
        'metrics': metrics.map((m) => m.toJson()).toList(),
        if (parentRating != null) 'parentRating': parentRating,
        if (parentNotes != null) 'parentNotes': parentNotes,
      };
}
