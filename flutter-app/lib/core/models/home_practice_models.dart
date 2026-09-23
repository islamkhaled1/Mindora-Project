/// Dart models mapping strictly to the backend HomePracticeRecommendationDto response.
///
/// IsPreliminary is always true — these are preliminary home-practice suggestions,
/// not a medical treatment plan or clinical prescription.

class HomePracticeRecommendationModel {
  final String childId;
  final double overallScore;
  final List<DomainProfileModel> strengths;
  final List<DomainProfileModel> focusAreas;
  final List<RecommendedActivityModel> recommendedActivities;
  final bool isPreliminary;
  final String disclaimer;
  final DateTime generatedAtUtc;

  const HomePracticeRecommendationModel({
    required this.childId,
    required this.overallScore,
    required this.strengths,
    required this.focusAreas,
    required this.recommendedActivities,
    required this.isPreliminary,
    required this.disclaimer,
    required this.generatedAtUtc,
  });

  factory HomePracticeRecommendationModel.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(
      dynamic raw,
      T Function(Map<String, dynamic>) fromJson,
    ) {
      if (raw == null) return <T>[];
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((e) => fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return <T>[];
    }

    return HomePracticeRecommendationModel(
      childId: (json['childId'] ?? json['ChildId'] ?? '').toString(),
      overallScore: _parseDouble(json['overallScore'] ?? json['OverallScore']),
      strengths: parseList(
        json['strengths'] ?? json['Strengths'],
        DomainProfileModel.fromJson,
      ),
      focusAreas: parseList(
        json['focusAreas'] ?? json['FocusAreas'],
        DomainProfileModel.fromJson,
      ),
      recommendedActivities: parseList(
        json['recommendedActivities'] ?? json['RecommendedActivities'],
        RecommendedActivityModel.fromJson,
      ),
      isPreliminary:
          (json['isPreliminary'] ?? json['IsPreliminary'] ?? true) as bool,
      disclaimer:
          (json['disclaimer'] ?? json['Disclaimer'] ?? '').toString(),
      generatedAtUtc: DateTime.tryParse(
            (json['generatedAtUtc'] ?? json['GeneratedAtUtc'] ?? '').toString(),
          ) ??
          DateTime.now(),
    );
  }

  static double _parseDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  /// True if there are no mapped focus areas with activity recommendations.
  bool get hasRecommendations => recommendedActivities.isNotEmpty;
}

/// Represents one assessment domain in the child's preliminary performance profile.
/// All four domains appear here (Motor, Communication, Cognitive, Emotional).
/// [hasActivityMapping] is false for Emotional.
class DomainProfileModel {
  final String assessmentDomain;
  final String assessmentDomainArabic;
  final double score;

  /// UI display label — "قوة واضحة" | "مستوى متوسط" | "مجال للتركيز"
  final String level;

  /// False for Emotional (no activity catalog domain exists yet).
  final bool hasActivityMapping;

  const DomainProfileModel({
    required this.assessmentDomain,
    required this.assessmentDomainArabic,
    required this.score,
    required this.level,
    required this.hasActivityMapping,
  });

  factory DomainProfileModel.fromJson(Map<String, dynamic> json) {
    return DomainProfileModel(
      assessmentDomain:
          (json['assessmentDomain'] ?? json['AssessmentDomain'] ?? '').toString(),
      assessmentDomainArabic:
          (json['assessmentDomainArabic'] ?? json['AssessmentDomainArabic'] ?? '').toString(),
      score: HomePracticeRecommendationModel._parseDouble(
        json['score'] ?? json['Score'],
      ),
      level: (json['level'] ?? json['Level'] ?? '').toString(),
      hasActivityMapping:
          (json['hasActivityMapping'] ?? json['HasActivityMapping'] ?? false) as bool,
    );
  }
}

/// A single recommended home-practice activity.
/// Only created for Motor/Communication/Cognitive — never for Emotional.
class RecommendedActivityModel {
  final String activityId;
  final String title;
  final String description;

  /// Backend ActivityDomain value: "Movement" | "Speech" | "Attention"
  final String activityDomain;

  /// Arabic display label for the activity domain.
  final String activityDomainArabic;

  /// Assessment domain that triggered this recommendation: "Motor" | "Communication" | "Cognitive"
  final String assessmentDomain;

  /// "Beginner" | "Intermediate" | "Advanced"
  final String baseDifficulty;
  final String baseDifficultyArabic;

  /// "High" (focus area) | "Low" (strength maintenance)
  final String priority;
  final String priorityArabic;

  /// Plain Arabic product-logic rationale. Not a clinical claim.
  final String reason;

  /// Configurable product heuristic — e.g. "٣ مرات أسبوعياً"
  final String suggestedPracticeFrequency;

  final bool isPreliminary;

  const RecommendedActivityModel({
    required this.activityId,
    required this.title,
    required this.description,
    required this.activityDomain,
    required this.activityDomainArabic,
    required this.assessmentDomain,
    required this.baseDifficulty,
    required this.baseDifficultyArabic,
    required this.priority,
    required this.priorityArabic,
    required this.reason,
    required this.suggestedPracticeFrequency,
    required this.isPreliminary,
  });

  factory RecommendedActivityModel.fromJson(Map<String, dynamic> json) {
    return RecommendedActivityModel(
      activityId:
          (json['activityId'] ?? json['ActivityId'] ?? '').toString(),
      title: (json['title'] ?? json['Title'] ?? '').toString(),
      description:
          (json['description'] ?? json['Description'] ?? '').toString(),
      activityDomain:
          (json['activityDomain'] ?? json['ActivityDomain'] ?? '').toString(),
      activityDomainArabic:
          (json['activityDomainArabic'] ?? json['ActivityDomainArabic'] ?? '').toString(),
      assessmentDomain:
          (json['assessmentDomain'] ?? json['AssessmentDomain'] ?? '').toString(),
      baseDifficulty:
          (json['baseDifficulty'] ?? json['BaseDifficulty'] ?? '').toString(),
      baseDifficultyArabic:
          (json['baseDifficultyArabic'] ?? json['BaseDifficultyArabic'] ?? '').toString(),
      priority: (json['priority'] ?? json['Priority'] ?? '').toString(),
      priorityArabic:
          (json['priorityArabic'] ?? json['PriorityArabic'] ?? '').toString(),
      reason: (json['reason'] ?? json['Reason'] ?? '').toString(),
      suggestedPracticeFrequency:
          (json['suggestedPracticeFrequency'] ?? json['SuggestedPracticeFrequency'] ?? '').toString(),
      isPreliminary:
          (json['isPreliminary'] ?? json['IsPreliminary'] ?? true) as bool,
    );
  }

  bool get isHighPriority => priority == 'High';
}
