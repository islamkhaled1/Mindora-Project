namespace Mindora.Application.Features.Doctor.Models;

/// <summary>
/// Longitudinal weekly performance trend point for the Doctor Dashboard General Progress chart.
/// Non-medical, average performance score across assigned children for a specific week.
/// </summary>
public record DoctorWeeklyTrendDto(
    int WeekNumber,
    string WeekLabel,
    decimal AverageScore);
