namespace Mindora.Application.Features.Assessments.RecordBaselineAssessment;

public record RecordBaselineAssessmentRequest(
    decimal OverallScore,
    decimal CognitiveScore,
    decimal CommunicationScore,
    decimal MotorScore,
    decimal EmotionalScore);
