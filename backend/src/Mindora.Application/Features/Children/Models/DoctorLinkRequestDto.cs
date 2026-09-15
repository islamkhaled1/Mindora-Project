namespace Mindora.Application.Features.Children.Models;

public record DoctorLinkRequestDto(
    Guid Id,
    Guid DoctorId,
    Guid ChildId,
    Guid ParentId,
    string Status,
    DateTime CreatedAtUtc,
    DateTime? RespondedAtUtc,
    string DoctorName,
    string? Specialization = null,
    string? ClinicName = null);

public record DoctorLinkRequestSummaryDto(
    Guid Id,
    Guid ChildId,
    string ChildName,
    int? ChildAgeYears,
    string? ChildGender,
    string ParentName,
    string Status,
    DateTime CreatedAtUtc);
