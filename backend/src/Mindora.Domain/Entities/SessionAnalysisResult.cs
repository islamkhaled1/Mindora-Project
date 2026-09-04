using Mindora.Domain.Common;
using Mindora.Domain.Enums;

namespace Mindora.Domain.Entities;

/// <summary>
/// Represents the analyzed outcome of an activity session.
/// Focuses on activity performance evaluation, adaptive difficulty, and supportive observations.
/// Does not represent clinical diagnosis, medical decisions, or medical prescriptions.
/// </summary>
public class SessionAnalysisResult : BaseEntity
{
    public const decimal MinScore = 0.00m;
    public const decimal MaxScore = 100.00m;

    public Guid SessionId { get; private set; }
    public decimal OverallPerformanceScore { get; private set; }
    public decimal DomainScore { get; private set; }
    public string SupportiveObservations { get; private set; } = string.Empty;
    public bool FatigueObserved { get; private set; }
    public DifficultyAdjustment RecommendedDifficultyAdjustment { get; private set; }
    public string? AdaptiveParametersJson { get; private set; }
    public DateTime AnalyzedAtUtc { get; private set; }
    public bool IsFallbackResult { get; private set; }

    // Parameterless constructor for ORM deserialization
    protected SessionAnalysisResult() : base()
    {
    }

    public SessionAnalysisResult(
        Guid id,
        Guid sessionId,
        decimal overallPerformanceScore,
        decimal domainScore,
        string supportiveObservations,
        bool fatigueObserved,
        DifficultyAdjustment recommendedDifficultyAdjustment,
        string? adaptiveParametersJson = null,
        DateTime? analyzedAtUtc = null,
        bool isFallbackResult = false) : base(id)
    {
        if (sessionId == Guid.Empty)
        {
            throw new DomainException("SessionId cannot be empty for SessionAnalysisResult.");
        }

        ValidateScore(overallPerformanceScore, nameof(OverallPerformanceScore));
        ValidateScore(domainScore, nameof(DomainScore));

        if (string.IsNullOrWhiteSpace(supportiveObservations))
        {
            throw new DomainException("SupportiveObservations cannot be empty or whitespace.");
        }

        SessionId = sessionId;
        OverallPerformanceScore = overallPerformanceScore;
        DomainScore = domainScore;
        SupportiveObservations = supportiveObservations.Trim();
        FatigueObserved = fatigueObserved;
        RecommendedDifficultyAdjustment = recommendedDifficultyAdjustment;
        AdaptiveParametersJson = adaptiveParametersJson;
        AnalyzedAtUtc = analyzedAtUtc ?? DateTime.UtcNow;
        IsFallbackResult = isFallbackResult;
    }

    public static SessionAnalysisResult Create(
        Guid sessionId,
        decimal overallPerformanceScore,
        decimal domainScore,
        string supportiveObservations,
        bool fatigueObserved,
        DifficultyAdjustment recommendedDifficultyAdjustment,
        string? adaptiveParametersJson = null,
        DateTime? analyzedAtUtc = null,
        bool isFallbackResult = false)
    {
        return new SessionAnalysisResult(
            Guid.NewGuid(),
            sessionId,
            overallPerformanceScore,
            domainScore,
            supportiveObservations,
            fatigueObserved,
            recommendedDifficultyAdjustment,
            adaptiveParametersJson,
            analyzedAtUtc,
            isFallbackResult);
    }

    private static void ValidateScore(decimal score, string paramName)
    {
        if (score < MinScore || score > MaxScore)
        {
            throw new DomainException($"{paramName} must be between {MinScore:F2} and {MaxScore:F2}. Actual: {score}.");
        }
    }
}
