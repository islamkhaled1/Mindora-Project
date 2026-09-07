namespace Mindora.Application.Features.Doctor.Models;

/// <summary>
/// Performance summary metrics for the Doctor Dashboard Overview.
/// Non-medical, performance telemetry indicators based on actual app sessions.
/// </summary>
public record DoctorDashboardDto(
    int TotalAssignedChildren,
    int ActiveChildrenCount,
    int WeeklyCompletedSessions,
    decimal AverageMovementScore,
    int NeedsSupportCount,
    IReadOnlyList<DoctorNeedsSupportAlertDto> NeedsSupportAlerts,
    IReadOnlyList<DoctorRecentSessionDto> RecentCompletedSessions);
