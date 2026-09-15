namespace Mindora.Application.Features.Doctor.Models;

/// <summary>
/// Clinical note and update timestamp recorded by an assigned doctor for a child.
/// </summary>
public record DoctorNotesDto(
    Guid ChildId,
    string? Notes,
    DateTime? UpdatedAtUtc);
