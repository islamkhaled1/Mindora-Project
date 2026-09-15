using FluentValidation;
using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Common.Validation;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Auth.ResetPassword;

public class ResetPasswordHandler
{
    private readonly IIdentityService _identityService;
    private readonly IApplicationDbContext _dbContext;
    private readonly IValidator<ResetPasswordRequest> _validator;

    public ResetPasswordHandler(
        IIdentityService identityService,
        IApplicationDbContext dbContext,
        IValidator<ResetPasswordRequest> validator)
    {
        _identityService = identityService;
        _dbContext = dbContext;
        _validator = validator;
    }

    public async Task<ResetPasswordResponseDto> HandleAsync(
        ResetPasswordRequest request,
        CancellationToken cancellationToken = default)
    {
        await _validator.ValidateAndThrowAppAsync(request, cancellationToken);

        var incomingHash = PasswordResetToken.ComputeHash(request.ResetToken);
        var utcNow = DateTime.UtcNow;

        // Find token by hash
        var tokenRecord = _dbContext.PasswordResetTokens
            .FirstOrDefault(t => t.ResetTokenHash == incomingHash && !t.IsUsed && t.IsOtpVerified);

        if (tokenRecord == null)
        {
            throw new BadRequestException("رمز إعادة تعيين كلمة المرور غير صالح أو منتهي الصلاحية.");
        }

        var (isValid, errorMessage) = tokenRecord.VerifyResetToken(request.ResetToken, utcNow);
        if (!isValid)
        {
            throw new BadRequestException(errorMessage ?? "رمز إعادة تعيين كلمة المرور غير صالح.");
        }

        // Server-side platform binding safeguard
        if (!string.IsNullOrWhiteSpace(request.Platform) && ClientPlatformParser.TryParse(request.Platform, out var platform))
        {
            var user = await _identityService.GetUserByIdAsync(tokenRecord.UserId, cancellationToken);
            if (user != null)
            {
                if (platform == ClientPlatform.DoctorDashboard && user.Value.Role != UserRole.Doctor)
                {
                    throw new BadRequestException("لا يمكن استخدام رمز استعادة حساب SAWA عبر لوحة تحكم الطبيب.");
                }
                if (platform == ClientPlatform.SawaApp && user.Value.Role != UserRole.Parent)
                {
                    throw new BadRequestException("لا يمكن استخدام رمز استعادة حساب الطبيب عبر تطبيق SAWA.");
                }
            }
        }

        // Execute password reset through ASP.NET Core Identity
        var (succeeded, errors) = await _identityService.ResetPasswordAsync(
            tokenRecord.UserId,
            request.NewPassword,
            cancellationToken);

        if (!succeeded)
        {
            var firstError = errors.FirstOrDefault() ?? "فشل إعادة تعيين كلمة المرور. يرجى التأكد من استيفاء شروط كلمة المرور.";
            throw new BadRequestException(firstError);
        }

        // Invalidate the reset token and mark used
        tokenRecord.MarkUsed(utcNow);

        // Invalidate any other pending tokens for this user
        var remainingTokens = _dbContext.PasswordResetTokens
            .Where(t => t.UserId == tokenRecord.UserId && !t.IsUsed)
            .ToList();

        foreach (var remaining in remainingTokens)
        {
            remaining.Invalidate();
        }

        await _dbContext.SaveChangesAsync(cancellationToken);

        return new ResetPasswordResponseDto("تم إعادة تعيين كلمة المرور بنجاح.");
    }
}
