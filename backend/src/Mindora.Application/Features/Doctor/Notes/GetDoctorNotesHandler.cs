using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Features.Doctor.Models;
using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Doctor.Notes;

public class GetDoctorNotesHandler
{
    private readonly ICurrentUserService _currentUserService;
    private readonly IApplicationDbContext _context;

    public GetDoctorNotesHandler(
        ICurrentUserService currentUserService,
        IApplicationDbContext context)
    {
        _currentUserService = currentUserService;
        _context = context;
    }

    public async Task<DoctorNotesDto> HandleAsync(
        Guid childId,
        CancellationToken cancellationToken = default)
    {
        if (!_currentUserService.IsAuthenticated || _currentUserService.UserId == null)
        {
            throw new UnauthorizedException("User is not authenticated.");
        }

        if (_currentUserService.Role != UserRole.Doctor)
        {
            throw new ForbiddenException("Only doctors are permitted to view clinical notes.");
        }

        var userId = _currentUserService.UserId.Value;
        var doctorProfile = _context.DoctorProfiles.FirstOrDefault(d => d.UserId == userId);
        if (doctorProfile == null)
        {
            throw new NotFoundException("DoctorProfile", userId);
        }

        var assignment = _context.DoctorChildAssignments
            .FirstOrDefault(a => a.DoctorId == doctorProfile.Id && a.ChildId == childId && a.IsActive);

        if (assignment == null)
        {
            throw new NotFoundException("Child", childId);
        }

        return new DoctorNotesDto(
            childId,
            assignment.DoctorNotes,
            assignment.DoctorNotesUpdatedAtUtc);
    }
}
