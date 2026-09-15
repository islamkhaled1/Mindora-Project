/// Strongly typed models for Baseline Assessment (التقييم الأولي لمستوى الأداء).
///
/// Strictly aligned with ASP.NET Core:
/// - Request: `Mindora.Application.Features.Assessments.RecordBaselineAssessment.RecordBaselineAssessmentRequest`
/// - Response: `Mindora.Application.Features.Assessments.Models.BaselineAssessmentDto`
///
/// All score fields are decimals in the range [0.0, 100.0].

/// Domains measured in the baseline performance assessment.
enum AssessmentDomain {
  motor('المهارات الحركية'),
  communication('مهارات التواصل'),
  cognitive('المهارات المعرفية والتركيز'),
  emotional('التفاعل الاجتماعي والتنظيم');

  final String arabicLabel;
  const AssessmentDomain(this.arabicLabel);
}

/// A selectable performance level option for a specific assessment task.
class AssessmentTaskOption {
  final String label;
  final double points; // 25.0, 50.0, 75.0, 100.0

  const AssessmentTaskOption({
    required this.label,
    required this.points,
  });
}

/// Definition of a supportive baseline performance task.
class AssessmentTask {
  final String id;
  final AssessmentDomain domain;
  final String title;
  final String description;
  final List<AssessmentTaskOption> options;

  const AssessmentTask({
    required this.id,
    required this.domain,
    required this.title,
    required this.description,
    required this.options,
  });
}

/// Request model mapping to ASP.NET Core `RecordBaselineAssessmentRequest`.
class RecordBaselineAssessmentRequest {
  final double overallScore;
  final double cognitiveScore;
  final double communicationScore;
  final double motorScore;
  final double emotionalScore;

  const RecordBaselineAssessmentRequest({
    required this.overallScore,
    required this.cognitiveScore,
    required this.communicationScore,
    required this.motorScore,
    required this.emotionalScore,
  });

  Map<String, dynamic> toJson() => {
        'overallScore': overallScore,
        'cognitiveScore': cognitiveScore,
        'communicationScore': communicationScore,
        'motorScore': motorScore,
        'emotionalScore': emotionalScore,
      };

  @override
  String toString() =>
      'RecordBaselineAssessmentRequest(overall: $overallScore, cog: $cognitiveScore, comm: $communicationScore, motor: $motorScore, emo: $emotionalScore)';
}

/// Response model mapping to ASP.NET Core `BaselineAssessmentDto`.
class BaselineAssessmentModel {
  final String id;
  final String childId;
  final double overallScore;
  final double cognitiveScore;
  final double communicationScore;
  final double motorScore;
  final double emotionalScore;
  final DateTime completedAtUtc;

  const BaselineAssessmentModel({
    required this.id,
    required this.childId,
    required this.overallScore,
    required this.cognitiveScore,
    required this.communicationScore,
    required this.motorScore,
    required this.emotionalScore,
    required this.completedAtUtc,
  });

  factory BaselineAssessmentModel.fromJson(Map<String, dynamic> json) {
    double parseDecimal(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) {
        return double.tryParse(val) ?? 0.0;
      }
      return 0.0;
    }

    final rawCompleted =
        json['completedAtUtc'] ?? json['CompletedAtUtc'];
    DateTime parsedCompleted = DateTime.now().toUtc();
    if (rawCompleted != null) {
      parsedCompleted =
          DateTime.tryParse(rawCompleted.toString())?.toUtc() ??
              DateTime.now().toUtc();
    }

    return BaselineAssessmentModel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      childId: (json['childId'] ?? json['ChildId'] ?? '').toString(),
      overallScore: parseDecimal(json['overallScore'] ?? json['OverallScore']),
      cognitiveScore:
          parseDecimal(json['cognitiveScore'] ?? json['CognitiveScore']),
      communicationScore: parseDecimal(
          json['communicationScore'] ?? json['CommunicationScore']),
      motorScore: parseDecimal(json['motorScore'] ?? json['MotorScore']),
      emotionalScore:
          parseDecimal(json['emotionalScore'] ?? json['EmotionalScore']),
      completedAtUtc: parsedCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'childId': childId,
        'overallScore': overallScore,
        'cognitiveScore': cognitiveScore,
        'communicationScore': communicationScore,
        'motorScore': motorScore,
        'emotionalScore': emotionalScore,
        'completedAtUtc': completedAtUtc.toIso8601String(),
      };

  @override
  String toString() =>
      'BaselineAssessmentModel(id: $id, childId: $childId, overallScore: $overallScore, completedAt: $completedAtUtc)';
}
