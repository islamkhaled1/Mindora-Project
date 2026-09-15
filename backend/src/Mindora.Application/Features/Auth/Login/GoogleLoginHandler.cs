using FluentValidation;
using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Common.Validation;
using Mindora.Application.Features.Auth.Models;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Auth.Login;

public class GoogleLoginHandler
{
    private readonly IGoogleTokenValidator _googleTokenValidator;
    private readonly IIdentityService _identityService;
    private readonly IApplicationDbContext _dbContext;
    private readonly IJwtTokenService _jwtTokenService;
    private readonly IValidator<GoogleLoginRequest> _validator;

    public GoogleLoginHandler(
        IGoogleTokenValidator googleTokenValidator,
        IIdentityService identityService,
        IApplicationDbContext dbContext,
        IJwtTokenService jwtTokenService,
        IValidator<GoogleLoginRequest> validator)
    {
        _googleTokenValidator = googleTokenValidator;
        _identityService = identityService;
        _dbContext = dbContext;
        _jwtTokenService = jwtTokenService;
        _validator = validator;
    }

    public async Task<AuthResponseDto> HandleAsync(GoogleLoginRequest request, CancellationToken cancellationToken = default)
    {
        await _validator.ValidateAndThrowAppAsync(request, cancellationToken);

        // 1. Server-side validation of Google ID Token (signature, issuer, audience, expiration, email_verified)
        var payload = await _googleTokenValidator.ValidateAsync(request.IdToken, cancellationToken);

        if (!payload.EmailVerified)
        {
            throw new BadRequestException("Google email address is not verified.");
        }

        if (string.IsNullOrWhiteSpace(payload.Email) || string.IsNullOrWhiteSpace(payload.Subject))
        {
            throw new BadRequestException("Invalid Google token claims.");
        }

        // 2. Identity resolution & external login linking
        var (succeeded, userId, email, fullName, role, isDoctorConflict, errors) = await _identityService.AuthenticateOrLinkExternalLoginAsync(
            "Google",
            payload.Subject,
            payload.Email,
            payload.Name ?? string.Empty,
            cancellationToken);

        if (isDoctorConflict)
        {
            throw new ConflictException("هذا الحساب مسجل بالفعل على لوحة تحكم الطبيب.");
        }

        if (!succeeded)
        {
            throw new UnauthorizedException(errors.Length > 0 ? string.Join(" ", errors) : "Google authentication failed.");
        }

        if (role != UserRole.Parent)
        {
            throw new ConflictException("هذا الحساب مسجل بالفعل على لوحة تحكم الطبيب.");
        }

        // 3. Ensure ParentProfile exists
        var parentProfile = _dbContext.ParentProfiles.FirstOrDefault(p => p.UserId == userId);
        if (parentProfile == null)
        {
            parentProfile = ParentProfile.Create(userId);
            _dbContext.Add(parentProfile);
            await _dbContext.SaveChangesAsync(cancellationToken);
        }

        // 4. Issue the standard Mindora JWT
        var tokenResult = _jwtTokenService.GenerateToken(
            userId,
            email,
            fullName,
            UserRole.Parent,
            parentProfile.Id);

        return new AuthResponseDto(
            tokenResult.Token,
            tokenResult.ExpiresAtUtc,
            new AuthUserDto(userId, email, fullName, UserRole.Parent.ToString(), parentProfile.Id));
    }
}
