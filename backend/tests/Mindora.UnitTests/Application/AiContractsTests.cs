using Mindora.Application.Common.Interfaces;
using Mindora.Application.Common.Models;
using Mindora.Domain.Enums;
using Xunit;

namespace Mindora.UnitTests.Application;

public class AiContractsTests
{
    [Fact]
    public void AiSessionAnalysisRequest_Initializes_With_Valid_Parameters()
    {
        // Arrange
        var sessionId = Guid.NewGuid();
        var metrics = new List<AiMetricInput>
        {
            new("AccuracyPercentage", 88.50m, DateTime.UtcNow),
            new("ReactionTimeMs", 420.00m, DateTime.UtcNow)
        };

        // Act
        var request = new AiSessionAnalysisRequest(
            sessionId,
            ChildAgeYears: 7,
            ActivityDomain.Movement,
            DifficultyLevel.Intermediate,
            SessionDurationSeconds: 300,
            metrics);

        // Assert
        Assert.Equal(sessionId, request.SessionId);
        Assert.Equal(7, request.ChildAgeYears);
        Assert.Equal(ActivityDomain.Movement, request.Domain);
        Assert.Equal(DifficultyLevel.Intermediate, request.TargetDifficulty);
        Assert.Equal(300, request.SessionDurationSeconds);
        Assert.Equal(2, request.Metrics.Count);
    }

    [Fact]
    public void AiSessionAnalysisResult_With_Valid_Parameters_Creates_Instance()
    {
        // Act
        var result = new AiSessionAnalysisResult(
            overallPerformanceScore: 84.50m,
            domainScore: 86.00m,
            supportiveObservations: "Child showed steady motor coordination with consistent repetition pacing.",
            fatigueObserved: false,
            recommendedDifficultyAdjustment: DifficultyAdjustment.Maintain,
            adaptiveParameters: "{\"pacingSeconds\": 3}",
            isFallbackResult: false);

        // Assert
        Assert.Equal(84.50m, result.OverallPerformanceScore);
        Assert.Equal(86.00m, result.DomainScore);
        Assert.False(result.FatigueObserved);
        Assert.Equal(DifficultyAdjustment.Maintain, result.RecommendedDifficultyAdjustment);
        Assert.False(result.IsFallbackResult);
        Assert.Contains("steady motor coordination", result.SupportiveObservations);
    }

    [Theory]
    [InlineData(-0.01)]
    [InlineData(-25.00)]
    [InlineData(100.01)]
    [InlineData(105.50)]
    public void AiSessionAnalysisResult_With_Invalid_Overall_Score_Throws_ArgumentOutOfRangeException(decimal invalidScore)
    {
        // Act & Assert
        var ex = Assert.Throws<ArgumentOutOfRangeException>(() =>
            new AiSessionAnalysisResult(
                overallPerformanceScore: invalidScore,
                domainScore: 80.00m,
                supportiveObservations: "Normal progress",
                fatigueObserved: false,
                recommendedDifficultyAdjustment: DifficultyAdjustment.Maintain));

        Assert.Equal("overallPerformanceScore", ex.ParamName);
    }

    [Theory]
    [InlineData(-0.01)]
    [InlineData(-50.00)]
    [InlineData(100.01)]
    [InlineData(150.00)]
    public void AiSessionAnalysisResult_With_Invalid_Domain_Score_Throws_ArgumentOutOfRangeException(decimal invalidDomainScore)
    {
        // Act & Assert
        var ex = Assert.Throws<ArgumentOutOfRangeException>(() =>
            new AiSessionAnalysisResult(
                overallPerformanceScore: 80.00m,
                domainScore: invalidDomainScore,
                supportiveObservations: "Normal progress",
                fatigueObserved: false,
                recommendedDifficultyAdjustment: DifficultyAdjustment.Maintain));

        Assert.Equal("domainScore", ex.ParamName);
    }

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    [InlineData(null!)]
    public void AiSessionAnalysisResult_With_Empty_Observations_Throws_ArgumentException(string? invalidObservations)
    {
        // Act & Assert
        Assert.Throws<ArgumentException>(() =>
            new AiSessionAnalysisResult(
                overallPerformanceScore: 80.00m,
                domainScore: 80.00m,
                supportiveObservations: invalidObservations!,
                fatigueObserved: false,
                recommendedDifficultyAdjustment: DifficultyAdjustment.Maintain));
    }

    [Fact]
    public async Task AiAnalysisService_Contract_Propagates_CancellationToken()
    {
        // Arrange
        var cts = new CancellationTokenSource();
        cts.Cancel(); // Pre-cancelled token

        var stubService = new StubAiAnalysisService();
        var request = new AiSessionAnalysisRequest(
            Guid.NewGuid(),
            ChildAgeYears: 6,
            ActivityDomain.Speech,
            DifficultyLevel.Beginner,
            SessionDurationSeconds: 120,
            Array.Empty<AiMetricInput>());

        // Act & Assert
        await Assert.ThrowsAsync<OperationCanceledException>(() =>
            stubService.AnalyzeSessionPerformanceAsync(request, cts.Token));
    }

    private sealed class StubAiAnalysisService : IAiAnalysisService
    {
        public Task<AiSessionAnalysisResult> AnalyzeSessionPerformanceAsync(
            AiSessionAnalysisRequest request,
            CancellationToken cancellationToken = default)
        {
            cancellationToken.ThrowIfCancellationRequested();
            return Task.FromResult(new AiSessionAnalysisResult(
                80m, 80m, "Supportive observations", false, DifficultyAdjustment.Maintain));
        }
    }
}
