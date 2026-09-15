using FluentValidation;
using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Common.Validation;
using Mindora.Application.Features.Auth.Models;
using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Auth.Login;

public class LoginHandler
{
    private readonly IIdentityService _identityService;
    private readonly IApplicationDbContext _dbContext;
    private readonly IJwtTokenService _jwtTokenService;
    private readonly IValidator<LoginRequest> _validator;

    public LoginHandler(
        IIdentityService identityService,
        IApplicationDbContext dbContext,
        IJwtTokenService jwtTokenService,
        IValidator<LoginRequest> validator)
    {
        _identityService = identityService;
        _dbContext = dbContext;
        _jwtTokenService = jwtTokenService;
        _validator = validator;
    }

    public async Task<AuthResponseDto> HandleAsync(LoginRequest request, CancellationToken cancellationToken = default)
    {
        await _validator.ValidateAndThrowAppAsync(request, cancellationToken);

        var (succeeded, userId, email, fullName, role, _) = await _identityService.AuthenticateAsync(
            request.Email,
            request.Password,
            cancellationToken);

        if (!succeeded)
        {
            throw new UnauthorizedException("Invalid email or password.");
        }

        var isEmailConfirmed = await _identityService.IsEmailConfirmedAsync(request.Email, cancellationToken);
        if (!isEmailConfirmed)
        {
            throw new EmailNotConfirmedException(request.Email.Trim().ToLowerInvariant());
        }

        Guid profileId = Guid.Empty;

        if (role == UserRole.Parent)
        {
            var parentProfile = _dbContext.ParentProfiles.FirstOrDefault(p => p.UserId == userId);
            if (parentProfile == null)
            {
                throw new UnauthorizedException("User profile was not found.");
            }
            profileId = parentProfile.Id;
        }
        else if (role == UserRole.Doctor)
        {
            var doctorProfile = _dbContext.DoctorProfiles.FirstOrDefault(d => d.UserId == userId);
            if (doctorProfile == null)
            {
                throw new UnauthorizedException("User profile was not found.");
            }
            profileId = doctorProfile.Id;
        }

        var tokenResult = _jwtTokenService.GenerateToken(userId, email, fullName, role, profileId);

        return new AuthResponseDto(
            tokenResult.Token,
            tokenResult.ExpiresAtUtc,
            new AuthUserDto(userId, email, fullName, role.ToString(), profileId));
    }
}
