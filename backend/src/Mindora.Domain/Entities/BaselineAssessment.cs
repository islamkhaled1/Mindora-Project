using Mindora.Domain.Common;

namespace Mindora.Domain.Entities;

/// <summary>
/// Represents the initial holistic AI intake assessment across 4 developmental domains.
/// Evaluated during child onboarding before individualized daily activities begin.
/// </summary>
public class BaselineAssessment : BaseEntity
{
    public Guid ChildId { get; private set; }
    public decimal OverallScore { get; private set; }
    public decimal CognitiveScore { get; private set; }
    public decimal CommunicationScore { get; private set; }
    public decimal MotorScore { get; private set; }
    public decimal EmotionalScore { get; private set; }
    public DateTime CompletedAtUtc { get; private set; }

    // Parameterless constructor for ORM deserialization
    protected BaselineAssessment() : base()
    {
    }

    public BaselineAssessment(
        Guid id,
        Guid childId,
        decimal overallScore,
        decimal cognitiveScore,
        decimal communicationScore,
        decimal motorScore,
        decimal emotionalScore,
        DateTime? completedAtUtc = null) : base(id)
    {
        if (childId == Guid.Empty)
        {
            throw new DomainException("ChildId cannot be empty for BaselineAssessment.");
        }

        ValidateScore("OverallScore", overallScore);
        ValidateScore("CognitiveScore", cognitiveScore);
        ValidateScore("CommunicationScore", communicationScore);
        ValidateScore("MotorScore", motorScore);
        ValidateScore("EmotionalScore", emotionalScore);

        ChildId = childId;
        OverallScore = overallScore;
        CognitiveScore = cognitiveScore;
        CommunicationScore = communicationScore;
        MotorScore = motorScore;
        EmotionalScore = emotionalScore;
        CompletedAtUtc = completedAtUtc ?? DateTime.UtcNow;
    }

    public static BaselineAssessment Create(
        Guid childId,
        decimal overallScore,
        decimal cognitiveScore,
        decimal communicationScore,
        decimal motorScore,
        decimal emotionalScore,
        DateTime? completedAtUtc = null)
    {
        return new BaselineAssessment(
            Guid.NewGuid(),
            childId,
            overallScore,
            cognitiveScore,
            communicationScore,
            motorScore,
            emotionalScore,
            completedAtUtc);
    }

    private static void ValidateScore(string scoreName, decimal score)
    {
        if (score < 0m || score > 100m)
        {
            throw new DomainException($"{scoreName} must be between 0 and 100.");
        }
    }
}
