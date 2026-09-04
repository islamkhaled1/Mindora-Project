namespace Mindora.Application.Features.Activities.Models;

public record ActivityDto(
    Guid Id,
    string Title,
    string Description,
    string Domain,
    string BaseDifficulty,
    string? AdaptiveSettingsJson,
    DateTime CreatedAtUtc);
