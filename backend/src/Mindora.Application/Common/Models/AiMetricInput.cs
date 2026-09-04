namespace Mindora.Application.Common.Models;

/// <summary>
/// Telemetry metric input passed to the AI analysis contract.
/// </summary>
public record AiMetricInput(
    string MetricType,
    decimal Value,
    DateTime TimestampUtc);
