using FluentValidation;
using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Common.Models;
using Mindora.Application.Features.Sessions.Models;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Sessions.CompleteSession;

public class CompleteSessionHandler
{
    private readonly ICurrentUserService _currentUserService;
    private readonly IApplicationDbContext _context;
    private readonly IAiAnalysisService _aiAnalysisService;
    private readonly IValidator<CompleteSessionRequest> _validator;

    public CompleteSessionHandler(
        ICurrentUserService currentUserService,
        IApplicationDbContext context,
        IAiAnalysisService aiAnalysisService,
        IValidator<CompleteSessionRequest> validator)
    {
        _currentUserService = currentUserService;
        _context = context;
        _aiAnalysisService = aiAnalysisService;
        _validator = validator;
    }

    public async Task<CompletedSessionDto> HandleAsync(
        Guid sessionId,
        CompleteSessionRequest request,
        CancellationToken cancellationToken = default)
    {
        if (!_currentUserService.IsAuthenticated || _currentUserService.UserId == null)
        {
            throw new UnauthorizedException("User is not authenticated.");
        }

        var validationResult = await _validator.ValidateAsync(request, cancellationToken);
        if (!validationResult.IsValid)
        {
            var failures = validationResult.Errors
                .Select(e => new FluentValidation.Results.ValidationFailure(e.PropertyName, e.ErrorMessage));
            throw new Mindora.Application.Common.Exceptions.ValidationException(failures);
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
            throw new ForbiddenException("You do not have permission to complete sessions.");
        }

        // 3. Idempotency Check: if already completed, return existing result without re-executing AI
        if (session.Status == SessionStatus.Completed)
        {
            var existingAnalysis = _context.SessionAnalysisResults.FirstOrDefault(r => r.SessionId == sessionId);
            var existingMetrics = _context.PerformanceMetrics
                .Where(m => m.SessionId == sessionId)
                .OrderBy(m => m.TimestampUtc)
                .Select(m => new PerformanceMetricDto(m.Id, m.SessionId, m.MetricType, m.Value, m.TimestampUtc))
                .ToList();

            return new CompletedSessionDto(
                session.Id,
                session.ChildId,
                session.ActivityId,
                session.Domain.ToString(),
                session.Status.ToString(),
                session.StartTimeUtc,
                session.EndTimeUtc,
                session.ActualDurationSeconds,
                existingAnalysis != null ? MapAnalysisResultDto(existingAnalysis) : null,
                existingMetrics);
        }

        // 4. Invalid transition check: Abandoned sessions cannot be completed
        if (session.Status == SessionStatus.Abandoned)
        {
            throw new ConflictException("Cannot complete an abandoned session. Invalid lifecycle transition.");
        }

        // 5. Gather existing recorded telemetry metrics
        var existingMetricEntities = _context.PerformanceMetrics
            .Where(m => m.SessionId == sessionId)
            .ToList();

        var allAiMetrics = existingMetricEntities
            .Select(m => new AiMetricInput(m.MetricType, m.Value, m.TimestampUtc))
            .ToList();

        // Include valid final metrics in analysis input if provided in request
        if (request.Metrics != null && request.Metrics.Count > 0)
        {
            foreach (var m in request.Metrics)
            {
                allAiMetrics.Add(new AiMetricInput(m.MetricType, m.Value, DateTime.UtcNow));
            }
        }

        // 6. Build AiSessionAnalysisRequest using authoritative server data
        var activity = _context.Activities.FirstOrDefault(a => a.Id == session.ActivityId);
        var baseDifficulty = activity?.BaseDifficulty ?? DifficultyLevel.Beginner;
        int childAgeYears = Math.Max(1, DateTime.UtcNow.Year - child.DateOfBirth.Year);

        var aiRequest = new AiSessionAnalysisRequest(
            session.Id,
            childAgeYears,
            session.Domain,
            baseDifficulty,
            request.ActualDurationSeconds,
            allAiMetrics);

        // 7. CRITICAL: Execute AI analysis OUTSIDE of any database transaction
        var aiResult = await _aiAnalysisService.AnalyzeSessionPerformanceAsync(aiRequest, cancellationToken);

        // 8. Now persist state changes atomically
        // Add final metrics to session
        if (request.Metrics != null && request.Metrics.Count > 0)
        {
            foreach (var m in request.Metrics)
            {
                var newMetric = session.AddMetric(m.MetricType, m.Value);
                _context.Add(newMetric);
            }
        }

        // Complete the session through Domain method
        session.Complete(DateTime.UtcNow, request.ActualDurationSeconds);

        // Create and attach SessionAnalysisResult
        var analysisResult = SessionAnalysisResult.Create(
            session.Id,
            aiResult.OverallPerformanceScore,
            aiResult.DomainScore,
            aiResult.SupportiveObservations,
            aiResult.FatigueObserved,
            aiResult.RecommendedDifficultyAdjustment,
            aiResult.AdaptiveParameters,
            DateTime.UtcNow,
            aiResult.IsFallbackResult);

        session.AttachAnalysisResult(analysisResult);
        _context.Add(analysisResult);

        await _context.SaveChangesAsync(cancellationToken);

        // 9. Load complete metric list for response
        var finalMetricsList = _context.PerformanceMetrics
            .Where(m => m.SessionId == sessionId)
            .OrderBy(m => m.TimestampUtc)
            .Select(m => new PerformanceMetricDto(m.Id, m.SessionId, m.MetricType, m.Value, m.TimestampUtc))
            .ToList();

        return new CompletedSessionDto(
            session.Id,
            session.ChildId,
            session.ActivityId,
            session.Domain.ToString(),
            session.Status.ToString(),
            session.StartTimeUtc,
            session.EndTimeUtc,
            session.ActualDurationSeconds,
            MapAnalysisResultDto(analysisResult),
            finalMetricsList);
    }

    private static SessionAnalysisResultDto MapAnalysisResultDto(SessionAnalysisResult result)
    {
        return new SessionAnalysisResultDto(
            result.Id,
            result.SessionId,
            result.OverallPerformanceScore,
            result.DomainScore,
            result.SupportiveObservations,
            result.FatigueObserved,
            result.RecommendedDifficultyAdjustment.ToString(),
            result.AdaptiveParametersJson,
            result.AnalyzedAtUtc,
            result.IsFallbackResult);
    }
}
