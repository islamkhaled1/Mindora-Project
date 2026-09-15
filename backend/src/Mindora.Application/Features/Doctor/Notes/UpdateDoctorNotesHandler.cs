using FluentValidation;
using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Common.Validation;
using Mindora.Application.Features.Doctor.Models;
using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Doctor.Notes;

public class UpdateDoctorNotesHandler
{
    private readonly ICurrentUserService _currentUserService;
    private readonly IApplicationDbContext _context;
    private readonly IValidator<UpdateDoctorNotesRequest> _validator;

    public UpdateDoctorNotesHandler(
        ICurrentUserService currentUserService,
        IApplicationDbContext context,
        IValidator<UpdateDoctorNotesRequest> validator)
    {
        _currentUserService = currentUserService;
        _context = context;
        _validator = validator;
    }

    public async Task<DoctorNotesDto> HandleAsync(
        Guid childId,
        UpdateDoctorNotesRequest request,
        CancellationToken cancellationToken = default)
    {
        if (!_currentUserService.IsAuthenticated || _currentUserService.UserId == null)
        {
            throw new UnauthorizedException("User is not authenticated.");
        }

        if (_currentUserService.Role != UserRole.Doctor)
        {
            throw new ForbiddenException("Only doctors are permitted to record clinical notes.");
        }

        await _validator.ValidateAndThrowAppAsync(request, cancellationToken);

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

        assignment.UpdateDoctorNotes(request.Notes, DateTime.UtcNow);
        await _context.SaveChangesAsync(cancellationToken);

        return new DoctorNotesDto(
            childId,
            assignment.DoctorNotes,
            assignment.DoctorNotesUpdatedAtUtc);
    }
}
