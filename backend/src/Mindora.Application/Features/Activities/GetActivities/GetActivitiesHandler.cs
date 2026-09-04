using FluentValidation;
using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Features.Activities.Models;
using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Activities.GetActivities;

public class GetActivitiesHandler
{
    private readonly ICurrentUserService _currentUserService;
    private readonly IApplicationDbContext _context;
    private readonly IValidator<GetActivitiesRequest> _validator;

    public GetActivitiesHandler(
        ICurrentUserService currentUserService,
        IApplicationDbContext context,
        IValidator<GetActivitiesRequest> validator)
    {
        _currentUserService = currentUserService;
        _context = context;
        _validator = validator;
    }

    public async Task<IReadOnlyList<ActivityDto>> HandleAsync(
        GetActivitiesRequest request,
        CancellationToken cancellationToken = default)
    {
        if (!_currentUserService.IsAuthenticated)
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

        // Only active activities are exposed to users
        var query = _context.Activities.Where(a => a.IsActive);

        if (!string.IsNullOrWhiteSpace(request.Domain) &&
            Enum.TryParse<ActivityDomain>(request.Domain, ignoreCase: true, out var domainFilter))
        {
            query = query.Where(a => a.Domain == domainFilter);
        }

        if (!string.IsNullOrWhiteSpace(request.Difficulty) &&
            Enum.TryParse<DifficultyLevel>(request.Difficulty, ignoreCase: true, out var difficultyFilter))
        {
            query = query.Where(a => a.BaseDifficulty == difficultyFilter);
        }

        var activities = query
            .OrderBy(a => a.Domain)
            .ThenBy(a => a.BaseDifficulty)
            .ThenBy(a => a.Title)
            .Select(a => new ActivityDto(
                a.Id,
                a.Title,
                a.Description,
                a.Domain.ToString(),
                a.BaseDifficulty.ToString(),
                a.AdaptiveSettingsJson,
                a.CreatedAtUtc))
            .ToList();

        return activities;
    }
}
