namespace Mindora.Application.Features.Progress.Models;

public record DomainProgressDto(
    string Domain,
    int CompletedSessions,
    decimal AverageScore,
    decimal LatestScore,
    string Trend);

public record ChildProgressSummaryDto(
    Guid ChildId,
    int TotalCompletedSessions,
    int TotalPracticeMinutes,
    decimal OverallAverageScore,
    int CurrentStreakDays,
    string RecentPerformanceTrend,
    IReadOnlyList<DomainProgressDto> DomainSummaries);

public record SessionHistoryPointDto(
    Guid SessionId,
    string ActivityTitle,
    string Domain,
    decimal Score,
    int DurationSeconds,
    DateTime CompletedAtUtc);
