using Mindora.Application.Common.Models;

namespace Mindora.Application.Common.Interfaces;

/// <summary>
/// Evaluates activity session telemetry to produce performance analysis, supportive observations,
/// and adaptive difficulty adjustments.
/// Decoupled from specific AI providers and infrastructure protocols.
/// </summary>
public interface IAiAnalysisService
{
    Task<AiSessionAnalysisResult> AnalyzeSessionPerformanceAsync(
        AiSessionAnalysisRequest request,
        CancellationToken cancellationToken = default);
}
