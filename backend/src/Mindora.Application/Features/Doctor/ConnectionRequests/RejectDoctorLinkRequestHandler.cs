using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Doctor.ConnectionRequests;

public class RejectDoctorLinkRequestHandler
{
    private readonly ICurrentUserService _currentUserService;
    private readonly IApplicationDbContext _context;

    public RejectDoctorLinkRequestHandler(
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
            throw new ForbiddenException("Only doctors are permitted to reject connection requests.");
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
            throw new ForbiddenException("Doctor is not authorized to reject requests belonging to another doctor.");
        }

        if (request.Status != DoctorLinkRequestStatus.Pending)
        {
            throw new ConflictException($"Cannot reject request. Current status is '{request.Status}'. Only Pending requests can be rejected.");
        }

        // Mark request as Rejected (NO DoctorChildAssignment is created)
        request.Reject();

        await _context.SaveChangesAsync(cancellationToken);
    }
}
