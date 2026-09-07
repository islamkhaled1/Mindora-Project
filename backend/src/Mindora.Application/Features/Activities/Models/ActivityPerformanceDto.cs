namespace Mindora.Application.Features.Activities.Models;

public record ActivityPerformanceDto(
    Guid ActivityId,
    string ActivityTitle,
    string Domain,
    string BaseDifficulty,
    int TimesPlayed,
    int TotalPracticeMinutes,
    decimal AverageScore,
    decimal BestScore,
    decimal LatestScore,
    decimal? AverageAccuracyPercentage,
    decimal? AverageReactionTimeMs,
    decimal? AverageRepetitions,
    DateTime LastPlayedUtc);
