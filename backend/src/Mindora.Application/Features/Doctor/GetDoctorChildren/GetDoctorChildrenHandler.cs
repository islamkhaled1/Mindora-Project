using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Features.Doctor.Models;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Doctor.GetDoctorChildren;

public class GetDoctorChildrenHandler
{
    private readonly ICurrentUserService _currentUserService;
    private readonly IApplicationDbContext _context;

    public GetDoctorChildrenHandler(
        ICurrentUserService currentUserService,
        IApplicationDbContext context)
    {
        _currentUserService = currentUserService;
        _context = context;
    }

    public async Task<IReadOnlyList<DoctorChildCardDto>> HandleAsync(CancellationToken cancellationToken = default)
    {
        if (!_currentUserService.IsAuthenticated || _currentUserService.UserId == null)
        {
            throw new UnauthorizedException("User is not authenticated.");
        }

        if (_currentUserService.Role != UserRole.Doctor)
        {
            throw new ForbiddenException("Only doctors are permitted to view the assigned children roster.");
        }

        var userId = _currentUserService.UserId.Value;
        var doctorProfile = _context.DoctorProfiles.FirstOrDefault(d => d.UserId == userId);
        if (doctorProfile == null)
        {
            throw new NotFoundException("DoctorProfile", userId);
        }

        // Fetch active doctor-child assignments
        var activeAssignments = _context.DoctorChildAssignments
            .Where(a => a.DoctorId == doctorProfile.Id && a.IsActive)
            .OrderByDescending(a => a.AssignedAtUtc)
            .ToList();

        if (!activeAssignments.Any())
        {
            return Array.Empty<DoctorChildCardDto>();
        }

        var childIds = activeAssignments.Select(a => a.ChildId).Distinct().ToList();

        // Query active children (global query filter ensures !IsDeleted)
        var children = _context.Children
            .Where(c => childIds.Contains(c.Id))
            .ToDictionary(c => c.Id);

        // Batch query all completed sessions for these children
        var completedSessions = _context.Sessions
            .Where(s => childIds.Contains(s.ChildId) && s.Status == SessionStatus.Completed)
            .OrderByDescending(s => s.StartTimeUtc)
            .ToList();

        var sessionIds = completedSessions.Select(s => s.Id).ToList();

        // Batch query analysis results
        var analysisResults = _context.SessionAnalysisResults
            .Where(r => sessionIds.Contains(r.SessionId))
            .ToDictionary(r => r.SessionId);

        var sessionsByChild = completedSessions
            .GroupBy(s => s.ChildId)
            .ToDictionary(g => g.Key, g => g.ToList());

        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        var resultList = new List<DoctorChildCardDto>();

        foreach (var assignment in activeAssignments)
        {
            if (!children.TryGetValue(assignment.ChildId, out var child))
            {
                continue; // Child not found or soft-deleted
            }

            sessionsByChild.TryGetValue(child.Id, out var childSessions);
            childSessions ??= new List<Session>();

            int totalCompletedSessions = childSessions.Count;
            int totalPracticeMinutes = childSessions.Sum(s => s.ActualDurationSeconds ?? 0) / 60;

            var scoredScores = childSessions
                .Where(s => analysisResults.ContainsKey(s.Id))
                .Select(s => analysisResults[s.Id].OverallPerformanceScore)
                .ToList();

            decimal overallAvgScore = scoredScores.Any()
                ? Math.Round(scoredScores.Average(), 2)
                : 0.00m;

            string recentTrend = CalculatePerformanceTrend(scoredScores);
            DateTime? lastSessionDate = childSessions.FirstOrDefault()?.StartTimeUtc;

            int ageYears = today.Year - child.DateOfBirth.Year;
            if (child.DateOfBirth > today.AddYears(-ageYears))
            {
                ageYears--;
            }

            resultList.Add(new DoctorChildCardDto(
                child.Id,
                child.FullName,
                child.DateOfBirth,
                Math.Max(0, ageYears),
                child.SupportNotes,
                child.CurrentMovementLevel.ToString(),
                totalCompletedSessions,
                totalPracticeMinutes,
                overallAvgScore,
                recentTrend,
                lastSessionDate,
                assignment.AssignedAtUtc,
                child.Gender?.ToString(),
                child.AvatarUrl,
                child.SupportLevel?.ToString()));
        }

        return resultList;
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
