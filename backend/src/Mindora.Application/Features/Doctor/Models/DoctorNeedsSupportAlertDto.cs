namespace Mindora.Application.Features.Doctor.Models;

/// <summary>
/// Performance notification identifying an assigned child with a NeedsSupport trend or low activity cadence.
/// Explicitly non-medical performance indicator.
/// </summary>
public record DoctorNeedsSupportAlertDto(
    Guid ChildId,
    string FullName,
    int AgeYears,
    decimal OverallAverageScore,
    string CurrentMovementLevel,
    string RecentTrend,
    int DaysSinceLastSession,
    DateTime? LastSessionDateUtc = null);
