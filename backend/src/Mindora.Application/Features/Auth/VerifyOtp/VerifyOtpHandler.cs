using FluentValidation;
using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Common.Validation;
using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Auth.VerifyOtp;

public class VerifyOtpHandler
{
    private readonly IApplicationDbContext _dbContext;
    private readonly IIdentityService _identityService;
    private readonly IValidator<VerifyOtpRequest> _validator;

    public VerifyOtpHandler(
        IApplicationDbContext dbContext,
        IIdentityService identityService,
        IValidator<VerifyOtpRequest> validator)
    {
        _dbContext = dbContext;
        _identityService = identityService;
        _validator = validator;
    }

    public async Task<VerifyOtpResponseDto> HandleAsync(
        VerifyOtpRequest request,
        CancellationToken cancellationToken = default)
    {
        await _validator.ValidateAndThrowAppAsync(request, cancellationToken);

        var normalizedEmail = request.Email.Trim().ToLowerInvariant();
        var utcNow = DateTime.UtcNow;

        // Find active unverified token for this email
        var activeToken = _dbContext.PasswordResetTokens
            .Where(t => t.Email == normalizedEmail && !t.IsUsed && !t.IsOtpVerified)
            .OrderByDescending(t => t.CreatedAtUtc)
            .FirstOrDefault();

        if (activeToken == null)
        {
            throw new BadRequestException("رمز التحقق غير صالح أو منتهي الصلاحية.");
        }

        if (!string.IsNullOrWhiteSpace(request.Platform) && ClientPlatformParser.TryParse(request.Platform, out var platform))
        {
            var user = await _identityService.GetUserByIdAsync(activeToken.UserId, cancellationToken);
            if (user != null)
            {
                if (platform == ClientPlatform.DoctorDashboard && user.Value.Role != UserRole.Doctor)
                {
                    throw new BadRequestException("رمز التحقق غير صالح لهذه المنصة.");
                }
                if (platform == ClientPlatform.SawaApp && user.Value.Role != UserRole.Parent)
                {
                    throw new BadRequestException("رمز التحقق غير صالح لهذه المنصة.");
                }
            }
        }

        var (succeeded, errorMessage) = activeToken.VerifyOtp(request.Otp, utcNow);
        if (!succeeded)
        {
            // Persist the incremented attempt count
            await _dbContext.SaveChangesAsync(cancellationToken);
            throw new BadRequestException(errorMessage ?? "رمز التحقق غير صحيح.");
        }

        // Issue single-use, time-bounded reset token
        var plainResetToken = activeToken.IssueResetToken(utcNow);
        await _dbContext.SaveChangesAsync(cancellationToken);

        return new VerifyOtpResponseDto(plainResetToken, "تم التحقق من الرمز بنجاح.");
    }
}
