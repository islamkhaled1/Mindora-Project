using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Features.Assessments.Models;
using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Assessments.GetChildBaselineAssessment;

public class GetChildBaselineAssessmentHandler
{
    private readonly ICurrentUserService _currentUserService;
    private readonly IApplicationDbContext _context;

    public GetChildBaselineAssessmentHandler(
        ICurrentUserService currentUserService,
        IApplicationDbContext context)
    {
        _currentUserService = currentUserService;
        _context = context;
    }

    public async Task<BaselineAssessmentDto> HandleAsync(Guid childId, CancellationToken cancellationToken = default)
    {
        if (!_currentUserService.IsAuthenticated || _currentUserService.UserId == null)
        {
            throw new UnauthorizedException("User is not authenticated.");
        }

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
            throw new ForbiddenException("You do not have permission to view baseline assessments.");
        }

        var assessment = _context.BaselineAssessments
            .Where(b => b.ChildId == childId)
            .OrderByDescending(b => b.CompletedAtUtc)
            .FirstOrDefault();

        if (assessment == null)
        {
            throw new NotFoundException("BaselineAssessment", childId);
        }

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
