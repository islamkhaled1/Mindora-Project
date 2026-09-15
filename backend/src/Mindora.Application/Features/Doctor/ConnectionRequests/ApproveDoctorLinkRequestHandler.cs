using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Doctor.ConnectionRequests;

public class ApproveDoctorLinkRequestHandler
{
    private readonly ICurrentUserService _currentUserService;
    private readonly IApplicationDbContext _context;

    public ApproveDoctorLinkRequestHandler(
        ICurrentUserService currentUserService,
        IApplicationDbContext context)
    {
        _currentUserService = currentUserService;
        _context = context;
    }

    public async Task HandleAsync(Guid requestId, CancellationToken cancellationToken = default)
    {
        if (!_currentUserService.IsAuthenticated || _currentUserService.UserId == null)
        {
            throw new UnauthorizedException("User is not authenticated.");
        }

        if (_currentUserService.Role != UserRole.Doctor)
        {
            throw new ForbiddenException("Only doctors are permitted to approve connection requests.");
        }

        var userId = _currentUserService.UserId.Value;
        var doctorProfile = _context.DoctorProfiles.FirstOrDefault(d => d.UserId == userId);
        if (doctorProfile == null)
        {
            throw new NotFoundException("DoctorProfile", userId);
        }

        var request = _context.DoctorLinkRequests.FirstOrDefault(r => r.Id == requestId);
        if (request == null)
        {
            throw new NotFoundException("DoctorLinkRequest", requestId);
        }

        // Enforce doctor ownership
        if (request.DoctorId != doctorProfile.Id)
        {
            throw new ForbiddenException("Doctor is not authorized to approve requests belonging to another doctor.");
        }

        if (request.Status != DoctorLinkRequestStatus.Pending)
        {
            throw new ConflictException($"Cannot approve request. Current status is '{request.Status}'. Only Pending requests can be approved.");
        }

        // Mark request as Approved
        request.Approve();

        // Atomically create or reactivate DoctorChildAssignment in the same database transaction
        var existingAssignment = _context.DoctorChildAssignments
            .FirstOrDefault(a => a.DoctorId == request.DoctorId && a.ChildId == request.ChildId);

        if (existingAssignment != null)
        {
            if (!existingAssignment.IsActive)
            {
                existingAssignment.Reactivate();
            }
        }
        else
        {
            var newAssignment = DoctorChildAssignment.Create(request.DoctorId, request.ChildId);
            _context.Add(newAssignment);
        }

        // Atomic commit: request approval and assignment creation/reactivation succeed or fail together
        await _context.SaveChangesAsync(cancellationToken);
    }
}
