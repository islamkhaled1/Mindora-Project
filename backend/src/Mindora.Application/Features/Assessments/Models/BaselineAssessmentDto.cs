namespace Mindora.Application.Features.Assessments.Models;

public record BaselineAssessmentDto(
    Guid Id,
    Guid ChildId,
    decimal OverallScore,
    decimal CognitiveScore,
    decimal CommunicationScore,
    decimal MotorScore,
    decimal EmotionalScore,
    DateTime CompletedAtUtc);
