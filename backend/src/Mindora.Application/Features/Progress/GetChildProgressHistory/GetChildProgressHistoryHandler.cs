using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Features.Progress.Models;
using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Progress.GetChildProgressHistory;

public class GetChildProgressHistoryHandler
{
    private readonly ICurrentUserService _currentUserService;
    private readonly IApplicationDbContext _context;

    public GetChildProgressHistoryHandler(
        ICurrentUserService currentUserService,
        IApplicationDbContext context)
    {
        _currentUserService = currentUserService;
        _context = context;
    }

    public async Task<IReadOnlyList<SessionHistoryPointDto>> HandleAsync(Guid childId, CancellationToken cancellationToken = default)
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
            throw new ForbiddenException("You do not have permission to view child progress history.");
        }

        // 3. Query completed sessions ordered chronologically
        var completedSessions = _context.Sessions
            .Where(s => s.ChildId == childId && s.Status == SessionStatus.Completed)
            .OrderBy(s => s.StartTimeUtc)
            .ToList();

        if (!completedSessions.Any())
        {
            return Array.Empty<SessionHistoryPointDto>();
        }

        var sessionIds = completedSessions.Select(s => s.Id).ToList();
        var activityIds = completedSessions.Select(s => s.ActivityId).Distinct().ToList();

        var activities = _context.Activities
            .Where(a => activityIds.Contains(a.Id))
            .ToDictionary(a => a.Id, a => a.Title);

        var analysisResults = _context.SessionAnalysisResults
            .Where(r => sessionIds.Contains(r.SessionId))
            .ToDictionary(r => r.SessionId);

        var historyPoints = completedSessions.Select(s =>
        {
            string title = activities.TryGetValue(s.ActivityId, out var actTitle) ? actTitle : "Activity";
            decimal score = analysisResults.TryGetValue(s.Id, out var analysis) ? analysis.OverallPerformanceScore : 0.00m;
            int duration = s.ActualDurationSeconds ?? 0;
            DateTime completedAt = s.EndTimeUtc ?? s.StartTimeUtc;

            return new SessionHistoryPointDto(
                s.Id,
                title,
                s.Domain.ToString(),
                score,
                duration,
                completedAt);
        }).ToList();

        return historyPoints;
    }
}
