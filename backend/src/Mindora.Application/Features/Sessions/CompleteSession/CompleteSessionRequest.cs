using Mindora.Application.Features.Sessions.Models;

namespace Mindora.Application.Features.Sessions.CompleteSession;

public record CompleteSessionRequest(
    int ActualDurationSeconds,
    IReadOnlyList<MetricInputDto>? Metrics = null);
