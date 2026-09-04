using FluentValidation;
using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Features.Children.Models;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Children.AssignDoctor;

public class AssignDoctorHandler
{
    private readonly ICurrentUserService _currentUserService;
    private readonly IApplicationDbContext _context;
    private readonly IValidator<AssignDoctorRequest> _validator;

    public AssignDoctorHandler(
        ICurrentUserService currentUserService,
        IApplicationDbContext context,
        IValidator<AssignDoctorRequest> validator)
    {
        _currentUserService = currentUserService;
        _context = context;
        _validator = validator;
    }

    public async Task<DoctorAssignmentDto> HandleAsync(
        Guid childId,
        AssignDoctorRequest request,
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

        // 1. Authorize: Only owning Parent or self-assigning Doctor
        if (role == UserRole.Parent)
        {
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
        }
        else if (role == UserRole.Doctor)
        {
            var doctorProfile = _context.DoctorProfiles.FirstOrDefault(d => d.UserId == userId);
            if (doctorProfile == null)
            {
                throw new NotFoundException("DoctorProfile", userId);
            }

            // Doctor self-assignment rule: Doctor can only assign themselves to the child
            if (request.DoctorId != doctorProfile.Id)
            {
                throw new ForbiddenException("Doctors are only permitted to self-assign to a child.");
            }

            var childExists = _context.Children.Any(c => c.Id == childId);
            if (!childExists)
            {
                throw new NotFoundException("Child", childId);
            }
        }
        else
        {
            throw new ForbiddenException("You do not have permission to assign doctors.");
        }

        // 2. Verify Doctor exists
        var doctorExists = _context.DoctorProfiles.Any(d => d.Id == request.DoctorId);
        if (!doctorExists)
        {
            throw new NotFoundException("Doctor", request.DoctorId);
        }

        // 3. Prevent duplicate active assignment, or reactivate inactive historical assignment
        var existingAssignment = _context.DoctorChildAssignments
            .FirstOrDefault(a => a.DoctorId == request.DoctorId && a.ChildId == childId);

        if (existingAssignment != null)
        {
            if (existingAssignment.IsActive)
            {
                throw new ConflictException("Doctor is already actively assigned to this child.");
            }

            // Reactivate historical assignment preserving history
            existingAssignment.Reactivate();
            await _context.SaveChangesAsync(cancellationToken);

            return new DoctorAssignmentDto(
                existingAssignment.Id,
                existingAssignment.DoctorId,
                existingAssignment.ChildId,
                existingAssignment.AssignedAtUtc,
                existingAssignment.IsActive);
        }

        // 4. Create new active assignment
        var newAssignment = DoctorChildAssignment.Create(request.DoctorId, childId);
        _context.Add(newAssignment);
        await _context.SaveChangesAsync(cancellationToken);

        return new DoctorAssignmentDto(
            newAssignment.Id,
            newAssignment.DoctorId,
            newAssignment.ChildId,
            newAssignment.AssignedAtUtc,
            newAssignment.IsActive);
    }
}
