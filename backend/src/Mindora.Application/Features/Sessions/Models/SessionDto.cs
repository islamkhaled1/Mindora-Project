namespace Mindora.Application.Features.Sessions.Models;

public record SessionDto(
    Guid Id,
    Guid ChildId,
    Guid ActivityId,
    string Domain,
    string Status,
    DateTime StartTimeUtc,
    string? TargetDifficulty = null,
    string? AdaptiveSettingsJson = null);
