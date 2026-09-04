using Mindora.Domain.Enums;

namespace Mindora.Application.Common.Models;

/// <summary>
/// Result produced by the AI performance analysis abstraction.
/// Focuses on activity performance evaluation, adaptive difficulty, and supportive observations.
/// Does not represent medical diagnosis or clinical prescription.
/// </summary>
public class AiSessionAnalysisResult
{
    public const decimal MinScore = 0.00m;
    public const decimal MaxScore = 100.00m;

    public decimal OverallPerformanceScore { get; }
    public decimal DomainScore { get; }
    public string SupportiveObservations { get; }
    public bool FatigueObserved { get; }
    public DifficultyAdjustment RecommendedDifficultyAdjustment { get; }
    public string? AdaptiveParameters { get; }
    public bool IsFallbackResult { get; }

    public AiSessionAnalysisResult(
        decimal overallPerformanceScore,
        decimal domainScore,
        string supportiveObservations,
        bool fatigueObserved,
        DifficultyAdjustment recommendedDifficultyAdjustment,
        string? adaptiveParameters = null,
        bool isFallbackResult = false)
    {
        if (overallPerformanceScore < MinScore || overallPerformanceScore > MaxScore)
        {
            throw new ArgumentOutOfRangeException(
                nameof(overallPerformanceScore),
                overallPerformanceScore,
                $"OverallPerformanceScore must be between {MinScore:F2} and {MaxScore:F2}.");
        }

        if (domainScore < MinScore || domainScore > MaxScore)
        {
            throw new ArgumentOutOfRangeException(
                nameof(domainScore),
                domainScore,
                $"DomainScore must be between {MinScore:F2} and {MaxScore:F2}.");
        }

        if (string.IsNullOrWhiteSpace(supportiveObservations))
        {
            throw new ArgumentException("SupportiveObservations cannot be empty or whitespace.", nameof(supportiveObservations));
        }

        OverallPerformanceScore = overallPerformanceScore;
        DomainScore = domainScore;
        SupportiveObservations = supportiveObservations.Trim();
        FatigueObserved = fatigueObserved;
        RecommendedDifficultyAdjustment = recommendedDifficultyAdjustment;
        AdaptiveParameters = adaptiveParameters;
        IsFallbackResult = isFallbackResult;
    }
}
