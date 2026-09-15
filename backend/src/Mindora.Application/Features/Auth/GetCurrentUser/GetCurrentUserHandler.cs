using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Auth.GetCurrentUser;

public class GetCurrentUserHandler
{
    private readonly ICurrentUserService _currentUserService;
    private readonly IIdentityService _identityService;
    private readonly IApplicationDbContext _dbContext;

    public GetCurrentUserHandler(
        ICurrentUserService currentUserService,
        IIdentityService identityService,
        IApplicationDbContext dbContext)
    {
        _currentUserService = currentUserService;
        _identityService = identityService;
        _dbContext = dbContext;
    }

    public async Task<CurrentUserDto> HandleAsync(CancellationToken cancellationToken = default)
    {
        if (!_currentUserService.IsAuthenticated || _currentUserService.UserId == null)
        {
            throw new UnauthorizedException("User is not authenticated.");
        }

        var userId = _currentUserService.UserId.Value;
        var user = await _identityService.GetUserByIdAsync(userId, cancellationToken);
        if (user == null)
        {
            throw new NotFoundException("User", userId);
        }

        Guid profileId = Guid.Empty;
        string? gender = null;
        string? specialization = null;
        string? clinicName = null;
        string? referralCode = null;

        if (user.Value.Role == UserRole.Parent)
        {
            var parentProfile = _dbContext.ParentProfiles.FirstOrDefault(p => p.UserId == userId);
            profileId = parentProfile?.Id ?? Guid.Empty;
        }
        else if (user.Value.Role == UserRole.Doctor)
        {
            var doctorProfile = _dbContext.DoctorProfiles.FirstOrDefault(d => d.UserId == userId);
            profileId = doctorProfile?.Id ?? Guid.Empty;
            gender = doctorProfile?.Gender?.ToString();
            specialization = doctorProfile?.Specialization;
            clinicName = doctorProfile?.ClinicName;
            referralCode = doctorProfile?.ReferralCode;
        }

        return new CurrentUserDto(
            user.Value.UserId,
            user.Value.Email,
            user.Value.FullName,
            user.Value.Role.ToString(),
            profileId,
            gender,
            specialization,
            clinicName,
            referralCode);
    }
}
