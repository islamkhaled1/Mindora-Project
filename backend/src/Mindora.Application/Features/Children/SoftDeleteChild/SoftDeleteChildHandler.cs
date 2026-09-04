using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Children.SoftDeleteChild;

public class SoftDeleteChildHandler
{
    private readonly ICurrentUserService _currentUserService;
    private readonly IApplicationDbContext _context;

    public SoftDeleteChildHandler(
        ICurrentUserService currentUserService,
        IApplicationDbContext context)
    {
        _currentUserService = currentUserService;
        _context = context;
    }

    public async Task HandleAsync(Guid childId, CancellationToken cancellationToken = default)
    {
        if (!_currentUserService.IsAuthenticated || _currentUserService.UserId == null)
        {
            throw new UnauthorizedException("User is not authenticated.");
        }

        if (_currentUserService.Role != UserRole.Parent)
        {
            throw new ForbiddenException("Only the owning parent may delete a child.");
        }

        var userId = _currentUserService.UserId.Value;
        var parentProfile = _context.ParentProfiles.FirstOrDefault(p => p.UserId == userId);
        if (parentProfile == null)
        {
            throw new NotFoundException("ParentProfile", userId);
        }

        // Must be the child of this parent. Global query filter ensures we only query active (non-deleted) children.
        var child = _context.Children.FirstOrDefault(c => c.Id == childId && c.ParentId == parentProfile.Id);
        if (child == null)
        {
            // If child doesn't exist or already deleted, throw NotFoundException (safe and prevents leaking other parents' child IDs)
            throw new NotFoundException("Child", childId);
        }

        // Soft delete: sets IsDeleted = true. Preserves all related records (Sessions, Metrics, Assignments).
        child.MarkAsDeleted();
        await _context.SaveChangesAsync(cancellationToken);
    }
}
