namespace Mindora.Application.Features.Sessions.Models;

public record CompletedSessionDto(
    Guid Id,
    Guid ChildId,
    Guid ActivityId,
    string Domain,
    string Status,
    DateTime StartTimeUtc,
    DateTime? EndTimeUtc,
    int? ActualDurationSeconds,
    SessionAnalysisResultDto? AnalysisResult,
    IReadOnlyList<PerformanceMetricDto> Metrics,
    string? ParentRating = null,
    string? ParentNotes = null);

public record SessionActivitySummaryDto(
    Guid Id,
    string Title,
    string Domain,
    string BaseDifficulty);

public record SessionDetailsDto(
    Guid Id,
    Guid ChildId,
    SessionActivitySummaryDto Activity,
    string Domain,
    string Status,
    DateTime StartTimeUtc,
    DateTime? EndTimeUtc,
    int? ActualDurationSeconds,
    SessionAnalysisResultDto? AnalysisResult,
    IReadOnlyList<PerformanceMetricDto> Metrics,
    string? ParentRating = null,
    string? ParentNotes = null);
