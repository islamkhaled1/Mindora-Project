using Mindora.Application.Features.Sessions.Models;

namespace Mindora.Application.Features.Sessions.RecordMetrics;

public record RecordMetricsRequest(
    IReadOnlyList<MetricInputDto> Metrics);
