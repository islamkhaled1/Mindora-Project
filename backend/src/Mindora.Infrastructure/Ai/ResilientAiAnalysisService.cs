using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Common.Models;

namespace Mindora.Infrastructure.Ai;

/// <summary>
/// Resilient decorator and single public DI implementation of IAiAnalysisService.
/// Guarantees that external network failures, timeouts, or unexpected payloads
/// fall back gracefully to the deterministic MockAiAnalysisService with zero demo disruptions.
/// </summary>
public class ResilientAiAnalysisService : IAiAnalysisService
{
    private readonly MockAiAnalysisService _mockService;
    private readonly ExternalAiProviderClient _externalClient;
    private readonly AiOptions _options;
    private readonly ILogger<ResilientAiAnalysisService> _logger;

    public ResilientAiAnalysisService(
        MockAiAnalysisService mockService,
        ExternalAiProviderClient externalClient,
        IOptions<AiOptions> options,
        ILogger<ResilientAiAnalysisService> logger)
    {
        _mockService = mockService;
        _externalClient = externalClient;
        _options = options.Value;
        _logger = logger;
    }

    public async Task<AiSessionAnalysisResult> AnalyzeSessionPerformanceAsync(
        AiSessionAnalysisRequest request,
        CancellationToken cancellationToken = default)
    {
        // 1. Default / Mock Provider: Direct execution of deterministic heuristic engine
        if (string.Equals(_options.Provider, "Mock", StringComparison.OrdinalIgnoreCase))
        {
            return await _mockService.AnalyzeSessionPerformanceAsync(request, isFallback: false, cancellationToken);
        }

        // 2. External Provider: Execute with timeout and fault resilience
        try
        {
            return await _externalClient.AnalyzeAsync(request, cancellationToken);
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            // Preserve genuine caller cancellation
            throw;
        }
        catch (Exception ex)
        {
            // Log sanitized warning metadata: no PII, no prompt text, no tokens
            _logger.LogWarning(
                "External AI analysis failed ({ErrorType}). Engaging deterministic fallback heuristic engine.",
                ex.GetType().Name);

            // Execute deterministic heuristic engine with fallback flag enabled
            return await _mockService.AnalyzeSessionPerformanceAsync(request, isFallback: true, cancellationToken);
        }
    }
}
