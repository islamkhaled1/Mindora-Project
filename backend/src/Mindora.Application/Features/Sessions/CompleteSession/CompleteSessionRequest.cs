using Mindora.Application.Features.Sessions.Models;
using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Sessions.CompleteSession;

public record CompleteSessionRequest(
    int ActualDurationSeconds,
    IReadOnlyList<MetricInputDto>? Metrics = null,
    ParentSentimentRating? ParentRating = null,
    string? ParentNotes = null);
