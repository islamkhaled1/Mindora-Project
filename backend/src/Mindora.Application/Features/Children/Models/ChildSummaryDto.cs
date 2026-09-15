namespace Mindora.Application.Features.Children.Models;

public record ChildSummaryDto(
    Guid Id,
    string FullName,
    DateOnly DateOfBirth,
    string CurrentMovementLevel,
    string CurrentSpeechLevel,
    string CurrentAttentionLevel,
    DateTime CreatedAtUtc,
    string? AvatarUrl = null,
    string? Gender = null);
