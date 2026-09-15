using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Features.Children.Models;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Children.GetChildDetails;

public class GetChildDetailsHandler
{
    private readonly ICurrentUserService _currentUserService;
    private readonly IApplicationDbContext _context;

    public GetChildDetailsHandler(
        ICurrentUserService currentUserService,
        IApplicationDbContext context)
    {
        _currentUserService = currentUserService;
        _context = context;
    }

    public async Task<ChildDetailsDto> HandleAsync(Guid childId, CancellationToken cancellationToken = default)
    {
        if (!_currentUserService.IsAuthenticated || _currentUserService.UserId == null)
        {
            throw new UnauthorizedException("User is not authenticated.");
        }

        var userId = _currentUserService.UserId.Value;
        var role = _currentUserService.Role;

        Child? child = null;

        if (role == UserRole.Parent)
        {
            var parentProfile = _context.ParentProfiles.FirstOrDefault(p => p.UserId == userId);
            if (parentProfile == null)
            {
                throw new NotFoundException("ParentProfile", userId);
            }

            // Secure ownership check: query by childId AND parentId to avoid leaking existence of unrelated children
            child = _context.Children.FirstOrDefault(c => c.Id == childId && c.ParentId == parentProfile.Id);
            if (child == null)
            {
                throw new NotFoundException("Child", childId);
            }
        }
        else if (role == UserRole.Doctor)
        {
            var doctorProfile = _context.DoctorProfiles.FirstOrDefault(d => d.UserId == userId);
            if (doctorProfile == null)
            {
                throw new NotFoundException("DoctorProfile", userId);
            }

            // Verify active clinical assignment to prevent unauthorized access
            var isAssigned = _context.DoctorChildAssignments
                .Any(a => a.DoctorId == doctorProfile.Id && a.ChildId == childId && a.IsActive);

            if (!isAssigned)
            {
                // Return NotFoundException to prevent disclosing whether an unassigned child exists
                throw new NotFoundException("Child", childId);
            }

            child = _context.Children.FirstOrDefault(c => c.Id == childId);
            if (child == null)
            {
                throw new NotFoundException("Child", childId);
            }
        }
        else
        {
            throw new ForbiddenException("You do not have permission to view child details.");
        }

        // Fetch active doctor assignments for this child
        var activeAssignments = _context.DoctorChildAssignments
            .Where(a => a.ChildId == childId && a.IsActive)
            .ToList();

        var doctorIds = activeAssignments.Select(a => a.DoctorId).ToList();
        var doctors = _context.DoctorProfiles
            .Where(d => doctorIds.Contains(d.Id))
            .ToDictionary(d => d.Id);

        var assignedDoctorsDto = activeAssignments
            .Where(a => doctors.ContainsKey(a.DoctorId))
            .Select(a =>
            {
                var doc = doctors[a.DoctorId];
                return new AssignedDoctorSummaryDto(
                    doc.Id,
                    doc.Specialization,
                    doc.ClinicName,
                    a.AssignedAtUtc,
                    doc.ReferralCode);
            })
            .ToList();

        return new ChildDetailsDto(
            child.Id,
            child.ParentId,
            child.FullName,
            child.DateOfBirth,
            child.SupportNotes,
            child.CurrentMovementLevel.ToString(),
            child.CurrentSpeechLevel.ToString(),
            child.CurrentAttentionLevel.ToString(),
            child.CreatedAtUtc,
            assignedDoctorsDto,
            child.Gender?.ToString(),
            child.Diagnosis,
            child.AvatarUrl,
            child.SupportLevel?.ToString(),
            child.HearingStatus?.ToString(),
            child.VisionStatus?.ToString(),
            child.FocusDurationMinutes,
            child.PreferredPracticeTime,
            child.PreferredActivityType?.ToString());
    }
}
