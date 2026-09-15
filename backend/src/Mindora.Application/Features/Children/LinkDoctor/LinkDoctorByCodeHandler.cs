using FluentValidation;
using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Common.Validation;
using Mindora.Application.Features.Children.Models;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Children.LinkDoctor;

public class LinkDoctorByCodeHandler
{
    private readonly ICurrentUserService _currentUserService;
    private readonly IApplicationDbContext _context;
    private readonly IIdentityService _identityService;
    private readonly IValidator<LinkDoctorByCodeRequest> _validator;

    public LinkDoctorByCodeHandler(
        ICurrentUserService currentUserService,
        IApplicationDbContext context,
        IIdentityService identityService,
        IValidator<LinkDoctorByCodeRequest> validator)
    {
        _currentUserService = currentUserService;
        _context = context;
        _identityService = identityService;
        _validator = validator;
    }

    public async Task<DoctorLinkRequestDto> HandleAsync(
        Guid childId,
        LinkDoctorByCodeRequest request,
        CancellationToken cancellationToken = default)
    {
        if (!_currentUserService.IsAuthenticated || _currentUserService.UserId == null)
        {
            throw new UnauthorizedException("User is not authenticated.");
        }

        if (_currentUserService.Role != UserRole.Parent)
        {
            throw new ForbiddenException("Only parents are permitted to link a doctor to a child.");
        }

        await _validator.ValidateAndThrowAppAsync(request, cancellationToken);

        var userId = _currentUserService.UserId.Value;
        var parentProfile = _context.ParentProfiles.FirstOrDefault(p => p.UserId == userId);
        if (parentProfile == null)
        {
            throw new NotFoundException("ParentProfile", userId);
        }

        var ownsChild = _context.Children.Any(c => c.Id == childId && c.ParentId == parentProfile.Id);
        if (!ownsChild)
        {
            throw new NotFoundException("Child", childId);
        }

        var normalizedCode = request.DoctorCode.Trim().ToUpperInvariant();
        var doctor = _context.DoctorProfiles.FirstOrDefault(d => d.ReferralCode == normalizedCode);
        if (doctor == null)
        {
            throw new NotFoundException("Doctor", request.DoctorCode);
        }

        // Check if an active assignment already exists
        var isAlreadyLinked = _context.DoctorChildAssignments
            .Any(a => a.DoctorId == doctor.Id && a.ChildId == childId && a.IsActive);
        if (isAlreadyLinked)
        {
            throw new ConflictException("Doctor is already actively assigned to this child.");
        }

        // Check if a pending connection request already exists
        var existingPending = _context.DoctorLinkRequests
            .FirstOrDefault(r => r.DoctorId == doctor.Id && r.ChildId == childId && r.Status == DoctorLinkRequestStatus.Pending);
        if (existingPending != null)
        {
            throw new ConflictException("A pending connection request already exists for this doctor.");
        }

        // Create pending connection request (Approval required by Doctor)
        var linkRequest = DoctorLinkRequest.Create(doctor.Id, parentProfile.Id, childId);
        _context.Add(linkRequest);

        await _context.SaveChangesAsync(cancellationToken);

        var doctorUser = await _identityService.GetUserByIdAsync(doctor.UserId, cancellationToken);
        var doctorName = doctorUser.HasValue ? doctorUser.Value.FullName : "Specialist Doctor";

        return new DoctorLinkRequestDto(
            linkRequest.Id,
            linkRequest.DoctorId,
            linkRequest.ChildId,
            linkRequest.ParentId,
            linkRequest.Status.ToString(),
            linkRequest.CreatedAtUtc,
            linkRequest.RespondedAtUtc,
            doctorName,
            doctor.Specialization,
            doctor.ClinicName);
    }
}
