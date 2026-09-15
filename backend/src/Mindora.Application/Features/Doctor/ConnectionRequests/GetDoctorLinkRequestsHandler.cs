using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Features.Children.Models;
using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Doctor.ConnectionRequests;

public class GetDoctorLinkRequestsHandler
{
    private readonly ICurrentUserService _currentUserService;
    private readonly IApplicationDbContext _context;
    private readonly IIdentityService _identityService;

    public GetDoctorLinkRequestsHandler(
        ICurrentUserService currentUserService,
        IApplicationDbContext context,
        IIdentityService identityService)
    {
        _currentUserService = currentUserService;
        _context = context;
        _identityService = identityService;
    }

    public async Task<IReadOnlyList<DoctorLinkRequestSummaryDto>> HandleAsync(
        DoctorLinkRequestStatus? statusFilter = DoctorLinkRequestStatus.Pending,
        CancellationToken cancellationToken = default)
    {
        if (!_currentUserService.IsAuthenticated || _currentUserService.UserId == null)
        {
            throw new UnauthorizedException("User is not authenticated.");
        }

        if (_currentUserService.Role != UserRole.Doctor)
        {
            throw new ForbiddenException("Only doctors are permitted to view connection requests.");
        }

        var userId = _currentUserService.UserId.Value;
        var doctorProfile = _context.DoctorProfiles.FirstOrDefault(d => d.UserId == userId);
        if (doctorProfile == null)
        {
            throw new NotFoundException("DoctorProfile", userId);
        }

        var query = _context.DoctorLinkRequests
            .Where(r => r.DoctorId == doctorProfile.Id);

        if (statusFilter.HasValue)
        {
            query = query.Where(r => r.Status == statusFilter.Value);
        }

        var requests = query
            .OrderByDescending(r => r.CreatedAtUtc)
            .ToList();

        if (!requests.Any())
        {
            return Array.Empty<DoctorLinkRequestSummaryDto>();
        }

        var childIds = requests.Select(r => r.ChildId).Distinct().ToList();
        var parentIds = requests.Select(r => r.ParentId).Distinct().ToList();

        var children = _context.Children
            .Where(c => childIds.Contains(c.Id))
            .ToDictionary(c => c.Id);

        var parentProfiles = _context.ParentProfiles
            .Where(p => parentIds.Contains(p.Id))
            .ToDictionary(p => p.Id);

        var parentUserIds = parentProfiles.Values.Select(p => p.UserId).Distinct().ToList();
        var parentUsers = new Dictionary<Guid, string>();
        foreach (var parentUserId in parentUserIds)
        {
            var user = await _identityService.GetUserByIdAsync(parentUserId, cancellationToken);
            if (user.HasValue)
            {
                parentUsers[parentUserId] = user.Value.FullName;
            }
        }

        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        var result = new List<DoctorLinkRequestSummaryDto>();

        foreach (var req in requests)
        {
            children.TryGetValue(req.ChildId, out var child);
            parentProfiles.TryGetValue(req.ParentId, out var parentProfile);

            string parentName = "ولي الأمر";
            if (parentProfile != null && parentUsers.TryGetValue(parentProfile.UserId, out var pName))
            {
                parentName = pName;
            }

            int? ageYears = null;
            if (child != null)
            {
                int calculatedAge = today.Year - child.DateOfBirth.Year;
                if (child.DateOfBirth > today.AddYears(-calculatedAge))
                {
                    calculatedAge--;
                }
                ageYears = Math.Max(0, calculatedAge);
            }

            result.Add(new DoctorLinkRequestSummaryDto(
                req.Id,
                req.ChildId,
                child?.FullName ?? "طفل سوا",
                ageYears,
                child?.Gender?.ToString(),
                parentName,
                req.Status.ToString(),
                req.CreatedAtUtc));
        }

        return result;
    }
}
