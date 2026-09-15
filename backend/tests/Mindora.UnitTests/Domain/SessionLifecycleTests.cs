using Mindora.Domain.Common;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;
using Xunit;

namespace Mindora.UnitTests.Domain;

public class SessionLifecycleTests
{
    private readonly Guid _childId = Guid.NewGuid();
    private readonly Guid _activityId = Guid.NewGuid();

    [Fact]
    public void Started_Session_Can_Be_Completed_Successfully()
    {
        // Arrange
        var startTime = DateTime.UtcNow.AddMinutes(-10);
        var session = Session.Start(_childId, _activityId, ActivityDomain.Movement, startTime);
        var completedTime = DateTime.UtcNow;

        // Act
        session.Complete(completedTime, actualDurationSeconds: 600);

        // Assert
        Assert.Equal(SessionStatus.Completed, session.Status);
        Assert.Equal(completedTime, session.EndTimeUtc);
        Assert.Equal(600, session.ActualDurationSeconds);
    }

    [Fact]
    public void Started_Session_Can_Be_Abandoned_Successfully()
    {
        // Arrange
        var startTime = DateTime.UtcNow.AddMinutes(-5);
        var session = Session.Start(_childId, _activityId, ActivityDomain.Speech, startTime);
        var abandonedTime = DateTime.UtcNow;

        // Act
        session.Abandon(abandonedTime);

        // Assert
        Assert.Equal(SessionStatus.Abandoned, session.Status);
        Assert.Equal(abandonedTime, session.EndTimeUtc);
        Assert.NotNull(session.ActualDurationSeconds);
    }

    [Fact]
    public void Completed_Session_Cannot_Be_Completed_Again()
    {
        // Arrange
        var session = Session.Start(_childId, _activityId, ActivityDomain.Attention, DateTime.UtcNow.AddMinutes(-5));
        session.Complete(DateTime.UtcNow);

        // Act & Assert
        var ex = Assert.Throws<DomainException>(() => session.Complete(DateTime.UtcNow.AddMinutes(1)));
        Assert.Contains("already completed", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Completed_Session_Cannot_Be_Abandoned()
    {
        // Arrange
        var session = Session.Start(_childId, _activityId, ActivityDomain.Movement, DateTime.UtcNow.AddMinutes(-5));
        session.Complete(DateTime.UtcNow);

        // Act & Assert
        var ex = Assert.Throws<DomainException>(() => session.Abandon(DateTime.UtcNow.AddMinutes(1)));
        Assert.Contains("Cannot abandon a completed session", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Abandoned_Session_Cannot_Be_Completed()
    {
        // Arrange
        var session = Session.Start(_childId, _activityId, ActivityDomain.Speech, DateTime.UtcNow.AddMinutes(-5));
        session.Abandon(DateTime.UtcNow);

        // Act & Assert
        var ex = Assert.Throws<DomainException>(() => session.Complete(DateTime.UtcNow.AddMinutes(1)));
        Assert.Contains("Cannot complete an abandoned session", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Abandoned_Session_Cannot_Be_Abandoned_Again()
    {
        // Arrange
        var session = Session.Start(_childId, _activityId, ActivityDomain.Attention, DateTime.UtcNow.AddMinutes(-5));
        session.Abandon(DateTime.UtcNow);

        // Act & Assert
        var ex = Assert.Throws<DomainException>(() => session.Abandon(DateTime.UtcNow.AddMinutes(1)));
        Assert.Contains("already abandoned", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Completion_Time_Earlier_Than_StartTime_Throws_DomainException()
    {
        // Arrange
        var startTime = DateTime.UtcNow;
        var session = Session.Start(_childId, _activityId, ActivityDomain.Movement, startTime);
        var invalidCompletedTime = startTime.AddMinutes(-1);

        // Act & Assert
        var ex = Assert.Throws<DomainException>(() => session.Complete(invalidCompletedTime));
        Assert.Contains("earlier than start time", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Abandon_Time_Earlier_Than_StartTime_Throws_DomainException()
    {
        // Arrange
        var startTime = DateTime.UtcNow;
        var session = Session.Start(_childId, _activityId, ActivityDomain.Movement, startTime);
        var invalidAbandonedTime = startTime.AddMinutes(-1);

        // Act & Assert
        var ex = Assert.Throws<DomainException>(() => session.Abandon(invalidAbandonedTime));
        Assert.Contains("earlier than start time", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void AnalysisResult_Can_Be_Attached_To_Completed_Session()
    {
        // Arrange
        var session = Session.Start(_childId, _activityId, ActivityDomain.Movement, DateTime.UtcNow.AddMinutes(-5));
        session.Complete(DateTime.UtcNow);

        var result = SessionAnalysisResult.Create(
            session.Id,
            overallPerformanceScore: 85.50m,
            domainScore: 88.00m,
            supportiveObservations: "Child showed sustained coordination throughout repetitions.",
            fatigueObserved: false,
            recommendedDifficultyAdjustment: DifficultyAdjustment.Maintain);

        // Act
        session.AttachAnalysisResult(result);

        // Assert
        Assert.NotNull(session.AnalysisResult);
        Assert.Equal(85.50m, session.AnalysisResult.OverallPerformanceScore);
    }

    [Fact]
    public void AnalysisResult_Cannot_Be_Attached_To_Non_Completed_Session()
    {
        // Arrange
        var session = Session.Start(_childId, _activityId, ActivityDomain.Movement, DateTime.UtcNow);

        var result = SessionAnalysisResult.Create(
            session.Id,
            overallPerformanceScore: 85.50m,
            domainScore: 88.00m,
            supportiveObservations: "Great progress observed.",
            fatigueObserved: false,
            recommendedDifficultyAdjustment: DifficultyAdjustment.Maintain);

        // Act & Assert
        var ex = Assert.Throws<DomainException>(() => session.AttachAnalysisResult(result));
        Assert.Contains("completed session", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void AnalysisResult_With_Mismatched_SessionId_Throws_DomainException()
    {
        // Arrange
        var session = Session.Start(_childId, _activityId, ActivityDomain.Movement, DateTime.UtcNow.AddMinutes(-5));
        session.Complete(DateTime.UtcNow);

        var result = SessionAnalysisResult.Create(
            Guid.NewGuid(), // Different session ID
            overallPerformanceScore: 85.50m,
            domainScore: 88.00m,
            supportiveObservations: "Observations",
            fatigueObserved: false,
            recommendedDifficultyAdjustment: DifficultyAdjustment.Maintain);

        // Act & Assert
        var ex = Assert.Throws<DomainException>(() => session.AttachAnalysisResult(result));
        Assert.Contains("does not match this session ID", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void RecordParentFeedback_On_Completed_Session_Succeeds()
    {
        // Arrange
        var session = Session.Start(_childId, _activityId, ActivityDomain.Movement, DateTime.UtcNow.AddMinutes(-10));
        session.Complete(DateTime.UtcNow, 600);

        // Act
        session.RecordParentFeedback(ParentSentimentRating.Medium, "Child was focused but got slightly tired.");

        // Assert
        Assert.Equal(ParentSentimentRating.Medium, session.ParentRating);
        Assert.Equal("Child was focused but got slightly tired.", session.ParentNotes);
    }

    [Fact]
    public void RecordParentFeedback_On_Started_Session_Throws_DomainException()
    {
        // Arrange
        var session = Session.Start(_childId, _activityId, ActivityDomain.Movement, DateTime.UtcNow.AddMinutes(-5));

        // Act & Assert
        var ex = Assert.Throws<DomainException>(() =>
            session.RecordParentFeedback(ParentSentimentRating.Easy, "Too early"));
        Assert.Contains("completed session", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void RecordParentFeedback_With_Excessive_Notes_Length_Throws_DomainException()
    {
        // Arrange
        var session = Session.Start(_childId, _activityId, ActivityDomain.Movement, DateTime.UtcNow.AddMinutes(-5));
        session.Complete(DateTime.UtcNow);
        var longNotes = new string('N', 1001);

        // Act & Assert
        var ex = Assert.Throws<DomainException>(() =>
            session.RecordParentFeedback(ParentSentimentRating.Difficult, longNotes));
        Assert.Contains("cannot exceed 1000 characters", ex.Message, StringComparison.OrdinalIgnoreCase);
    }
}
