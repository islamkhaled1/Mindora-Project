namespace Mindora.Application.Features.Children.Models;

public record DoctorAssignmentDto(
    Guid Id,
    Guid DoctorId,
    Guid ChildId,
    DateTime AssignedAtUtc,
    bool IsActive,
    string? Specialization = null,
    string? ClinicName = null,
    string? DoctorName = null);
