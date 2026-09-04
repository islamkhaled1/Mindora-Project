using Mindora.Domain.Common;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;
using Xunit;

namespace Mindora.UnitTests.Domain;

public class SessionMetricsTests
{
    private readonly Guid _childId = Guid.NewGuid();
    private readonly Guid _activityId = Guid.NewGuid();

    [Fact]
    public void Metrics_Can_Be_Added_While_Session_Is_Started()
    {
        // Arrange
        var session = Session.Start(_childId, _activityId, ActivityDomain.Movement);

        // Act
        var metric1 = session.AddMetric("RepetitionCount", 10.00m);
        var metric2 = session.AddMetric("AccuracyPercentage", 92.50m);

        // Assert
        Assert.Equal(2, session.Metrics.Count);
        Assert.Contains(metric1, session.Metrics);
        Assert.Contains(metric2, session.Metrics);
        Assert.Equal(10.00m, metric1.Value);
        Assert.Equal(92.50m, metric2.Value);
    }

    [Fact]
    public void Metrics_Cannot_Be_Added_After_Session_Completion()
    {
        // Arrange
        var session = Session.Start(_childId, _activityId, ActivityDomain.Speech, DateTime.UtcNow.AddMinutes(-5));
        session.Complete(DateTime.UtcNow);

        // Act & Assert
        var ex = Assert.Throws<DomainException>(() => session.AddMetric("SpeechClarityScore", 80.00m));
        Assert.Contains("Metrics may only be added while the session is Started", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Metrics_Cannot_Be_Added_After_Session_Abandonment()
    {
        // Arrange
        var session = Session.Start(_childId, _activityId, ActivityDomain.Attention, DateTime.UtcNow.AddMinutes(-5));
        session.Abandon(DateTime.UtcNow);

        // Act & Assert
        var ex = Assert.Throws<DomainException>(() => session.AddMetric("AttentionDurationSeconds", 45.00m));
        Assert.Contains("Metrics may only be added while the session is Started", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Adding_Metric_With_Mismatched_SessionId_Throws_DomainException()
    {
        // Arrange
        var session = Session.Start(_childId, _activityId, ActivityDomain.Movement);
        var foreignMetric = PerformanceMetric.Create(Guid.NewGuid(), "RepetitionCount", 5.00m);

        // Act & Assert
        var ex = Assert.Throws<DomainException>(() => session.AddMetric(foreignMetric));
        Assert.Contains("does not match this session ID", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Metric_With_Empty_Type_Throws_DomainException()
    {
        // Arrange
        var session = Session.Start(_childId, _activityId, ActivityDomain.Movement);

        // Act & Assert
        Assert.Throws<DomainException>(() => session.AddMetric("   ", 10.00m));
    }
}
