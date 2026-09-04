using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Features.Activities.Models;

namespace Mindora.Application.Features.Activities.GetActivityById;

public class GetActivityByIdHandler
{
    private readonly ICurrentUserService _currentUserService;
    private readonly IApplicationDbContext _context;

    public GetActivityByIdHandler(
        ICurrentUserService currentUserService,
        IApplicationDbContext context)
    {
        _currentUserService = currentUserService;
        _context = context;
    }

    public async Task<ActivityDto> HandleAsync(Guid activityId, CancellationToken cancellationToken = default)
    {
        if (!_currentUserService.IsAuthenticated)
        {
            throw new UnauthorizedException("User is not authenticated.");
        }

        // Return only active activities. Inactive activities must return NotFound.
        var activity = _context.Activities.FirstOrDefault(a => a.Id == activityId && a.IsActive);
        if (activity == null)
        {
            throw new NotFoundException("Activity", activityId);
        }

        return new ActivityDto(
            activity.Id,
            activity.Title,
            activity.Description,
            activity.Domain.ToString(),
            activity.BaseDifficulty.ToString(),
            activity.AdaptiveSettingsJson,
            activity.CreatedAtUtc);
    }
}
