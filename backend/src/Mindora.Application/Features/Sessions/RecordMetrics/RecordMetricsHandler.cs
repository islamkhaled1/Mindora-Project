using FluentValidation;
using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Features.Sessions.Models;
using Mindora.Domain.Common;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Sessions.RecordMetrics;

public class RecordMetricsHandler
{
    private readonly ICurrentUserService _currentUserService;
    private readonly IApplicationDbContext _context;
    private readonly IValidator<RecordMetricsRequest> _validator;

    public RecordMetricsHandler(
        ICurrentUserService currentUserService,
        IApplicationDbContext context,
        IValidator<RecordMetricsRequest> validator)
    {
        _currentUserService = currentUserService;
        _context = context;
        _validator = validator;
    }

    public async Task<IReadOnlyList<PerformanceMetricDto>> HandleAsync(
        Guid sessionId,
        RecordMetricsRequest request,
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

        // 2. Authorize caller for Session's Child
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
            throw new ForbiddenException("You do not have permission to record metrics.");
        }

        // 3. Enforce session state is Started
        if (session.Status != SessionStatus.Started)
        {
            throw new DomainException($"Cannot add metrics to a session with status '{session.Status}'. Metrics may only be added while the session is Started.");
        }

        // 4. Add metrics atomically through domain model
        var resultList = new List<PerformanceMetricDto>();
        foreach (var input in request.Metrics)
        {
            var metric = session.AddMetric(input.MetricType, input.Value);
            _context.Add(metric);
            resultList.Add(new PerformanceMetricDto(
                metric.Id,
                metric.SessionId,
                metric.MetricType,
                metric.Value,
                metric.TimestampUtc));
        }

        await _context.SaveChangesAsync(cancellationToken);

        return resultList;
    }
}
