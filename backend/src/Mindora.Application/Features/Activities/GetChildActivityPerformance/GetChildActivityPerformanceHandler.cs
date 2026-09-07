using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Features.Activities.Models;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Activities.GetChildActivityPerformance;

public class GetChildActivityPerformanceHandler
{
    private readonly ICurrentUserService _currentUserService;
    private readonly IApplicationDbContext _context;

    public GetChildActivityPerformanceHandler(
        ICurrentUserService currentUserService,
        IApplicationDbContext context)
    {
        _currentUserService = currentUserService;
        _context = context;
    }

    public async Task<IReadOnlyList<ActivityPerformanceDto>> HandleAsync(Guid childId, CancellationToken cancellationToken = default)
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
            throw new ForbiddenException("You do not have permission to view child activity performance.");
        }

        // 3. Batch query completed sessions ordered descending by time
        var completedSessions = _context.Sessions
            .Where(s => s.ChildId == childId && s.Status == SessionStatus.Completed)
            .OrderByDescending(s => s.StartTimeUtc)
            .ToList();

        if (!completedSessions.Any())
        {
            return Array.Empty<ActivityPerformanceDto>();
        }

        var sessionIds = completedSessions.Select(s => s.Id).ToList();
        var activityIds = completedSessions.Select(s => s.ActivityId).Distinct().ToList();

        // 4. Batch query activities and analysis results
        var activities = _context.Activities
            .Where(a => activityIds.Contains(a.Id))
            .ToDictionary(a => a.Id);

        var analysisResults = _context.SessionAnalysisResults
            .Where(r => sessionIds.Contains(r.SessionId))
            .ToDictionary(r => r.SessionId);

        // 5. Query relevant telemetry metrics without Cartesian product
        var performanceMetrics = _context.PerformanceMetrics
            .Where(m => sessionIds.Contains(m.SessionId))
            .Select(m => new { m.SessionId, m.MetricType, m.Value })
            .ToList();

        var metricsBySession = performanceMetrics
            .GroupBy(m => m.SessionId)
            .ToDictionary(g => g.Key, g => g.ToList());

        var resultList = new List<ActivityPerformanceDto>();

        // 6. Group by ActivityId to aggregate multi-session metrics
        var sessionsByActivity = completedSessions.GroupBy(s => s.ActivityId);

        foreach (var group in sessionsByActivity)
        {
            var activityId = group.Key;
            var groupSessions = group.ToList();

            if (!activities.TryGetValue(activityId, out var activity))
            {
                continue;
            }

            int timesPlayed = groupSessions.Count;
            int totalDurationSeconds = groupSessions.Sum(s => s.ActualDurationSeconds ?? 0);
            int totalPracticeMinutes = totalDurationSeconds / 60;

            var scoredScores = groupSessions
                .Where(s => analysisResults.ContainsKey(s.Id))
                .Select(s => analysisResults[s.Id].OverallPerformanceScore)
                .ToList();

            decimal avgScore = scoredScores.Any() ? Math.Round(scoredScores.Average(), 2) : 0.00m;
            decimal bestScore = scoredScores.Any() ? scoredScores.Max() : 0.00m;
            decimal latestScore = scoredScores.Any() ? scoredScores.First() : 0.00m;

            // Aggregate metrics across sessions for this activity
            var activitySessionIds = groupSessions.Select(s => s.Id).ToHashSet();
            var allActivityMetrics = performanceMetrics
                .Where(m => activitySessionIds.Contains(m.SessionId))
                .ToList();

            var accuracyList = allActivityMetrics
                .Where(m => string.Equals(m.MetricType, "AccuracyPercentage", StringComparison.OrdinalIgnoreCase))
                .Select(m => (decimal?)m.Value)
                .ToList();

            decimal? avgAccuracy = accuracyList.Any()
                ? Math.Round(accuracyList.Average()!.Value, 2)
                : null;

            var reactionList = allActivityMetrics
                .Where(m => string.Equals(m.MetricType, "ReactionTimeMs", StringComparison.OrdinalIgnoreCase))
                .Select(m => (decimal?)m.Value)
                .ToList();

            decimal? avgReactionTime = reactionList.Any()
                ? Math.Round(reactionList.Average()!.Value, 2)
                : null;

            var repList = allActivityMetrics
                .Where(m => string.Equals(m.MetricType, "RepetitionCount", StringComparison.OrdinalIgnoreCase))
                .Select(m => (decimal?)m.Value)
                .ToList();

            decimal? avgRepetitions = repList.Any()
                ? Math.Round(repList.Average()!.Value, 2)
                : null;

            DateTime lastPlayedUtc = groupSessions.First().StartTimeUtc;

            resultList.Add(new ActivityPerformanceDto(
                activity.Id,
                activity.Title,
                activity.Domain.ToString(),
                activity.BaseDifficulty.ToString(),
                timesPlayed,
                totalPracticeMinutes,
                avgScore,
                bestScore,
                latestScore,
                avgAccuracy,
                avgReactionTime,
                avgRepetitions,
                lastPlayedUtc));
        }

        return resultList.OrderByDescending(r => r.LastPlayedUtc).ToList();
    }
}
