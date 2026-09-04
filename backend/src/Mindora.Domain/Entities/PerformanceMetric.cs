using Mindora.Domain.Common;

namespace Mindora.Domain.Entities;

/// <summary>
/// Represents a fine-grained telemetry metric recorded during an activity session.
/// Uses decimal precision for predictable scoring and percentage calculations.
/// </summary>
public class PerformanceMetric : BaseEntity
{
    public Guid SessionId { get; private set; }
    public string MetricType { get; private set; } = string.Empty;
    public decimal Value { get; private set; }
    public DateTime TimestampUtc { get; private set; }

    // Parameterless constructor for ORM deserialization
    protected PerformanceMetric() : base()
    {
    }

    public PerformanceMetric(
        Guid id,
        Guid sessionId,
        string metricType,
        decimal value,
        DateTime? timestampUtc = null) : base(id)
    {
        if (sessionId == Guid.Empty)
        {
            throw new DomainException("SessionId cannot be empty for PerformanceMetric.");
        }

        if (string.IsNullOrWhiteSpace(metricType))
        {
            throw new DomainException("MetricType cannot be empty or whitespace.");
        }

        SessionId = sessionId;
        MetricType = metricType.Trim();
        Value = value;
        TimestampUtc = timestampUtc ?? DateTime.UtcNow;
    }

    public static PerformanceMetric Create(
        Guid sessionId,
        string metricType,
        decimal value,
        DateTime? timestampUtc = null)
    {
        return new PerformanceMetric(Guid.NewGuid(), sessionId, metricType, value, timestampUtc);
    }
}
