using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Features.Sessions.Models;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Sessions.AbandonSession;

public class AbandonSessionHandler
{
    private readonly ICurrentUserService _currentUserService;
    private readonly IApplicationDbContext _context;

    public AbandonSessionHandler(
        ICurrentUserService currentUserService,
        IApplicationDbContext context)
    {
        _currentUserService = currentUserService;
        _context = context;
    }

    public async Task<SessionDto> HandleAsync(Guid sessionId, CancellationToken cancellationToken = default)
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

        // 2. Authorize caller for Session's Child (IDOR protection)
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
            throw new ForbiddenException("You do not have permission to abandon sessions.");
        }

        // 3. Idempotency Check: if already abandoned, return current state safely
        if (session.Status == SessionStatus.Abandoned)
        {
            return new SessionDto(
                session.Id,
                session.ChildId,
                session.ActivityId,
                session.Domain.ToString(),
                session.Status.ToString(),
                session.StartTimeUtc);
        }

        // 4. Invariant check: Cannot abandon a completed session
        if (session.Status == SessionStatus.Completed)
        {
            throw new ConflictException("Cannot abandon a completed session. Invalid lifecycle transition.");
        }

        // 5. Abandon session through Domain aggregate method
        session.Abandon(DateTime.UtcNow);
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
