namespace Mindora.Application.Features.Sessions.Models;

public record PerformanceMetricDto(
    Guid Id,
    Guid SessionId,
    string MetricType,
    decimal Value,
    DateTime TimestampUtc);

public record MetricInputDto(
    string MetricType,
    decimal Value);
