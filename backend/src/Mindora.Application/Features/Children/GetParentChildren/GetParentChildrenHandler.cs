using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Features.Children.Models;
using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Children.GetParentChildren;

public class GetParentChildrenHandler
{
    private readonly ICurrentUserService _currentUserService;
    private readonly IApplicationDbContext _context;

    public GetParentChildrenHandler(
        ICurrentUserService currentUserService,
        IApplicationDbContext context)
    {
        _currentUserService = currentUserService;
        _context = context;
    }

    public async Task<IReadOnlyList<ChildSummaryDto>> HandleAsync(CancellationToken cancellationToken = default)
    {
        if (!_currentUserService.IsAuthenticated || _currentUserService.UserId == null)
        {
            throw new UnauthorizedException("User is not authenticated.");
        }

        if (_currentUserService.Role != UserRole.Parent)
        {
            throw new ForbiddenException("Only parents can view their children list.");
        }

        var userId = _currentUserService.UserId.Value;
        var parentProfile = _context.ParentProfiles.FirstOrDefault(p => p.UserId == userId);
        if (parentProfile == null)
        {
            throw new NotFoundException("ParentProfile", userId);
        }

        // Global query filter on Child automatically filters out IsDeleted == true.
        var children = _context.Children
            .Where(c => c.ParentId == parentProfile.Id)
            .OrderByDescending(c => c.CreatedAtUtc)
            .Select(c => new ChildSummaryDto(
                c.Id,
                c.FullName,
                c.DateOfBirth,
                c.CurrentMovementLevel.ToString(),
                c.CurrentSpeechLevel.ToString(),
                c.CurrentAttentionLevel.ToString(),
                c.CreatedAtUtc,
                c.AvatarUrl,
                c.Gender.HasValue ? c.Gender.Value.ToString() : null))
            .ToList();

        return children;
    }
}
