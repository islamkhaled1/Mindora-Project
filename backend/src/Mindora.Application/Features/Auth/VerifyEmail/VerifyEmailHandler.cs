using FluentValidation;
using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Common.Validation;
using Mindora.Application.Features.Auth.Models;
using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Auth.VerifyEmail;

public class VerifyEmailHandler
{
    private readonly IIdentityService _identityService;
    private readonly IApplicationDbContext _dbContext;
    private readonly IJwtTokenService _jwtTokenService;
    private readonly IValidator<VerifyEmailRequest> _validator;

    public VerifyEmailHandler(
        IIdentityService identityService,
        IApplicationDbContext dbContext,
        IJwtTokenService jwtTokenService,
        IValidator<VerifyEmailRequest> validator)
    {
        _identityService = identityService;
        _dbContext = dbContext;
        _jwtTokenService = jwtTokenService;
        _validator = validator;
    }

    public async Task<VerifyEmailResponseDto> HandleAsync(
        VerifyEmailRequest request,
        CancellationToken cancellationToken = default)
    {
        await _validator.ValidateAndThrowAppAsync(request, cancellationToken);

        var platform = ClientPlatformParser.ParseOrDefault(request.Platform, ClientPlatform.SawaApp);
        var normalizedEmail = request.Email.Trim().ToLowerInvariant();

        var user = await _identityService.GetUserByEmailAsync(normalizedEmail, cancellationToken);
        if (user == null)
        {
            throw new BadRequestException("رمز التحقق غير صحيح أو منتهي الصلاحية.");
        }

        // Server-side platform and role boundary enforcement
        if (platform == ClientPlatform.SawaApp && user.Value.Role != UserRole.Parent)
        {
            throw new ForbiddenException("لا يمكن تأكيد حساب الطبيب عبر تطبيق SAWA.");
        }

        if (platform == ClientPlatform.DoctorDashboard && user.Value.Role != UserRole.Doctor)
        {
            throw new ForbiddenException("لا يمكن تأكيد حساب ولي الأمر عبر لوحة تحكم الطبيب.");
        }

        // Check if already confirmed
        var isConfirmed = await _identityService.IsEmailConfirmedAsync(normalizedEmail, cancellationToken);
        if (isConfirmed)
        {
            if (user.Value.Role == UserRole.Parent)
            {
                var parentProfile = _dbContext.ParentProfiles.FirstOrDefault(p => p.UserId == user.Value.UserId);
                var tokenResult = _jwtTokenService.GenerateToken(
                    user.Value.UserId,
                    user.Value.Email,
                    user.Value.FullName,
                    user.Value.Role,
                    parentProfile?.Id ?? Guid.Empty);

                return new VerifyEmailResponseDto(
                    true,
                    "البريد الإلكتروني مؤكد بالفعل.",
                    tokenResult.Token,
                    tokenResult.ExpiresAtUtc,
                    new AuthUserDto(user.Value.UserId, user.Value.Email, user.Value.FullName, user.Value.Role.ToString(), parentProfile?.Id ?? Guid.Empty));
            }

            return new VerifyEmailResponseDto(
                true,
                "البريد الإلكتروني مؤكد بالفعل. يمكنك تسجيل الدخول الآن.");
        }

        // Locate active token for this user and platform
        var token = _dbContext.EmailVerificationTokens
            .Where(t => t.UserId == user.Value.UserId && t.Platform == platform && t.IsActive)
            .OrderByDescending(t => t.CreatedAtUtc)
            .FirstOrDefault();

        if (token == null)
        {
            throw new BadRequestException("لم يتم العثور على رمز تحقق فعال. يرجى طلب رمز جديد.");
        }

        var (succeeded, errorMessage) = token.VerifyOtp(request.Otp, DateTime.UtcNow);

        // Always save to persist attempt increments or invalidation
        await _dbContext.SaveChangesAsync(cancellationToken);

        if (!succeeded)
        {
            throw new BadRequestException(errorMessage ?? "رمز التحقق غير صحيح.");
        }

        // Confirm email in ASP.NET Core Identity
        var (confirmSuccess, confirmErrors) = await _identityService.ConfirmEmailAsync(user.Value.UserId, cancellationToken);
        if (!confirmSuccess)
        {
            throw new BadRequestException("حدث خطأ أثناء تأكيد الحساب. يرجى المحاولة مرة أخرى.");
        }

        // For Parent (SAWA App): issue JWT for seamless continuation
        if (user.Value.Role == UserRole.Parent)
        {
            var parentProfile = _dbContext.ParentProfiles.FirstOrDefault(p => p.UserId == user.Value.UserId);
            var tokenResult = _jwtTokenService.GenerateToken(
                user.Value.UserId,
                user.Value.Email,
                user.Value.FullName,
                user.Value.Role,
                parentProfile?.Id ?? Guid.Empty);

            return new VerifyEmailResponseDto(
                true,
                "تم تأكيد البريد الإلكتروني بنجاح.",
                tokenResult.Token,
                tokenResult.ExpiresAtUtc,
                new AuthUserDto(user.Value.UserId, user.Value.Email, user.Value.FullName, user.Value.Role.ToString(), parentProfile?.Id ?? Guid.Empty));
        }

        // For Doctor (Dashboard): confirm success without issuing Doctor JWT directly (proceed to Doctor Login)
        var doctorProfile = _dbContext.DoctorProfiles.FirstOrDefault(d => d.UserId == user.Value.UserId);
        return new VerifyEmailResponseDto(
            true,
            "تم تأكيد البريد الإلكتروني بنجاح. يمكنك الآن تسجيل الدخول إلى حسابك.",
            User: new AuthUserDto(user.Value.UserId, user.Value.Email, user.Value.FullName, user.Value.Role.ToString(), doctorProfile?.Id ?? Guid.Empty));
    }
}
