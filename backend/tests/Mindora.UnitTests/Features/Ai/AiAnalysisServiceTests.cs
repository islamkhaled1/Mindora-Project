using System.Net;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Common.Models;
using Mindora.Domain.Enums;
using Mindora.Infrastructure;
using Mindora.Infrastructure.Ai;
using Xunit;

namespace Mindora.UnitTests.Features.Ai;

public class AiAnalysisServiceTests
{
    [Fact]
    public void AiService_DependencyInjection_Registers_Exactly_One_IAiAnalysisService_As_ResilientAiAnalysisService()
    {
        // Arrange
        var services = new ServiceCollection();
        var config = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                { "AiSettings:Provider", "Mock" },
                { "AiSettings:TimeoutSeconds", "4" }
            })
            .Build();

        services.AddInfrastructureServices(config);

        var provider = services.BuildServiceProvider();

        // Act
        var allRegistrations = provider.GetServices<IAiAnalysisService>().ToList();
        var resolvedService = provider.GetRequiredService<IAiAnalysisService>();

        // Assert
        Assert.Single(allRegistrations);
        Assert.IsType<ResilientAiAnalysisService>(resolvedService);
    }

    [Fact]
    public async Task Mock_Provider_Exclusivity_Never_Invokes_External_Client()
    {
        // Arrange
        var mockService = new MockAiAnalysisService();
        var stubHandler = new MockHttpHandler(async (req, ct) =>
        {
            throw new InvalidOperationException("External provider should NOT have been called!");
        });
        var httpClient = new HttpClient(stubHandler);
        var options = Options.Create(new AiOptions { Provider = "Mock" });
        var externalClient = new ExternalAiProviderClient(httpClient, options);
        var resilientService = new ResilientAiAnalysisService(
            mockService, externalClient, options, NullLogger<ResilientAiAnalysisService>.Instance);

        var request = new AiSessionAnalysisRequest(
            Guid.NewGuid(), 6, ActivityDomain.Movement, DifficultyLevel.Beginner, 120,
            new List<AiMetricInput> { new("AccuracyPercentage", 90m, DateTime.UtcNow) });

        // Act
        var result = await resilientService.AnalyzeSessionPerformanceAsync(request);

        // Assert
        Assert.NotNull(result);
        Assert.False(result.IsFallbackResult);
        Assert.Equal(0, stubHandler.CallCount);
    }

    [Fact]
    public async Task MockHeuristic_HighPerformance_Recommends_Increase()
    {
        // Arrange
        var mockService = new MockAiAnalysisService();
        var request = new AiSessionAnalysisRequest(
            Guid.NewGuid(), 6, ActivityDomain.Movement, DifficultyLevel.Beginner, 120,
            new List<AiMetricInput>
            {
                new("AccuracyPercentage", 92.00m, DateTime.UtcNow),
                new("ReactionTimeMs", 1200.00m, DateTime.UtcNow)
            });

        // Act
        var result = await mockService.AnalyzeSessionPerformanceAsync(request);

        // Assert
        Assert.True(result.OverallPerformanceScore >= 85.00m);
        Assert.Equal(DifficultyAdjustment.Increase, result.RecommendedDifficultyAdjustment);
        Assert.False(result.FatigueObserved);
        Assert.Contains("Exceptional engagement", result.SupportiveObservations);
        Assert.NotNull(result.AdaptiveParameters);
    }

    [Fact]
    public async Task MockHeuristic_Fatigue_Detected_Recommends_Decrease_And_Sets_Indicator()
    {
        // Arrange
        var mockService = new MockAiAnalysisService();
        var request = new AiSessionAnalysisRequest(
            Guid.NewGuid(), 6, ActivityDomain.Speech, DifficultyLevel.Intermediate, 180,
            new List<AiMetricInput>
            {
                new("SpeechClarityScore", 65.00m, DateTime.UtcNow),
                new("ReactionTimeMs", 3400.00m, DateTime.UtcNow) // Spiked reaction time
            });

        // Act
        var result = await mockService.AnalyzeSessionPerformanceAsync(request);

        // Assert
        Assert.True(result.FatigueObserved);
        Assert.Equal(DifficultyAdjustment.Decrease, result.RecommendedDifficultyAdjustment);
        Assert.Contains("fatigue", result.SupportiveObservations.ToLowerInvariant());
    }

    [Fact]
    public async Task MockHeuristic_Observations_Remain_Strictly_Non_Medical()
    {
        // Arrange
        var mockService = new MockAiAnalysisService();
        var request = new AiSessionAnalysisRequest(
            Guid.NewGuid(), 5, ActivityDomain.Attention, DifficultyLevel.Beginner, 100,
            new List<AiMetricInput> { new("AccuracyPercentage", 75.00m, DateTime.UtcNow) });

        // Act
        var result = await mockService.AnalyzeSessionPerformanceAsync(request);

        // Assert: Must NOT contain medical/clinical terms
        var obs = result.SupportiveObservations.ToLowerInvariant();
        Assert.DoesNotContain("diagnosis", obs);
        Assert.DoesNotContain("prescription", obs);
        Assert.DoesNotContain("clinical decision", obs);
        Assert.DoesNotContain("medical recommendation", obs);
    }

    [Fact]
    public async Task MockHeuristic_Missing_Optional_Metrics_Handled_Gracefully()
    {
        // Arrange: Empty metrics
        var mockService = new MockAiAnalysisService();
        var request = new AiSessionAnalysisRequest(
            Guid.NewGuid(), 6, ActivityDomain.Movement, DifficultyLevel.Beginner, 60,
            new List<AiMetricInput>());

        // Act
        var result = await mockService.AnalyzeSessionPerformanceAsync(request);

        // Assert
        Assert.NotNull(result);
        Assert.True(result.OverallPerformanceScore >= 0 && result.OverallPerformanceScore <= 100);
    }

    [Fact]
    public async Task External_AI_Failure_Falls_Back_To_Mock_With_IsFallbackResult_True()
    {
        // Arrange: External provider returns HTTP 500
        var mockService = new MockAiAnalysisService();
        var stubHandler = new MockHttpHandler(async (req, ct) =>
        {
            return new HttpResponseMessage(HttpStatusCode.InternalServerError);
        });
        var httpClient = new HttpClient(stubHandler);
        var options = Options.Create(new AiOptions
        {
            Provider = "External",
            Endpoint = "https://ai.example.com/analyze",
            TimeoutSeconds = 4
        });
        var externalClient = new ExternalAiProviderClient(httpClient, options);
        var resilientService = new ResilientAiAnalysisService(
            mockService, externalClient, options, NullLogger<ResilientAiAnalysisService>.Instance);

        var request = new AiSessionAnalysisRequest(
            Guid.NewGuid(), 6, ActivityDomain.Movement, DifficultyLevel.Beginner, 120,
            new List<AiMetricInput> { new("AccuracyPercentage", 85.00m, DateTime.UtcNow) });

        // Act
        var result = await resilientService.AnalyzeSessionPerformanceAsync(request);

        // Assert
        Assert.NotNull(result);
        Assert.True(result.IsFallbackResult);
        Assert.Equal(1, stubHandler.CallCount);
    }

    private class MockHttpHandler : HttpMessageHandler
    {
        private readonly Func<HttpRequestMessage, CancellationToken, Task<HttpResponseMessage>> _handler;
        public int CallCount { get; private set; }

        public MockHttpHandler(Func<HttpRequestMessage, CancellationToken, Task<HttpResponseMessage>> handler)
        {
            _handler = handler;
        }

        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            CallCount++;
            return _handler(request, cancellationToken);
        }
    }
}
