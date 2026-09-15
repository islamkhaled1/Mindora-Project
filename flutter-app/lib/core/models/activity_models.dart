import 'package:flutter/material.dart';

/// Supported activity domains strictly aligned with ASP.NET Core `ActivityDomain`.
enum ActivityDomainEnum {
  movement('Movement', 'حركي', Icons.directions_run_rounded),
  speech('Speech', 'لغوي ونطق', Icons.record_voice_over_rounded),
  attention('Attention', 'انتباه وتركيز', Icons.psychology_rounded);

  final String backendValue;
  final String arabicLabel;
  final IconData icon;

  const ActivityDomainEnum(this.backendValue, this.arabicLabel, this.icon);

  static ActivityDomainEnum? fromString(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.trim().toLowerCase();
    for (final domain in ActivityDomainEnum.values) {
      if (domain.backendValue.toLowerCase() == normalized ||
          domain.name.toLowerCase() == normalized) {
        return domain;
      }
    }
    return null;
  }
}

/// Supported difficulty levels strictly aligned with ASP.NET Core `DifficultyLevel`.
enum ActivityDifficultyEnum {
  beginner('Beginner', 'مبتدئ'),
  intermediate('Intermediate', 'متوسط'),
  advanced('Advanced', 'متقدم');

  final String backendValue;
  final String arabicLabel;

  const ActivityDifficultyEnum(this.backendValue, this.arabicLabel);

  static ActivityDifficultyEnum? fromString(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.trim().toLowerCase();
    for (final diff in ActivityDifficultyEnum.values) {
      if (diff.backendValue.toLowerCase() == normalized ||
          diff.name.toLowerCase() == normalized) {
        return diff;
      }
    }
    return null;
  }
}

/// Strongly typed model mapping strictly to ASP.NET Core `ActivityDto`.
class ActivityModel {
  final String id;
  final String title;
  final String description;
  final String domain;
  final String baseDifficulty;
  final String? adaptiveSettingsJson;
  final DateTime? createdAtUtc;

  const ActivityModel({
    required this.id,
    required this.title,
    required this.description,
    required this.domain,
    required this.baseDifficulty,
    this.adaptiveSettingsJson,
    this.createdAtUtc,
  });

  ActivityDomainEnum? get domainEnum => ActivityDomainEnum.fromString(domain);
  ActivityDifficultyEnum? get difficultyEnum =>
      ActivityDifficultyEnum.fromString(baseDifficulty);

  String get domainArabicLabel =>
      domainEnum?.arabicLabel ?? (domain.isNotEmpty ? domain : 'غير محدد');

  String get difficultyArabicLabel =>
      difficultyEnum?.arabicLabel ??
      (baseDifficulty.isNotEmpty ? baseDifficulty : 'غير محدد');

  IconData get domainIcon =>
      domainEnum?.icon ?? Icons.sports_esports_rounded;

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    final rawCreated = json['createdAtUtc'] ?? json['CreatedAtUtc'];
    DateTime? parsedCreated;
    if (rawCreated != null) {
      parsedCreated = DateTime.tryParse(rawCreated.toString());
    }

    return ActivityModel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      title: (json['title'] ?? json['Title'] ?? '').toString(),
      description:
          (json['description'] ?? json['Description'] ?? '').toString(),
      domain: (json['domain'] ?? json['Domain'] ?? '').toString(),
      baseDifficulty: (json['baseDifficulty'] ??
              json['BaseDifficulty'] ??
              '')
          .toString(),
      adaptiveSettingsJson:
          json['adaptiveSettingsJson'] ?? json['AdaptiveSettingsJson'],
      createdAtUtc: parsedCreated,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'domain': domain,
        'baseDifficulty': baseDifficulty,
        if (adaptiveSettingsJson != null)
          'adaptiveSettingsJson': adaptiveSettingsJson,
        if (createdAtUtc != null)
          'createdAtUtc': createdAtUtc!.toIso8601String(),
      };
}

/// Strongly typed model mapping strictly to ASP.NET Core `ActivityPerformanceDto`.
class ActivityPerformanceModel {
  final String activityId;
  final String activityTitle;
  final String domain;
  final String baseDifficulty;
  final int timesPlayed;
  final int totalPracticeMinutes;
  final double averageScore;
  final double bestScore;
  final double latestScore;
  final double? averageAccuracyPercentage;
  final double? averageReactionTimeMs;
  final double? averageRepetitions;
  final DateTime? lastPlayedUtc;

  const ActivityPerformanceModel({
    required this.activityId,
    required this.activityTitle,
    required this.domain,
    required this.baseDifficulty,
    required this.timesPlayed,
    required this.totalPracticeMinutes,
    required this.averageScore,
    required this.bestScore,
    required this.latestScore,
    this.averageAccuracyPercentage,
    this.averageReactionTimeMs,
    this.averageRepetitions,
    this.lastPlayedUtc,
  });

  ActivityDomainEnum? get domainEnum => ActivityDomainEnum.fromString(domain);
  ActivityDifficultyEnum? get difficultyEnum =>
      ActivityDifficultyEnum.fromString(baseDifficulty);

  String get domainArabicLabel =>
      domainEnum?.arabicLabel ?? (domain.isNotEmpty ? domain : 'غير محدد');

  String get difficultyArabicLabel =>
      difficultyEnum?.arabicLabel ??
      (baseDifficulty.isNotEmpty ? baseDifficulty : 'غير محدد');

  factory ActivityPerformanceModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val, [double defaultVal = 0.0]) {
      if (val is num) return val.toDouble();
      if (val is String) {
        return double.tryParse(val) ?? defaultVal;
      }
      return defaultVal;
    }

    double? parseNullableDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    int parseInt(dynamic val) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    final rawLastPlayed = json['lastPlayedUtc'] ?? json['LastPlayedUtc'];
    DateTime? parsedLastPlayed;
    if (rawLastPlayed != null) {
      parsedLastPlayed = DateTime.tryParse(rawLastPlayed.toString());
    }

    return ActivityPerformanceModel(
      activityId:
          (json['activityId'] ?? json['ActivityId'] ?? '').toString(),
      activityTitle:
          (json['activityTitle'] ?? json['ActivityTitle'] ?? '').toString(),
      domain: (json['domain'] ?? json['Domain'] ?? '').toString(),
      baseDifficulty: (json['baseDifficulty'] ??
              json['BaseDifficulty'] ??
              '')
          .toString(),
      timesPlayed: parseInt(json['timesPlayed'] ?? json['TimesPlayed']),
      totalPracticeMinutes: parseInt(
          json['totalPracticeMinutes'] ?? json['TotalPracticeMinutes']),
      averageScore:
          parseDouble(json['averageScore'] ?? json['AverageScore']),
      bestScore: parseDouble(json['bestScore'] ?? json['BestScore']),
      latestScore: parseDouble(json['latestScore'] ?? json['LatestScore']),
      averageAccuracyPercentage: parseNullableDouble(
          json['averageAccuracyPercentage'] ??
              json['AverageAccuracyPercentage']),
      averageReactionTimeMs: parseNullableDouble(
          json['averageReactionTimeMs'] ?? json['AverageReactionTimeMs']),
      averageRepetitions: parseNullableDouble(
          json['averageRepetitions'] ?? json['AverageRepetitions']),
      lastPlayedUtc: parsedLastPlayed,
    );
  }

  Map<String, dynamic> toJson() => {
        'activityId': activityId,
        'activityTitle': activityTitle,
        'domain': domain,
        'baseDifficulty': baseDifficulty,
        'timesPlayed': timesPlayed,
        'totalPracticeMinutes': totalPracticeMinutes,
        'averageScore': averageScore,
        'bestScore': bestScore,
        'latestScore': latestScore,
        if (averageAccuracyPercentage != null)
          'averageAccuracyPercentage': averageAccuracyPercentage,
        if (averageReactionTimeMs != null)
          'averageReactionTimeMs': averageReactionTimeMs,
        if (averageRepetitions != null)
          'averageRepetitions': averageRepetitions,
        if (lastPlayedUtc != null)
          'lastPlayedUtc': lastPlayedUtc!.toIso8601String(),
      };
}
