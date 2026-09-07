using FluentValidation;
using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Common.Validation;
using Mindora.Application.Features.Children.Models;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Doctor.LinkChild;

public class LinkChildHandler
{
    private readonly ICurrentUserService _currentUserService;
    private readonly IApplicationDbContext _context;
    private readonly ILinkingRateLimiter _rateLimiter;
    private readonly IValidator<LinkChildRequest> _validator;

    public LinkChildHandler(
        ICurrentUserService currentUserService,
        IApplicationDbContext context,
        ILinkingRateLimiter rateLimiter,
        IValidator<LinkChildRequest> validator)
    {
        _currentUserService = currentUserService;
        _context = context;
        _rateLimiter = rateLimiter;
        _validator = validator;
    }

    public async Task<DoctorAssignmentDto> HandleAsync(LinkChildRequest request, CancellationToken cancellationToken = default)
    {
        if (!_currentUserService.IsAuthenticated || _currentUserService.UserId == null)
        {
            throw new UnauthorizedException("User is not authenticated.");
        }

        if (_currentUserService.Role != UserRole.Doctor)
        {
            throw new ForbiddenException("Only doctors are permitted to link children using a linking code.");
        }

        await _validator.ValidateAndThrowAppAsync(request, cancellationToken);

        var userId = _currentUserService.UserId.Value;
        var doctorProfile = _context.DoctorProfiles.FirstOrDefault(d => d.UserId == userId);
        if (doctorProfile == null)
        {
            throw new NotFoundException("DoctorProfile", userId);
        }

        // Check rate limiting / abuse lockout for this doctor
        if (_rateLimiter.IsLimitExceeded(doctorProfile.Id))
        {
            throw new ForbiddenException("Too many failed linking attempts. Please wait 15 minutes before trying again.");
        }

        var codeHash = ChildLinkingCode.ComputeHash(request.LinkingCode);
        var linkingCode = _context.ChildLinkingCodes
            .FirstOrDefault(c => c.CodeHash == codeHash);

        if (linkingCode == null || linkingCode.IsRedeemed || linkingCode.IsExpired(DateTime.UtcNow))
        {
            _rateLimiter.RecordFailedAttempt(doctorProfile.Id);
            throw new NotFoundException("LinkingCode", "Invalid or expired linking code.");
        }

        var child = _context.Children.FirstOrDefault(c => c.Id == linkingCode.ChildId);
        if (child == null)
        {
            _rateLimiter.RecordFailedAttempt(doctorProfile.Id);
            throw new NotFoundException("Child", linkingCode.ChildId);
        }

        // Check if an assignment already exists
        var existingAssignment = _context.DoctorChildAssignments
            .FirstOrDefault(a => a.DoctorId == doctorProfile.Id && a.ChildId == child.Id);

        if (existingAssignment != null)
        {
            if (existingAssignment.IsActive)
            {
                throw new ConflictException("Doctor is already actively assigned to this child.");
            }

            // Reactivate inactive historical assignment
            existingAssignment.Reactivate();
        }
        else
        {
            existingAssignment = DoctorChildAssignment.Create(doctorProfile.Id, child.Id);
            _context.Add(existingAssignment);
        }

        // Mark linking code redeemed
        linkingCode.Redeem(doctorProfile.Id, DateTime.UtcNow);

        await _context.SaveChangesAsync(cancellationToken);

        // Reset failed attempt counter on success
        _rateLimiter.ResetAttempts(doctorProfile.Id);

        return new DoctorAssignmentDto(
            existingAssignment.Id,
            existingAssignment.DoctorId,
            existingAssignment.ChildId,
            existingAssignment.AssignedAtUtc,
            existingAssignment.IsActive);
    }
}
