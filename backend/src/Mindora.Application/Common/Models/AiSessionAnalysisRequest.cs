using Mindora.Domain.Enums;

namespace Mindora.Application.Common.Models;

/// <summary>
/// Input payload for AI session analysis.
/// Decoupled from EF Core entities and external AI provider formats.
/// </summary>
public record AiSessionAnalysisRequest(
    Guid SessionId,
    int ChildAgeYears,
    ActivityDomain Domain,
    DifficultyLevel TargetDifficulty,
    int SessionDurationSeconds,
    IReadOnlyList<AiMetricInput> Metrics);
