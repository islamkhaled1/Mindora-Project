using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.Options;
using Mindora.Application.Common.Models;
using Mindora.Domain.Enums;

namespace Mindora.Infrastructure.Ai;

/// <summary>
/// Typed HTTP client for optional external AI service providers.
/// Enforces bounded execution timeouts and payload validation.
/// </summary>
public class ExternalAiProviderClient
{
    private readonly HttpClient _httpClient;
    private readonly AiOptions _options;

    public ExternalAiProviderClient(HttpClient httpClient, IOptions<AiOptions> options)
    {
        _httpClient = httpClient;
        _options = options.Value;
    }

    public async Task<AiSessionAnalysisResult> AnalyzeAsync(
        AiSessionAnalysisRequest request,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(_options.Endpoint))
        {
            throw new InvalidOperationException("External AI provider endpoint is not configured.");
        }

        var timeoutSeconds = _options.TimeoutSeconds > 0 ? _options.TimeoutSeconds : 4;
        using var cts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        cts.CancelAfter(TimeSpan.FromSeconds(timeoutSeconds));

        var response = await _httpClient.PostAsJsonAsync(_options.Endpoint, request, cts.Token);
        response.EnsureSuccessStatusCode();

        var payload = await response.Content.ReadFromJsonAsync<ExternalAiResponseDto>(cancellationToken: cts.Token);
        if (payload == null)
        {
            throw new InvalidOperationException("External AI provider returned an empty or invalid payload.");
        }

        // Validate score boundaries
        if (payload.OverallPerformanceScore < 0.00m || payload.OverallPerformanceScore > 100.00m ||
            payload.DomainScore < 0.00m || payload.DomainScore > 100.00m)
        {
            throw new InvalidOperationException($"External AI provider returned out-of-range scores ({payload.OverallPerformanceScore}, {payload.DomainScore}).");
        }

        if (string.IsNullOrWhiteSpace(payload.SupportiveObservations))
        {
            throw new InvalidOperationException("External AI provider returned empty supportive observations.");
        }

        return new AiSessionAnalysisResult(
            payload.OverallPerformanceScore,
            payload.DomainScore,
            payload.SupportiveObservations,
            payload.FatigueObserved,
            payload.RecommendedDifficultyAdjustment,
            payload.AdaptiveParametersJson,
            isFallbackResult: false);
    }

    public record ExternalAiResponseDto(
        decimal OverallPerformanceScore,
        decimal DomainScore,
        string SupportiveObservations,
        bool FatigueObserved,
        DifficultyAdjustment RecommendedDifficultyAdjustment,
        string? AdaptiveParametersJson);
}
