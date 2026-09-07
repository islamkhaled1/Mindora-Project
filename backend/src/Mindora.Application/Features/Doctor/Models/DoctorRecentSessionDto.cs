namespace Mindora.Application.Features.Doctor.Models;

public record DoctorRecentSessionDto(
    Guid SessionId,
    Guid ChildId,
    string ChildFullName,
    string ActivityTitle,
    string Domain,
    decimal OverallScore,
    int DurationSeconds,
    DateTime CompletedAtUtc);
