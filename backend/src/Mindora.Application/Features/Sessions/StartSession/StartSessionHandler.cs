using FluentValidation;
using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Features.Sessions.Models;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Sessions.StartSession;

public class StartSessionHandler
{
    private readonly ICurrentUserService _currentUserService;
    private readonly IApplicationDbContext _context;
    private readonly IValidator<StartSessionRequest> _validator;

    public StartSessionHandler(
        ICurrentUserService currentUserService,
        IApplicationDbContext context,
        IValidator<StartSessionRequest> validator)
    {
        _currentUserService = currentUserService;
        _context = context;
        _validator = validator;
    }

    public async Task<SessionDto> HandleAsync(StartSessionRequest request, CancellationToken cancellationToken = default)
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

        // 1. Verify Child exists and is not soft-deleted
        var child = _context.Children.FirstOrDefault(c => c.Id == request.ChildId);
        if (child == null)
        {
            throw new NotFoundException("Child", request.ChildId);
        }

        // 2. Authorize caller for Child (IDOR protection)
        if (role == UserRole.Parent)
        {
            var parentProfile = _context.ParentProfiles.FirstOrDefault(p => p.UserId == userId);
            if (parentProfile == null || child.ParentId != parentProfile.Id)
            {
                throw new NotFoundException("Child", request.ChildId);
            }
        }
        else if (role == UserRole.Doctor)
        {
            var doctorProfile = _context.DoctorProfiles.FirstOrDefault(d => d.UserId == userId);
            if (doctorProfile == null)
            {
                throw new NotFoundException("Child", request.ChildId);
            }

            var isAssigned = _context.DoctorChildAssignments
                .Any(a => a.DoctorId == doctorProfile.Id && a.ChildId == request.ChildId && a.IsActive);
            if (!isAssigned)
            {
                throw new NotFoundException("Child", request.ChildId);
            }
        }
        else
        {
            throw new ForbiddenException("You do not have permission to start sessions.");
        }

        // 3. Verify Activity exists and is active
        var activity = _context.Activities.FirstOrDefault(a => a.Id == request.ActivityId && a.IsActive);
        if (activity == null)
        {
            throw new NotFoundException("Activity", request.ActivityId);
        }

        // 4. Create Session deriving authoritative Domain from Activity.Domain
        var session = Session.Start(child.Id, activity.Id, activity.Domain);
        _context.Add(session);
        await _context.SaveChangesAsync(cancellationToken);

        return new SessionDto(
            session.Id,
            session.ChildId,
            session.ActivityId,
            session.Domain.ToString(),
            session.Status.ToString(),
            session.StartTimeUtc);
    }
}
