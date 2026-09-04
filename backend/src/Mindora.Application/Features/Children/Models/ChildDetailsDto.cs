namespace Mindora.Application.Features.Children.Models;

public record AssignedDoctorSummaryDto(
    Guid DoctorId,
    string Specialization,
    string? ClinicName,
    DateTime AssignedAtUtc);

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
    IReadOnlyList<AssignedDoctorSummaryDto> AssignedDoctors);
