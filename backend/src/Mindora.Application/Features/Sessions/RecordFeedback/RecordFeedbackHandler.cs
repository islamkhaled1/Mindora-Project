using FluentValidation;
using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Common.Validation;
using Mindora.Application.Features.Sessions.Models;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Sessions.RecordFeedback;

public class RecordFeedbackHandler
{
    private readonly ICurrentUserService _currentUserService;
    private readonly IApplicationDbContext _context;
    private readonly IValidator<RecordFeedbackRequest> _validator;

    public RecordFeedbackHandler(
        ICurrentUserService currentUserService,
        IApplicationDbContext context,
        IValidator<RecordFeedbackRequest> validator)
    {
        _currentUserService = currentUserService;
        _context = context;
        _validator = validator;
    }

    public async Task<CompletedSessionDto> HandleAsync(
        Guid sessionId,
        RecordFeedbackRequest request,
        CancellationToken cancellationToken = default)
    {
        if (!_currentUserService.IsAuthenticated || _currentUserService.UserId == null)
        {
            throw new UnauthorizedException("User is not authenticated.");
        }

        if (_currentUserService.Role != UserRole.Parent)
        {
            throw new ForbiddenException("Only parents are permitted to submit session feedback.");
        }

        await _validator.ValidateAndThrowAppAsync(request, cancellationToken);

        var userId = _currentUserService.UserId.Value;
        var parentProfile = _context.ParentProfiles.FirstOrDefault(p => p.UserId == userId);
        if (parentProfile == null)
        {
            throw new NotFoundException("ParentProfile", userId);
        }

        var session = _context.Sessions.FirstOrDefault(s => s.Id == sessionId);
        if (session == null)
        {
            throw new NotFoundException("Session", sessionId);
        }

        var ownsChild = _context.Children.Any(c => c.Id == session.ChildId && c.ParentId == parentProfile.Id);
        if (!ownsChild)
        {
            throw new NotFoundException("Session", sessionId);
        }

        if (session.Status != SessionStatus.Completed)
        {
            throw new ConflictException("Parent feedback can only be recorded for a completed session.");
        }

        session.RecordParentFeedback(request.Rating, request.Notes);
        await _context.SaveChangesAsync(cancellationToken);

        var analysisResult = _context.SessionAnalysisResults.FirstOrDefault(r => r.SessionId == sessionId);
        var metrics = _context.PerformanceMetrics
            .Where(m => m.SessionId == sessionId)
            .OrderBy(m => m.TimestampUtc)
            .Select(m => new PerformanceMetricDto(m.Id, m.SessionId, m.MetricType, m.Value, m.TimestampUtc))
            .ToList();

        SessionAnalysisResultDto? analysisDto = null;
        if (analysisResult != null)
        {
            analysisDto = new SessionAnalysisResultDto(
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

        return new CompletedSessionDto(
            session.Id,
            session.ChildId,
            session.ActivityId,
            session.Domain.ToString(),
            session.Status.ToString(),
            session.StartTimeUtc,
            session.EndTimeUtc,
            session.ActualDurationSeconds,
            analysisDto,
            metrics,
            session.ParentRating?.ToString(),
            session.ParentNotes);
    }
}
