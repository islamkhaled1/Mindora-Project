namespace Mindora.Application.Features.Doctor.Models;

public record DoctorChildCardDto(
    Guid ChildId,
    string FullName,
    DateOnly DateOfBirth,
    int AgeYears,
    string? SupportNotes,
    string CurrentMovementLevel,
    int TotalCompletedSessions,
    int TotalPracticeMinutes,
    decimal OverallAverageScore,
    string RecentTrend,
    DateTime? LastSessionDateUtc,
    DateTime AssignedAtUtc);
