using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Children.CreateChild;

public record CreateChildRequest(
    string FullName,
    DateOnly DateOfBirth,
    string? SupportNotes,
    DifficultyLevel BaselineMovementLevel,
    DifficultyLevel BaselineSpeechLevel,
    DifficultyLevel BaselineAttentionLevel);
