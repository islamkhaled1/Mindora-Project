using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Features.Sessions.Models;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Sessions.GetSessionDetails;

public class GetSessionDetailsHandler
{
    private readonly ICurrentUserService _currentUserService;
    private readonly IApplicationDbContext _context;

    public GetSessionDetailsHandler(
        ICurrentUserService currentUserService,
        IApplicationDbContext context)
    {
        _currentUserService = currentUserService;
        _context = context;
    }

    public async Task<SessionDetailsDto> HandleAsync(Guid sessionId, CancellationToken cancellationToken = default)
    {
        if (!_currentUserService.IsAuthenticated || _currentUserService.UserId == null)
        {
            throw new UnauthorizedException("User is not authenticated.");
        }

        var userId = _currentUserService.UserId.Value;
        var role = _currentUserService.Role;

        // 1. Load Session
        var session = _context.Sessions.FirstOrDefault(s => s.Id == sessionId);
        if (session == null)
        {
            throw new NotFoundException("Session", sessionId);
        }

        // 2. Authorize caller for Child (IDOR protection)
        var child = _context.Children.FirstOrDefault(c => c.Id == session.ChildId);
        if (child == null)
        {
            throw new NotFoundException("Session", sessionId);
        }

        if (role == UserRole.Parent)
        {
            var parentProfile = _context.ParentProfiles.FirstOrDefault(p => p.UserId == userId);
            if (parentProfile == null || child.ParentId != parentProfile.Id)
            {
                throw new NotFoundException("Session", sessionId);
            }
        }
        else if (role == UserRole.Doctor)
        {
            var doctorProfile = _context.DoctorProfiles.FirstOrDefault(d => d.UserId == userId);
            if (doctorProfile == null)
            {
                throw new NotFoundException("Session", sessionId);
            }

            var isAssigned = _context.DoctorChildAssignments
                .Any(a => a.DoctorId == doctorProfile.Id && a.ChildId == session.ChildId && a.IsActive);
            if (!isAssigned)
            {
                throw new NotFoundException("Session", sessionId);
            }
        }
        else
        {
            throw new ForbiddenException("You do not have permission to view session details.");
        }

        // 3. Load Activity summary
        var activity = _context.Activities.FirstOrDefault(a => a.Id == session.ActivityId);
        var activitySummary = new SessionActivitySummaryDto(
            activity?.Id ?? session.ActivityId,
            activity?.Title ?? "Activity",
            (activity?.Domain ?? session.Domain).ToString(),
            (activity?.BaseDifficulty ?? DifficultyLevel.Beginner).ToString());

        // 4. Load Metrics
        var metrics = _context.PerformanceMetrics
            .Where(m => m.SessionId == sessionId)
            .OrderBy(m => m.TimestampUtc)
            .Select(m => new PerformanceMetricDto(m.Id, m.SessionId, m.MetricType, m.Value, m.TimestampUtc))
            .ToList();

        // 5. Load Analysis Result if completed
        var analysisResult = _context.SessionAnalysisResults.FirstOrDefault(r => r.SessionId == sessionId);
        SessionAnalysisResultDto? analysisResultDto = null;
        if (analysisResult != null)
        {
            analysisResultDto = new SessionAnalysisResultDto(
                analysisResult.Id,
                analysisResult.SessionId,
                analysisResult.OverallPerformanceScore,
                analysisResult.DomainScore,
                analysisResult.SupportiveObservations,
                analysisResult.FatigueObserved,
                analysisResult.RecommendedDifficultyAdjustment.ToString(),
                analysisResult.AdaptiveParametersJson,
                analysisResult.AnalyzedAtUtc,
                analysisResult.IsFallbackResult);
        }

        return new SessionDetailsDto(
            session.Id,
            session.ChildId,
            activitySummary,
            session.Domain.ToString(),
            session.Status.ToString(),
            session.StartTimeUtc,
            session.EndTimeUtc,
            session.ActualDurationSeconds,
            analysisResultDto,
            metrics,
            session.ParentRating?.ToString(),
            session.ParentNotes);
    }
}
