using FluentValidation;
using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Common.Validation;
using Mindora.Application.Features.Assessments.Models;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Assessments.RecordBaselineAssessment;

public class RecordBaselineAssessmentHandler
{
    private readonly ICurrentUserService _currentUserService;
    private readonly IApplicationDbContext _context;
    private readonly IValidator<RecordBaselineAssessmentRequest> _validator;

    public RecordBaselineAssessmentHandler(
        ICurrentUserService currentUserService,
        IApplicationDbContext context,
        IValidator<RecordBaselineAssessmentRequest> validator)
    {
        _currentUserService = currentUserService;
        _context = context;
        _validator = validator;
    }

    public async Task<BaselineAssessmentDto> HandleAsync(
        Guid childId,
        RecordBaselineAssessmentRequest request,
        CancellationToken cancellationToken = default)
    {
        if (!_currentUserService.IsAuthenticated || _currentUserService.UserId == null)
        {
            throw new UnauthorizedException("User is not authenticated.");
        }

        await _validator.ValidateAndThrowAppAsync(request, cancellationToken);

        var userId = _currentUserService.UserId.Value;
        var role = _currentUserService.Role;

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

            var isAssigned = _context.DoctorChildAssignments
                .Any(a => a.DoctorId == doctorProfile.Id && a.ChildId == childId && a.IsActive);
            if (!isAssigned)
            {
                throw new NotFoundException("Child", childId);
            }
        }
        else
        {
            throw new ForbiddenException("You do not have permission to record baseline assessments.");
        }

        var assessment = BaselineAssessment.Create(
            childId,
            request.OverallScore,
            request.CognitiveScore,
            request.CommunicationScore,
            request.MotorScore,
            request.EmotionalScore,
            DateTime.UtcNow);

        _context.Add(assessment);
        await _context.SaveChangesAsync(cancellationToken);

        return new BaselineAssessmentDto(
            assessment.Id,
            assessment.ChildId,
            assessment.OverallScore,
            assessment.CognitiveScore,
            assessment.CommunicationScore,
            assessment.MotorScore,
            assessment.EmotionalScore,
            assessment.CompletedAtUtc);
    }
}
