namespace Mindora.Application.Features.Children.Models;

public record ChildDto(
    Guid Id,
    Guid ParentId,
    string FullName,
    DateOnly DateOfBirth,
    string? SupportNotes,
    string CurrentMovementLevel,
    string CurrentSpeechLevel,
    string CurrentAttentionLevel,
    DateTime CreatedAtUtc);
