using Microsoft.EntityFrameworkCore;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;
using Mindora.Infrastructure.Persistence;
using Xunit;

namespace Mindora.UnitTests.Infrastructure;

public class PersistenceTests
{
    private static ApplicationDbContext CreateInMemoryDbContext()
    {
        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;

        return new ApplicationDbContext(options);
    }

    [Fact]
    public void Model_Builds_Successfully()
    {
        using var context = CreateInMemoryDbContext();
        var model = context.Model;

        Assert.NotNull(model);
        Assert.NotNull(model.FindEntityType(typeof(Child)));
        Assert.NotNull(model.FindEntityType(typeof(Session)));
        Assert.NotNull(model.FindEntityType(typeof(Activity)));
        Assert.NotNull(model.FindEntityType(typeof(ParentProfile)));
        Assert.NotNull(model.FindEntityType(typeof(DoctorProfile)));
        Assert.NotNull(model.FindEntityType(typeof(DoctorChildAssignment)));
        Assert.NotNull(model.FindEntityType(typeof(PerformanceMetric)));
        Assert.NotNull(model.FindEntityType(typeof(SessionAnalysisResult)));
        Assert.NotNull(model.FindEntityType(typeof(BaselineAssessment)));
    }

    [Fact]
    public async Task GlobalQueryFilter_Excludes_SoftDeleted_Children_From_Normal_Queries()
    {
        // Arrange
        using var context = CreateInMemoryDbContext();
        var parentId = Guid.NewGuid();

        var activeChild = Child.Create(parentId, "Active Child", DateOnly.FromDateTime(DateTime.UtcNow.AddYears(-5)));
        var deletedChild = Child.Create(parentId, "Deleted Child", DateOnly.FromDateTime(DateTime.UtcNow.AddYears(-6)));
        deletedChild.MarkAsDeleted();

        context.Children.AddRange(activeChild, deletedChild);
        await context.SaveChangesAsync();

        // Act - Normal query (Global filter active)
        var queriedChildren = await context.Children.ToListAsync();

        // Assert
        Assert.Single(queriedChildren);
        Assert.Equal("Active Child", queriedChildren[0].FullName);
        Assert.DoesNotContain(queriedChildren, c => c.FullName == "Deleted Child");
    }

    [Fact]
    public async Task GlobalQueryFilter_Allows_Access_Via_IgnoreQueryFilters()
    {
        // Arrange
        using var context = CreateInMemoryDbContext();
        var parentId = Guid.NewGuid();

        var activeChild = Child.Create(parentId, "Active Child", DateOnly.FromDateTime(DateTime.UtcNow.AddYears(-5)));
        var deletedChild = Child.Create(parentId, "Deleted Child", DateOnly.FromDateTime(DateTime.UtcNow.AddYears(-6)));
        deletedChild.MarkAsDeleted();

        context.Children.AddRange(activeChild, deletedChild);
        await context.SaveChangesAsync();

        // Act - Explicit administrative/audit query with IgnoreQueryFilters
        var allChildren = await context.Children.IgnoreQueryFilters().ToListAsync();

        // Assert
        Assert.Equal(2, allChildren.Count);
        Assert.Contains(allChildren, c => c.FullName == "Deleted Child" && c.IsDeleted);
    }

    [Fact]
    public async Task Historical_Sessions_Remain_Present_After_Child_Soft_Delete()
    {
        // Arrange
        using var context = CreateInMemoryDbContext();
        var parentId = Guid.NewGuid();
        var child = Child.Create(parentId, "Leo", DateOnly.FromDateTime(DateTime.UtcNow.AddYears(-5)));
        var activity = Activity.Create("Tap", "Desc", ActivityDomain.Movement, DifficultyLevel.Beginner);

        context.Children.Add(child);
        context.Activities.Add(activity);
        await context.SaveChangesAsync();

        var session = Session.Start(child.Id, activity.Id, ActivityDomain.Movement);
        session.Complete(DateTime.UtcNow.AddMinutes(5), 300);
        context.Sessions.Add(session);
        await context.SaveChangesAsync();

        // Act: Soft-delete child
        child.MarkAsDeleted();
        await context.SaveChangesAsync();

        // Assert: Child is filtered out of normal query, but historical session remains intact in database
        var visibleChildren = await context.Children.ToListAsync();
        Assert.Empty(visibleChildren);

        var historicalSessions = await context.Sessions.Where(s => s.ChildId == child.Id).ToListAsync();
        Assert.Single(historicalSessions);
        Assert.Equal(session.Id, historicalSessions[0].Id);
        Assert.Equal(SessionStatus.Completed, historicalSessions[0].Status);
    }

    [Fact]
    public async Task Session_Cascade_Deletes_PerformanceMetrics_And_AnalysisResult()
    {
        // Arrange
        using var context = CreateInMemoryDbContext();
        var childId = Guid.NewGuid();
        var activityId = Guid.NewGuid();

        var session = Session.Start(childId, activityId, ActivityDomain.Speech);
        session.AddMetric("SpeechClarityScore", 85.50m);
        session.Complete(DateTime.UtcNow.AddMinutes(5), 300);

        var result = SessionAnalysisResult.Create(
            session.Id,
            overallPerformanceScore: 88.00m,
            domainScore: 85.50m,
            supportiveObservations: "Great speech articulation",
            fatigueObserved: false,
            recommendedDifficultyAdjustment: DifficultyAdjustment.Maintain);

        session.AttachAnalysisResult(result);

        context.Sessions.Add(session);
        await context.SaveChangesAsync();

        Assert.Single(context.Sessions);
        Assert.Single(context.PerformanceMetrics);
        Assert.Single(context.SessionAnalysisResults);

        // Act: Remove session
        context.Sessions.Remove(session);
        await context.SaveChangesAsync();

        // Assert: Cascades to metrics and analysis result
        Assert.Empty(context.Sessions);
        Assert.Empty(context.PerformanceMetrics);
        Assert.Empty(context.SessionAnalysisResults);
    }

    [Fact]
    public async Task Decimal_Precision_Preserves_Values_Without_Truncation()
    {
        // Arrange
        using var context = CreateInMemoryDbContext();
        var sessionId = Guid.NewGuid();

        var metricPercentage = PerformanceMetric.Create(sessionId, "AccuracyPercentage", 98.75m);
        var metricReactionMs = PerformanceMetric.Create(sessionId, "ReactionTimeMs", 2450.50m);
        var metricDuration = PerformanceMetric.Create(sessionId, "AttentionDurationSeconds", 120.00m);
        var metricRepetitions = PerformanceMetric.Create(sessionId, "RepetitionCount", 15.00m);

        context.PerformanceMetrics.AddRange(metricPercentage, metricReactionMs, metricDuration, metricRepetitions);
        await context.SaveChangesAsync();

        // Act
        var queried = await context.PerformanceMetrics.Where(m => m.SessionId == sessionId).ToListAsync();

        // Assert
        Assert.Equal(4, queried.Count);
        Assert.Equal(98.75m, queried.First(m => m.MetricType == "AccuracyPercentage").Value);
        Assert.Equal(2450.50m, queried.First(m => m.MetricType == "ReactionTimeMs").Value);
        Assert.Equal(120.00m, queried.First(m => m.MetricType == "AttentionDurationSeconds").Value);
        Assert.Equal(15.00m, queried.First(m => m.MetricType == "RepetitionCount").Value);
    }

    [Fact]
    public async Task Child_Extended_Profile_Fields_Persist_And_Retrieve_Accurately()
    {
        // Arrange
        using var context = CreateInMemoryDbContext();
        var parentId = Guid.NewGuid();

        var child = Child.Create(
            parentId,
            "Maya Johnson",
            DateOnly.FromDateTime(DateTime.UtcNow.AddYears(-7)),
            supportNotes: "Thrives with visual structure.",
            currentMovementLevel: DifficultyLevel.Intermediate,
            currentSpeechLevel: DifficultyLevel.Beginner,
            currentAttentionLevel: DifficultyLevel.Advanced,
            createdAtUtc: DateTime.UtcNow,
            gender: Gender.Girl,
            diagnosis: "Autism Spectrum Disorder",
            avatarUrl: "https://mindora.app/avatars/maya.png",
            supportLevel: SupportLevel.Moderate,
            hearingStatus: SensoryStatus.Normal,
            visionStatus: SensoryStatus.HasDifficulty,
            focusDurationMinutes: 15,
            preferredPracticeTime: "10:00 - 11:30 AM",
            preferredActivityType: ActivityTypePreference.Games);

        context.Children.Add(child);
        await context.SaveChangesAsync();

        // Act
        var retrieved = await context.Children.FirstAsync(c => c.Id == child.Id);

        // Assert
        Assert.Equal(Gender.Girl, retrieved.Gender);
        Assert.Equal("Autism Spectrum Disorder", retrieved.Diagnosis);
        Assert.Equal("https://mindora.app/avatars/maya.png", retrieved.AvatarUrl);
        Assert.Equal(SupportLevel.Moderate, retrieved.SupportLevel);
        Assert.Equal(SensoryStatus.Normal, retrieved.HearingStatus);
        Assert.Equal(SensoryStatus.HasDifficulty, retrieved.VisionStatus);
        Assert.Equal(15, retrieved.FocusDurationMinutes);
        Assert.Equal("10:00 - 11:30 AM", retrieved.PreferredPracticeTime);
        Assert.Equal(ActivityTypePreference.Games, retrieved.PreferredActivityType);
    }

    [Fact]
    public async Task Session_Parent_Feedback_Persists_And_Retrieves_Accurately()
    {
        // Arrange
        using var context = CreateInMemoryDbContext();
        var childId = Guid.NewGuid();
        var activityId = Guid.NewGuid();

        var session = Session.Start(childId, activityId, ActivityDomain.Movement);
        session.Complete(DateTime.UtcNow, actualDurationSeconds: 300);
        session.RecordParentFeedback(ParentSentimentRating.Easy, "Child was very engaged and smiled throughout.");

        context.Sessions.Add(session);
        await context.SaveChangesAsync();

        // Act
        var retrieved = await context.Sessions.FirstAsync(s => s.Id == session.Id);

        // Assert
        Assert.Equal(ParentSentimentRating.Easy, retrieved.ParentRating);
        Assert.Equal("Child was very engaged and smiled throughout.", retrieved.ParentNotes);
    }

    [Fact]
    public async Task DoctorProfile_ReferralCode_Persists_And_Enforces_Lookup()
    {
        // Arrange
        using var context = CreateInMemoryDbContext();
        var userId = Guid.NewGuid();

        var doctor = DoctorProfile.Create(userId, "Pediatric Neurologist", "Apex Children's Clinic", "LIC-4412", referralCode: "DR-TESTCODE");
        context.DoctorProfiles.Add(doctor);
        await context.SaveChangesAsync();

        // Act
        var retrieved = await context.DoctorProfiles.FirstAsync(d => d.ReferralCode == "DR-TESTCODE");

        // Assert
        Assert.Equal(userId, retrieved.UserId);
        Assert.Equal("DR-TESTCODE", retrieved.ReferralCode);
    }

    [Fact]
    public async Task BaselineAssessment_Persists_Scores_With_Precision()
    {
        // Arrange
        using var context = CreateInMemoryDbContext();
        var childId = Guid.NewGuid();

        var assessment = BaselineAssessment.Create(
            childId,
            overallScore: 82.50m,
            cognitiveScore: 78.00m,
            communicationScore: 85.25m,
            motorScore: 90.00m,
            emotionalScore: 76.75m);

        context.BaselineAssessments.Add(assessment);
        await context.SaveChangesAsync();

        // Act
        var retrieved = await context.BaselineAssessments.FirstAsync(b => b.Id == assessment.Id);

        // Assert
        Assert.Equal(childId, retrieved.ChildId);
        Assert.Equal(82.50m, retrieved.OverallScore);
        Assert.Equal(78.00m, retrieved.CognitiveScore);
        Assert.Equal(85.25m, retrieved.CommunicationScore);
        Assert.Equal(90.00m, retrieved.MotorScore);
        Assert.Equal(76.75m, retrieved.EmotionalScore);
    }
}
