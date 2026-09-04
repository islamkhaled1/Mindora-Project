using System.Text.Json;
using Mindora.Application.Common.Models;
using Mindora.Domain.Enums;

namespace Mindora.Infrastructure.Ai;

/// <summary>
/// Deterministic performance heuristics engine.
/// Evaluates session telemetry to produce performance analysis, supportive observations,
/// and adaptive activity adjustments.
/// Outputs are non-medical performance indicators and supportive observations.
/// </summary>
public class MockAiAnalysisService
{
    public Task<AiSessionAnalysisResult> AnalyzeSessionPerformanceAsync(
        AiSessionAnalysisRequest request,
        bool isFallback = false,
        CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();

        // 1. Extract and categorize metrics
        var metrics = request.Metrics ?? Array.Empty<AiMetricInput>();

        decimal? accuracy = metrics
            .Where(m => string.Equals(m.MetricType, "AccuracyPercentage", StringComparison.OrdinalIgnoreCase))
            .Select(m => (decimal?)m.Value)
            .Average();

        decimal? speechClarity = metrics
            .Where(m => string.Equals(m.MetricType, "SpeechClarityScore", StringComparison.OrdinalIgnoreCase))
            .Select(m => (decimal?)m.Value)
            .Average();

        decimal? reactionTimeMs = metrics
            .Where(m => string.Equals(m.MetricType, "ReactionTimeMs", StringComparison.OrdinalIgnoreCase))
            .Select(m => (decimal?)m.Value)
            .Average();

        decimal? responseLatencyMs = metrics
            .Where(m => string.Equals(m.MetricType, "ResponseLatencyMs", StringComparison.OrdinalIgnoreCase))
            .Select(m => (decimal?)m.Value)
            .Average();

        decimal? repetitionCount = metrics
            .Where(m => string.Equals(m.MetricType, "RepetitionCount", StringComparison.OrdinalIgnoreCase))
            .Select(m => (decimal?)m.Value)
            .Sum();

        decimal? attentionSeconds = metrics
            .Where(m => string.Equals(m.MetricType, "AttentionDurationSeconds", StringComparison.OrdinalIgnoreCase))
            .Select(m => (decimal?)m.Value)
            .Sum();

        // 2. Performance Heuristic: Calculate base accuracy score
        decimal baseScore = 75.00m; // Default baseline if metrics are sparse
        if (accuracy.HasValue && speechClarity.HasValue)
        {
            baseScore = (accuracy.Value + speechClarity.Value) / 2m;
        }
        else if (accuracy.HasValue)
        {
            baseScore = accuracy.Value;
        }
        else if (speechClarity.HasValue)
        {
            baseScore = speechClarity.Value;
        }
        else if (repetitionCount.HasValue && repetitionCount.Value > 0)
        {
            baseScore = Math.Min(100.00m, 60.00m + (repetitionCount.Value * 4.00m));
        }
        else if (attentionSeconds.HasValue && attentionSeconds.Value > 0)
        {
            baseScore = Math.Min(100.00m, 60.00m + (attentionSeconds.Value * 1.50m));
        }

        // 3. Performance Indicator: Fatigue detection heuristic
        bool fatigueObserved = false;
        if ((reactionTimeMs.HasValue && reactionTimeMs.Value > 3000m) ||
            (responseLatencyMs.HasValue && responseLatencyMs.Value > 3500m))
        {
            if (baseScore < 80.00m)
            {
                fatigueObserved = true;
            }
        }

        // If fatigue indicator triggered, apply modest pacing adjustment to score
        decimal overallScore = fatigueObserved ? Math.Max(0.00m, baseScore - 10.00m) : baseScore;
        overallScore = Math.Round(Math.Clamp(overallScore, 0.00m, 100.00m), 2);

        // Domain-specific score
        decimal domainScore = Math.Round(Math.Clamp(baseScore, 0.00m, 100.00m), 2);

        // 4. Adaptive Activity Adjustment
        DifficultyAdjustment adjustment;
        string pacingRecommendation;
        if (overallScore >= 85.00m && !fatigueObserved)
        {
            adjustment = DifficultyAdjustment.Increase;
            pacingRecommendation = "Progressive pacing with increased challenge";
        }
        else if (overallScore < 60.00m || fatigueObserved)
        {
            adjustment = DifficultyAdjustment.Decrease;
            pacingRecommendation = "Gentle pacing with increased rest intervals";
        }
        else
        {
            adjustment = DifficultyAdjustment.Maintain;
            pacingRecommendation = "Steady pacing maintaining current difficulty level";
        }

        // 5. Supportive Observations (strictly non-medical, encouraging observations)
        string observations = GenerateSupportiveObservations(request.Domain, overallScore, fatigueObserved, adjustment);

        // 6. Adaptive Parameters JSON
        var adaptiveParams = new
        {
            targetPacingSeconds = adjustment == DifficultyAdjustment.Increase ? 3 : (adjustment == DifficultyAdjustment.Decrease ? 6 : 4),
            visualCueLevel = adjustment == DifficultyAdjustment.Decrease ? "High" : "Standard",
            repetitionTarget = adjustment == DifficultyAdjustment.Increase ? 10 : (adjustment == DifficultyAdjustment.Decrease ? 5 : 8),
            pacingNotes = pacingRecommendation
        };
        string adaptiveParametersJson = JsonSerializer.Serialize(adaptiveParams);

        var result = new AiSessionAnalysisResult(
            overallScore,
            domainScore,
            observations,
            fatigueObserved,
            adjustment,
            adaptiveParametersJson,
            isFallback);

        return Task.FromResult(result);
    }

    private static string GenerateSupportiveObservations(
        ActivityDomain domain,
        decimal score,
        bool fatigueObserved,
        DifficultyAdjustment adjustment)
    {
        string domainName = domain switch
        {
            ActivityDomain.Movement => "motor coordination",
            ActivityDomain.Speech => "speech articulation",
            ActivityDomain.Attention => "focus and attention",
            _ => "activity participation"
        };

        if (score >= 85.00m && !fatigueObserved)
        {
            return $"Exceptional engagement and high accuracy demonstrated in {domainName}. The child is ready for adaptive challenge progression.";
        }

        if (fatigueObserved)
        {
            return $"Steady effort shown in {domainName}. Slower response times indicate natural fatigue; introducing additional rest intervals will maintain comfort and enjoyment.";
        }

        if (score < 60.00m)
        {
            return $"Active participation in {domainName}. Adjusting to a gentler difficulty with supportive visual cues will build confidence.";
        }

        return $"Consistent and stable performance in {domainName}. Sustaining current activity settings supports continued skill reinforcement.";
    }
}
