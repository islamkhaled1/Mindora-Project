using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Features.Progress.Models;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Progress.GetChildProgress;

public class GetChildProgressHandler
{
    private readonly ICurrentUserService _currentUserService;
    private readonly IApplicationDbContext _context;

    public GetChildProgressHandler(
        ICurrentUserService currentUserService,
        IApplicationDbContext context)
    {
        _currentUserService = currentUserService;
        _context = context;
    }

    public async Task<ChildProgressSummaryDto> HandleAsync(Guid childId, CancellationToken cancellationToken = default)
    {
        if (!_currentUserService.IsAuthenticated || _currentUserService.UserId == null)
        {
            throw new UnauthorizedException("User is not authenticated.");
        }

        var userId = _currentUserService.UserId.Value;
        var role = _currentUserService.Role;

        // 1. Verify child exists and is not soft-deleted
        var child = _context.Children.FirstOrDefault(c => c.Id == childId);
        if (child == null)
        {
            throw new NotFoundException("Child", childId);
        }

        // 2. Authorize caller for Child (IDOR protection)
        if (role == UserRole.Parent)
        {
            var parentProfile = _context.ParentProfiles.FirstOrDefault(p => p.UserId == userId);
            if (parentProfile == null || child.ParentId != parentProfile.Id)
            {
                throw new NotFoundException("Child", childId);
            }
        }
        else if (role == UserRole.Doctor)
        {
            var doctorProfile = _context.DoctorProfiles.FirstOrDefault(d => d.UserId == userId);
            if (doctorProfile == null)
            {
                throw new NotFoundException("Child", childId);
            }

            var isAssigned = _context.DoctorChildAssignments
                .Any(a => a.DoctorId == doctorProfile.Id && a.ChildId == childId && a.IsActive);
            if (!isAssigned)
            {
                throw new NotFoundException("Child", childId);
            }
        }
        else
        {
            throw new ForbiddenException("You do not have permission to view child progress.");
        }

        // 3. Query ONLY Completed sessions for this child.
        // DO NOT join PerformanceMetrics to prevent Cartesian row multiplication!
        var completedSessions = _context.Sessions
            .Where(s => s.ChildId == childId && s.Status == SessionStatus.Completed)
            .OrderByDescending(s => s.StartTimeUtc)
            .ToList();

        var sessionIds = completedSessions.Select(s => s.Id).ToList();

        // 4. Query 1:1 SessionAnalysisResults
        var analysisResults = _context.SessionAnalysisResults
            .Where(r => sessionIds.Contains(r.SessionId))
            .ToDictionary(r => r.SessionId);

        // 5. Aggregate overall metrics
        int totalCompletedSessions = completedSessions.Count;
        int totalDurationSeconds = completedSessions.Sum(s => s.ActualDurationSeconds ?? 0);
        int totalPracticeMinutes = totalDurationSeconds / 60;

        var scoredSessions = completedSessions
            .Where(s => analysisResults.ContainsKey(s.Id))
            .Select(s => new
            {
                Session = s,
                Analysis = analysisResults[s.Id]
            })
            .ToList();

        decimal overallAverageScore = scoredSessions.Any()
            ? Math.Round(scoredSessions.Average(x => x.Analysis.OverallPerformanceScore), 2)
            : 0.00m;

        // 6. Current active streak calculation (consecutive calendar days in UTC)
        int currentStreakDays = CalculateCurrentStreak(completedSessions);

        // 7. Recent performance trend algorithm (latest 3 scored vs prior 3 scored)
        string overallTrend = CalculatePerformanceTrend(scoredSessions.Select(s => s.Analysis.OverallPerformanceScore).ToList());

        // 8. Domain-specific summaries for Movement, Speech, Attention
        var domainSummaries = new List<DomainProgressDto>();
        foreach (var domain in new[] { ActivityDomain.Movement, ActivityDomain.Speech, ActivityDomain.Attention })
        {
            var domainSessions = completedSessions.Where(s => s.Domain == domain).ToList();
            int domainCompleted = domainSessions.Count;

            var domainScored = domainSessions
                .Where(s => analysisResults.ContainsKey(s.Id))
                .Select(s => analysisResults[s.Id])
                .ToList();

            decimal domainAvg = domainScored.Any()
                ? Math.Round(domainScored.Average(a => a.DomainScore), 2)
                : 0.00m;

            decimal latestScore = domainScored.Any()
                ? domainScored[0].DomainScore // since completedSessions is ordered descending
                : 0.00m;

            string domainTrend = CalculatePerformanceTrend(domainScored.Select(a => a.DomainScore).ToList());

            domainSummaries.Add(new DomainProgressDto(
                domain.ToString(),
                domainCompleted,
                domainAvg,
                latestScore,
                domainTrend));
        }

        return new ChildProgressSummaryDto(
            childId,
            totalCompletedSessions,
            totalPracticeMinutes,
            overallAverageScore,
            currentStreakDays,
            overallTrend,
            domainSummaries);
    }

    /// <summary>
    /// Calculates the number of consecutive calendar days with at least one completed session.
    /// Uses UTC date boundaries.
    /// </summary>
    private static int CalculateCurrentStreak(IReadOnlyList<Session> completedSessions)
    {
        if (!completedSessions.Any())
        {
            return 0;
        }

        var distinctDates = completedSessions
            .Select(s => DateOnly.FromDateTime(s.StartTimeUtc))
            .Distinct()
            .OrderByDescending(d => d)
            .ToList();

        if (!distinctDates.Any())
        {
            return 0;
        }

        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        var yesterday = today.AddDays(-1);

        // A streak is active only if there was a session today or yesterday
        var mostRecent = distinctDates[0];
        if (mostRecent < yesterday)
        {
            return 0; // Streak broken
        }

        int streak = 0;
        var expectedDate = mostRecent;

        foreach (var date in distinctDates)
        {
            if (date == expectedDate)
            {
                streak++;
                expectedDate = expectedDate.AddDays(-1);
            }
            else
            {
                break;
            }
        }

        return streak;
    }

    /// <summary>
    /// Deterministic trend algorithm: compares average of latest 3 scored sessions vs prior 3.
    /// Delta > +3.0 => Improving; Delta < -3.0 => NeedsSupport; otherwise Steady.
    /// </summary>
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
            // If fewer than 4 sessions, compare latest with oldest
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
