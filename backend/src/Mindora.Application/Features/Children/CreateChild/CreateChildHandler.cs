using FluentValidation;
using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Features.Children.Models;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Children.CreateChild;

public class CreateChildHandler
{
    private readonly ICurrentUserService _currentUserService;
    private readonly IApplicationDbContext _context;
    private readonly IValidator<CreateChildRequest> _validator;

    public CreateChildHandler(
        ICurrentUserService currentUserService,
        IApplicationDbContext context,
        IValidator<CreateChildRequest> validator)
    {
        _currentUserService = currentUserService;
        _context = context;
        _validator = validator;
    }

    public async Task<ChildDto> HandleAsync(CreateChildRequest request, CancellationToken cancellationToken = default)
    {
        if (!_currentUserService.IsAuthenticated || _currentUserService.UserId == null)
        {
            throw new UnauthorizedException("User is not authenticated.");
        }

        if (_currentUserService.Role != UserRole.Parent)
        {
            throw new ForbiddenException("Only parents are permitted to register children.");
        }

        var validationResult = await _validator.ValidateAsync(request, cancellationToken);
        if (!validationResult.IsValid)
        {
            var failures = validationResult.Errors
                .Select(e => new FluentValidation.Results.ValidationFailure(e.PropertyName, e.ErrorMessage));
            throw new Mindora.Application.Common.Exceptions.ValidationException(failures);
        }

        var userId = _currentUserService.UserId.Value;
        var parentProfile = _context.ParentProfiles.FirstOrDefault(p => p.UserId == userId);
        if (parentProfile == null)
        {
            throw new NotFoundException("ParentProfile", userId);
        }

        var child = Child.Create(
            parentProfile.Id,
            request.FullName,
            request.DateOfBirth,
            request.SupportNotes,
            request.BaselineMovementLevel,
            request.BaselineSpeechLevel,
            request.BaselineAttentionLevel,
            createdAtUtc: null,
            gender: request.Gender,
            diagnosis: request.Diagnosis,
            avatarUrl: request.AvatarUrl,
            supportLevel: request.SupportLevel,
            hearingStatus: request.HearingStatus,
            visionStatus: request.VisionStatus,
            focusDurationMinutes: request.FocusDurationMinutes,
            preferredPracticeTime: request.PreferredPracticeTime,
            preferredActivityType: request.PreferredActivityType);

        _context.Add(child);
        await _context.SaveChangesAsync(cancellationToken);

        return new ChildDto(
            child.Id,
            child.ParentId,
            child.FullName,
            child.DateOfBirth,
            child.SupportNotes,
            child.CurrentMovementLevel.ToString(),
            child.CurrentSpeechLevel.ToString(),
            child.CurrentAttentionLevel.ToString(),
            child.CreatedAtUtc,
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
