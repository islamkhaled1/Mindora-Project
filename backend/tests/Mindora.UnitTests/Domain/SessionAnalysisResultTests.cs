using Mindora.Domain.Common;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;
using Xunit;

namespace Mindora.UnitTests.Domain;

public class SessionAnalysisResultTests
{
    private readonly Guid _sessionId = Guid.NewGuid();

    [Theory]
    [InlineData(-0.01)]
    [InlineData(-10.00)]
    [InlineData(100.01)]
    [InlineData(150.00)]
    public void Performance_Score_Outside_0_To_100_Is_Rejected(decimal invalidScore)
    {
        // Act & Assert
        var ex = Assert.Throws<DomainException>(() =>
            SessionAnalysisResult.Create(
                _sessionId,
                overallPerformanceScore: invalidScore,
                domainScore: 80.00m,
                supportiveObservations: "Normal progress",
                fatigueObserved: false,
                recommendedDifficultyAdjustment: DifficultyAdjustment.Maintain));

        Assert.Contains("OverallPerformanceScore must be between 0.00 and 100.00", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Theory]
    [InlineData(-0.01)]
    [InlineData(-50.00)]
    [InlineData(100.01)]
    [InlineData(200.00)]
    public void Domain_Score_Outside_0_To_100_Is_Rejected(decimal invalidDomainScore)
    {
        // Act & Assert
        var ex = Assert.Throws<DomainException>(() =>
            SessionAnalysisResult.Create(
                _sessionId,
                overallPerformanceScore: 75.00m,
                domainScore: invalidDomainScore,
                supportiveObservations: "Normal progress",
                fatigueObserved: false,
                recommendedDifficultyAdjustment: DifficultyAdjustment.Maintain));

        Assert.Contains("DomainScore must be between 0.00 and 100.00", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Theory]
    [InlineData(0.00)]
    [InlineData(50.55)]
    [InlineData(100.00)]
    public void Boundary_And_Valid_Scores_Are_Accepted(decimal validScore)
    {
        // Act
        var result = SessionAnalysisResult.Create(
            _sessionId,
            overallPerformanceScore: validScore,
            domainScore: validScore,
            supportiveObservations: "Valid score range tested",
            fatigueObserved: false,
            recommendedDifficultyAdjustment: DifficultyAdjustment.Maintain);

        // Assert
        Assert.Equal(validScore, result.OverallPerformanceScore);
        Assert.Equal(validScore, result.DomainScore);
    }

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    [InlineData(null)]
    public void Empty_Or_Null_Supportive_Observations_Throws_DomainException(string? invalidObservations)
    {
        // Act & Assert
        var ex = Assert.Throws<DomainException>(() =>
            SessionAnalysisResult.Create(
                _sessionId,
                overallPerformanceScore: 80.00m,
                domainScore: 80.00m,
                supportiveObservations: invalidObservations!,
                fatigueObserved: false,
                recommendedDifficultyAdjustment: DifficultyAdjustment.Maintain));

        Assert.Contains("SupportiveObservations cannot be empty", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Empty_SessionId_Throws_DomainException()
    {
        // Act & Assert
        var ex = Assert.Throws<DomainException>(() =>
            SessionAnalysisResult.Create(
                Guid.Empty,
                overallPerformanceScore: 80.00m,
                domainScore: 80.00m,
                supportiveObservations: "Valid observations",
                fatigueObserved: false,
                recommendedDifficultyAdjustment: DifficultyAdjustment.Maintain));

        Assert.Contains("SessionId cannot be empty", ex.Message, StringComparison.OrdinalIgnoreCase);
    }
}
