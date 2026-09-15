import 'package:flutter/material.dart';
import '../models/activity_models.dart';

// Re-export ActivityPerformanceModel and activity enums for convenient single-import use in progress contexts
export '../models/activity_models.dart'
    show ActivityPerformanceModel, ActivityDomainEnum, ActivityDifficultyEnum;

/// Performance trend indicator strictly aligned with ASP.NET Core `ProgressTrend`.
enum PerformanceTrendEnum {
  improving('Improving', 'في تحسن مستمر', Icons.trending_up_rounded, Color(0xff2E7D32), Color(0xffE8F5E9)),
  steady('Steady', 'أداء مستقر', Icons.trending_flat_rounded, Color(0xff1976D2), Color(0xffE3F2FD)),
  needsSupport('NeedsSupport', 'يحتاج دعمًا إضافيًا', Icons.trending_down_rounded, Color(0xffE65100), Color(0xffFFF3E0));

  final String backendValue;
  final String arabicLabel;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const PerformanceTrendEnum(
    this.backendValue,
    this.arabicLabel,
    this.icon,
    this.color,
    this.bgColor,
  );

  static PerformanceTrendEnum? fromString(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.trim().toLowerCase();
    for (final trend in PerformanceTrendEnum.values) {
      if (trend.backendValue.toLowerCase() == normalized ||
          trend.name.toLowerCase() == normalized) {
        return trend;
      }
    }
    return null;
  }
}

/// Strongly typed model mapping strictly to ASP.NET Core `DomainProgressDto`.
class DomainProgressModel {
  final String domain;
  final int completedSessions;
  final double averageScore;
  final double latestScore;
  final String trend;

  const DomainProgressModel({
    required this.domain,
    required this.completedSessions,
    required this.averageScore,
    required this.latestScore,
    required this.trend,
  });

  ActivityDomainEnum? get domainEnum => ActivityDomainEnum.fromString(domain);
  PerformanceTrendEnum? get trendEnum => PerformanceTrendEnum.fromString(trend);

  String get domainArabicLabel =>
      domainEnum?.arabicLabel ?? (domain.isNotEmpty ? domain : 'غير محدد');

  IconData get domainIcon =>
      domainEnum?.icon ?? Icons.sports_esports_rounded;

  factory DomainProgressModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val, [double defaultVal = 0.0]) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? defaultVal;
      return defaultVal;
    }

    int parseInt(dynamic val, [int defaultVal = 0]) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? defaultVal;
      return defaultVal;
    }

    return DomainProgressModel(
      domain: (json['domain'] ?? json['Domain'] ?? '').toString(),
      completedSessions:
          parseInt(json['completedSessions'] ?? json['CompletedSessions']),
      averageScore:
          parseDouble(json['averageScore'] ?? json['AverageScore']),
      latestScore:
          parseDouble(json['latestScore'] ?? json['LatestScore']),
      trend: (json['trend'] ?? json['Trend'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'domain': domain,
        'completedSessions': completedSessions,
        'averageScore': averageScore,
        'latestScore': latestScore,
        'trend': trend,
      };
}

/// Strongly typed model mapping strictly to ASP.NET Core `ChildProgressSummaryDto`.
class ChildProgressSummaryModel {
  final String childId;
  final int totalCompletedSessions;
  final int totalPracticeMinutes;
  final double overallAverageScore;
  final int currentStreakDays;
  final String recentPerformanceTrend;
  final List<DomainProgressModel> domainSummaries;

  const ChildProgressSummaryModel({
    required this.childId,
    required this.totalCompletedSessions,
    required this.totalPracticeMinutes,
    required this.overallAverageScore,
    required this.currentStreakDays,
    required this.recentPerformanceTrend,
    required this.domainSummaries,
  });

  PerformanceTrendEnum? get trendEnum =>
      PerformanceTrendEnum.fromString(recentPerformanceTrend);

  factory ChildProgressSummaryModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val, [double defaultVal = 0.0]) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? defaultVal;
      return defaultVal;
    }

    int parseInt(dynamic val, [int defaultVal = 0]) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? defaultVal;
      return defaultVal;
    }

    final rawDomains =
        json['domainSummaries'] ?? json['DomainSummaries'];
    List<DomainProgressModel> domains = [];
    if (rawDomains is List) {
      domains = rawDomains
          .map((item) => DomainProgressModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList();
    }

    return ChildProgressSummaryModel(
      childId: (json['childId'] ?? json['ChildId'] ?? '').toString(),
      totalCompletedSessions: parseInt(
          json['totalCompletedSessions'] ?? json['TotalCompletedSessions']),
      totalPracticeMinutes: parseInt(
          json['totalPracticeMinutes'] ?? json['TotalPracticeMinutes']),
      overallAverageScore: parseDouble(
          json['overallAverageScore'] ?? json['OverallAverageScore']),
      currentStreakDays: parseInt(
          json['currentStreakDays'] ?? json['CurrentStreakDays']),
      recentPerformanceTrend: (json['recentPerformanceTrend'] ??
              json['RecentPerformanceTrend'] ??
              '')
          .toString(),
      domainSummaries: domains,
    );
  }

  Map<String, dynamic> toJson() => {
        'childId': childId,
        'totalCompletedSessions': totalCompletedSessions,
        'totalPracticeMinutes': totalPracticeMinutes,
        'overallAverageScore': overallAverageScore,
        'currentStreakDays': currentStreakDays,
        'recentPerformanceTrend': recentPerformanceTrend,
        'domainSummaries': domainSummaries.map((d) => d.toJson()).toList(),
      };
}

/// Strongly typed model mapping strictly to ASP.NET Core `SessionHistoryPointDto`.
class SessionHistoryPointModel {
  final String sessionId;
  final String activityTitle;
  final String domain;
  final double score;
  final int durationSeconds;
  final DateTime completedAtUtc;

  const SessionHistoryPointModel({
    required this.sessionId,
    required this.activityTitle,
    required this.domain,
    required this.score,
    required this.durationSeconds,
    required this.completedAtUtc,
  });

  ActivityDomainEnum? get domainEnum => ActivityDomainEnum.fromString(domain);

  String get domainArabicLabel =>
      domainEnum?.arabicLabel ?? (domain.isNotEmpty ? domain : 'غير محدد');

  IconData get domainIcon =>
      domainEnum?.icon ?? Icons.sports_esports_rounded;

  factory SessionHistoryPointModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val, [double defaultVal = 0.0]) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? defaultVal;
      return defaultVal;
    }

    int parseInt(dynamic val, [int defaultVal = 0]) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? defaultVal;
      return defaultVal;
    }

    final rawCompleted =
        json['completedAtUtc'] ?? json['CompletedAtUtc'];
    DateTime parsedCompleted = DateTime.now().toUtc();
    if (rawCompleted != null) {
      final parsed = DateTime.tryParse(rawCompleted.toString());
      if (parsed != null) parsedCompleted = parsed;
    }

    return SessionHistoryPointModel(
      sessionId:
          (json['sessionId'] ?? json['SessionId'] ?? '').toString(),
      activityTitle:
          (json['activityTitle'] ?? json['ActivityTitle'] ?? '').toString(),
      domain: (json['domain'] ?? json['Domain'] ?? '').toString(),
      score: parseDouble(json['score'] ?? json['Score']),
      durationSeconds:
          parseInt(json['durationSeconds'] ?? json['DurationSeconds']),
      completedAtUtc: parsedCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'activityTitle': activityTitle,
        'domain': domain,
        'score': score,
        'durationSeconds': durationSeconds,
        'completedAtUtc': completedAtUtc.toIso8601String(),
      };
}

/// Formatting helper utilities strictly for non-destructive UI presentation.
class ProgressFormatters {
  ProgressFormatters._();

  /// Formats practice minutes into localized Arabic duration.
  /// Examples:
  /// - 45 -> "45 دقيقة"
  /// - 60 -> "ساعة واحدة"
  /// - 75 -> "ساعة و 15 دقيقة"
  /// - 120 -> "2 ساعة"
  static String formatPracticeMinutes(int minutes) {
    if (minutes <= 0) return '0 دقيقة';
    if (minutes < 60) return '$minutes دقيقة';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    String hoursPart;
    if (hours == 1) {
      hoursPart = 'ساعة واحدة';
    } else if (hours == 2) {
      hoursPart = 'ساعتان';
    } else if (hours >= 3 && hours <= 10) {
      hoursPart = '$hours ساعات';
    } else {
      hoursPart = '$hours ساعة';
    }

    if (remainingMinutes == 0) {
      return hoursPart;
    }

    return '$hoursPart و $remainingMinutes دقيقة';
  }

  /// Formats duration seconds into localized Arabic duration.
  /// Examples:
  /// - 45 -> "45 ثانية"
  /// - 60 -> "دقيقة واحدة"
  /// - 90 -> "دقيقة و 30 ثانية"
  /// - 130 -> "2 دقيقة و 10 ثوانٍ"
  static String formatDurationSeconds(int totalSeconds) {
    if (totalSeconds <= 0) return '0 ثانية';
    if (totalSeconds < 60) return '$totalSeconds ثانية';
    final minutes = totalSeconds ~/ 60;
    final remainingSecs = totalSeconds % 60;

    String minsPart;
    if (minutes == 1) {
      minsPart = 'دقيقة واحدة';
    } else if (minutes == 2) {
      minsPart = 'دقيقتان';
    } else if (minutes >= 3 && minutes <= 10) {
      minsPart = '$minutes دقائق';
    } else {
      minsPart = '$minutes دقيقة';
    }

    if (remainingSecs == 0) {
      return minsPart;
    }

    String secsPart;
    if (remainingSecs >= 3 && remainingSecs <= 10) {
      secsPart = '$remainingSecs ثوانٍ';
    } else {
      secsPart = '$remainingSecs ثانية';
    }

    return '$minsPart و $secsPart';
  }

  /// Formats UTC DateTime to Arabic localized readable date/time.
  static String formatCompletedDate(DateTime dateTimeUtc) {
    final local = dateTimeUtc.toLocal();
    final year = local.year;
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour > 12
        ? local.hour - 12
        : (local.hour == 0 ? 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'م' : 'ص';

    return '$year/$month/$day $hour:$minute $period';
  }
}
