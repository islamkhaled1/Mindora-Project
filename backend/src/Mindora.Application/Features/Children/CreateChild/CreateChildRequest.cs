using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Children.CreateChild;

public record CreateChildRequest(
    string FullName,
    DateOnly DateOfBirth,
    string? SupportNotes = null,
    DifficultyLevel BaselineMovementLevel = DifficultyLevel.Beginner,
    DifficultyLevel BaselineSpeechLevel = DifficultyLevel.Beginner,
    DifficultyLevel BaselineAttentionLevel = DifficultyLevel.Beginner,
    Gender? Gender = null,
    string? Diagnosis = null,
    string? AvatarUrl = null,
    SupportLevel? SupportLevel = null,
    SensoryStatus? HearingStatus = null,
    SensoryStatus? VisionStatus = null,
    int? FocusDurationMinutes = null,
    string? PreferredPracticeTime = null,
    ActivityTypePreference? PreferredActivityType = null);
