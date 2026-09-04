namespace Mindora.Application.Features.Sessions.Models;

public record SessionAnalysisResultDto(
    Guid Id,
    Guid SessionId,
    decimal OverallPerformanceScore,
    decimal DomainScore,
    string SupportiveObservations,
    bool FatigueObserved,
    string RecommendedDifficultyAdjustment,
    string? AdaptiveParametersJson,
    DateTime AnalyzedAtUtc,
    bool IsFallbackResult);
