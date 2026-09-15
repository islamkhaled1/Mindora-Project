namespace Mindora.Application.Features.Children.Models;

public record AssignedDoctorSummaryDto(
    Guid DoctorId,
    string Specialization,
    string? ClinicName,
    DateTime AssignedAtUtc,
    string? ReferralCode = null);

public record ChildDetailsDto(
    Guid Id,
    Guid ParentId,
    string FullName,
    DateOnly DateOfBirth,
    string? SupportNotes,
    string CurrentMovementLevel,
    string CurrentSpeechLevel,
    string CurrentAttentionLevel,
    DateTime CreatedAtUtc,
    IReadOnlyList<AssignedDoctorSummaryDto> AssignedDoctors,
    string? Gender = null,
    string? Diagnosis = null,
    string? AvatarUrl = null,
    string? SupportLevel = null,
    string? HearingStatus = null,
    string? VisionStatus = null,
    int? FocusDurationMinutes = null,
    string? PreferredPracticeTime = null,
    string? PreferredActivityType = null);
