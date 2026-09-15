using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Features.Doctor.Models;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Doctor.GetDoctorDashboard;

public class GetDoctorDashboardHandler
{
    private readonly ICurrentUserService _currentUserService;
    private readonly IApplicationDbContext _context;

    public GetDoctorDashboardHandler(
        ICurrentUserService currentUserService,
        IApplicationDbContext context)
    {
        _currentUserService = currentUserService;
        _context = context;
    }

    public async Task<DoctorDashboardDto> HandleAsync(CancellationToken cancellationToken = default)
    {
        if (!_currentUserService.IsAuthenticated || _currentUserService.UserId == null)
        {
            throw new UnauthorizedException("User is not authenticated.");
        }

        if (_currentUserService.Role != UserRole.Doctor)
        {
            throw new ForbiddenException("Only doctors are permitted to view the doctor dashboard overview.");
        }

        var userId = _currentUserService.UserId.Value;
        var doctorProfile = _context.DoctorProfiles.FirstOrDefault(d => d.UserId == userId);
        if (doctorProfile == null)
        {
            throw new NotFoundException("DoctorProfile", userId);
        }

        var activeAssignments = _context.DoctorChildAssignments
            .Where(a => a.DoctorId == doctorProfile.Id && a.IsActive)
            .ToList();

        if (!activeAssignments.Any())
        {
            return new DoctorDashboardDto(
                0,
                0,
                0,
                0.00m,
                0,
                Array.Empty<DoctorNeedsSupportAlertDto>(),
                Array.Empty<DoctorRecentSessionDto>(),
                doctorProfile.ReferralCode,
                Array.Empty<DoctorWeeklyTrendDto>(),
                Array.Empty<DoctorRecentSessionDto>());
        }

        var childIds = activeAssignments.Select(a => a.ChildId).Distinct().ToList();

        var children = _context.Children
            .Where(c => childIds.Contains(c.Id))
            .ToDictionary(c => c.Id);

        var completedSessions = _context.Sessions
            .Where(s => childIds.Contains(s.ChildId) && s.Status == SessionStatus.Completed)
            .OrderByDescending(s => s.StartTimeUtc)
            .ToList();

        var sessionIds = completedSessions.Select(s => s.Id).ToList();

        var analysisResults = _context.SessionAnalysisResults
            .Where(r => sessionIds.Contains(r.SessionId))
            .ToDictionary(r => r.SessionId);

        var activityIds = completedSessions.Select(s => s.ActivityId).Distinct().ToList();
        var activities = _context.Activities
            .Where(a => activityIds.Contains(a.Id))
            .ToDictionary(a => a.Id, a => a.Title);

        var now = DateTime.UtcNow;
        var todayDate = DateOnly.FromDateTime(now);
        var sevenDaysAgo = now.AddDays(-7);
        var fourteenDaysAgo = now.AddDays(-14);

        int totalAssigned = children.Count;

        // Active children: at least one completed session in past 14 days
        var activeChildIds = completedSessions
            .Where(s => s.StartTimeUtc >= fourteenDaysAgo)
            .Select(s => s.ChildId)
            .Distinct()
            .ToHashSet();

        int activeChildrenCount = activeChildIds.Count;

        // Weekly completed sessions: completed in past 7 days
        int weeklyCompletedSessions = completedSessions.Count(s => s.StartTimeUtc >= sevenDaysAgo);

        // Average movement score across all movement completed sessions
        var movementScores = completedSessions
            .Where(s => s.Domain == ActivityDomain.Movement && analysisResults.ContainsKey(s.Id))
            .Select(s => analysisResults[s.Id].OverallPerformanceScore)
            .ToList();

        decimal avgMovementScore = movementScores.Any()
            ? Math.Round(movementScores.Average(), 2)
            : 0.00m;

        // Group sessions by child to identify NeedsSupport trends or inactivity
        var sessionsByChild = completedSessions
            .GroupBy(s => s.ChildId)
            .ToDictionary(g => g.Key, g => g.ToList());

        var needsSupportAlerts = new List<DoctorNeedsSupportAlertDto>();

        foreach (var child in children.Values)
        {
            sessionsByChild.TryGetValue(child.Id, out var childSessions);
            childSessions ??= new List<Session>();

            var scores = childSessions
                .Where(s => analysisResults.ContainsKey(s.Id))
                .Select(s => analysisResults[s.Id].OverallPerformanceScore)
                .ToList();

            string trend = CalculatePerformanceTrend(scores);

            DateTime? lastSessionTime = childSessions.FirstOrDefault()?.StartTimeUtc;
            int daysSinceLast = lastSessionTime.HasValue
                ? (int)Math.Max(0, (now - lastSessionTime.Value).TotalDays)
                : 999;

            int ageYears = todayDate.Year - child.DateOfBirth.Year;
            if (child.DateOfBirth > todayDate.AddYears(-ageYears))
            {
                ageYears--;
            }

            decimal overallAvgScore = scores.Any()
                ? Math.Round(scores.Average(), 2)
                : 0.00m;

            if (trend == PerformanceTrend.NeedsSupport.ToString() || (childSessions.Any() && daysSinceLast > 14))
            {
                needsSupportAlerts.Add(new DoctorNeedsSupportAlertDto(
                    child.Id,
                    child.FullName,
                    Math.Max(0, ageYears),
                    overallAvgScore,
                    child.CurrentMovementLevel.ToString(),
                    trend,
                    daysSinceLast,
                    lastSessionTime));
            }
        }

        // Recent 5 completed sessions
        var recentSessions = completedSessions.Take(5).Select(s =>
        {
            var childName = children.TryGetValue(s.ChildId, out var ch) ? ch.FullName : "Child";
            var actTitle = activities.TryGetValue(s.ActivityId, out var title) ? title : "Activity";
            decimal score = analysisResults.TryGetValue(s.Id, out var an) ? an.OverallPerformanceScore : 0.00m;

            return new DoctorRecentSessionDto(
                s.Id,
                s.ChildId,
                childName,
                actTitle,
                s.Domain.ToString(),
                score,
                s.ActualDurationSeconds ?? 0,
                s.EndTimeUtc ?? s.StartTimeUtc);
        }).ToList();

        // 6-week cohort progress trend (longitudinal performance curve for general progress chart)
        var weeklyTrends = new List<DoctorWeeklyTrendDto>();
        for (int i = 5; i >= 0; i--)
        {
            int weekNumber = 6 - i;
            var windowStart = now.AddDays(-(i + 1) * 7);
            var windowEnd = i == 0 ? now.AddMinutes(1) : now.AddDays(-i * 7);

            var weekScores = completedSessions
                .Where(s => s.StartTimeUtc >= windowStart && s.StartTimeUtc < windowEnd && analysisResults.ContainsKey(s.Id))
                .Select(s => analysisResults[s.Id].OverallPerformanceScore)
                .ToList();

            decimal weekAvg = weekScores.Any()
                ? Math.Round(weekScores.Average(), 2)
                : 0.00m;

            weeklyTrends.Add(new DoctorWeeklyTrendDto(
                weekNumber,
                $"أسبوع {weekNumber}",
                weekAvg));
        }

        // Today's completed sessions
        var startOfTodayUtc = DateTime.SpecifyKind(now.Date, DateTimeKind.Utc);
        var todaySessions = completedSessions
            .Where(s => s.StartTimeUtc >= startOfTodayUtc)
            .Select(s =>
            {
                var childName = children.TryGetValue(s.ChildId, out var ch) ? ch.FullName : "Child";
                var actTitle = activities.TryGetValue(s.ActivityId, out var title) ? title : "Activity";
                decimal score = analysisResults.TryGetValue(s.Id, out var an) ? an.OverallPerformanceScore : 0.00m;

                return new DoctorRecentSessionDto(
                    s.Id,
                    s.ChildId,
                    childName,
                    actTitle,
                    s.Domain.ToString(),
                    score,
                    s.ActualDurationSeconds ?? 0,
                    s.EndTimeUtc ?? s.StartTimeUtc);
            }).ToList();

        return new DoctorDashboardDto(
            totalAssigned,
            activeChildrenCount,
            weeklyCompletedSessions,
            avgMovementScore,
            needsSupportAlerts.Count(a => a.RecentTrend == PerformanceTrend.NeedsSupport.ToString()),
            needsSupportAlerts,
            recentSessions,
            doctorProfile.ReferralCode,
            weeklyTrends,
            todaySessions);
    }

    private static string CalculatePerformanceTrend(IReadOnlyList<decimal> descendingScores)
    {
        if (descendingScores.Count < 2)
        {
            return PerformanceTrend.Steady.ToString();
        }

        var recent = descendingScores.Take(3).ToList();
        var prior = descendingScores.Skip(3).Take(3).ToList();

        if (!prior.Any())
        {
            decimal delta = recent.First() - recent.Last();
            if (delta > 3.00m) return PerformanceTrend.Improving.ToString();
            if (delta < -3.00m) return PerformanceTrend.NeedsSupport.ToString();
            return PerformanceTrend.Steady.ToString();
        }

        decimal recentAvg = recent.Average();
        decimal priorAvg = prior.Average();
        decimal diff = recentAvg - priorAvg;

        if (diff > 3.00m) return PerformanceTrend.Improving.ToString();
        if (diff < -3.00m) return PerformanceTrend.NeedsSupport.ToString();
        return PerformanceTrend.Steady.ToString();
    }
}
