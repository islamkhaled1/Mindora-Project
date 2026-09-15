using System.Security.Cryptography;
using FluentValidation;
using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Common.Validation;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Auth.ForgotPassword;

public class ForgotPasswordHandler
{
    private readonly IIdentityService _identityService;
    private readonly IApplicationDbContext _dbContext;
    private readonly IEmailService _emailService;
    private readonly IValidator<ForgotPasswordRequest> _validator;

    public const string GenericResponse = "إذا كان البريد الإلكتروني مسجلاً، سيتم إرسال رمز التحقق.";
    public static readonly TimeSpan CooldownDuration = TimeSpan.FromSeconds(60);

    public ForgotPasswordHandler(
        IIdentityService identityService,
        IApplicationDbContext dbContext,
        IEmailService emailService,
        IValidator<ForgotPasswordRequest> validator)
    {
        _identityService = identityService;
        _dbContext = dbContext;
        _emailService = emailService;
        _validator = validator;
    }

    public async Task<ForgotPasswordResponseDto> HandleAsync(
        ForgotPasswordRequest request,
        CancellationToken cancellationToken = default)
    {
        await _validator.ValidateAndThrowAppAsync(request, cancellationToken);

        var normalizedEmail = request.Email.Trim().ToLowerInvariant();
        var user = await _identityService.GetUserByEmailAsync(normalizedEmail, cancellationToken);

        // Anti-enumeration protection: return the exact same generic message if user not found
        if (user == null)
        {
            await Task.Delay(200, cancellationToken); // constant time mitigation
            return new ForgotPasswordResponseDto(GenericResponse, ForgotPasswordStatus.ContinueReset);
        }

        var requestPlatform = ClientPlatformParser.ParseOrDefault(request.Platform, ClientPlatform.SawaApp);

        // Platform mismatch checks:
        // 1. Doctor Dashboard requested with a Parent account
        if (requestPlatform == ClientPlatform.DoctorDashboard && user.Value.Role != UserRole.Doctor)
        {
            return new ForgotPasswordResponseDto(
                "هذا الحساب مسجل على SAWA APP.\nلاستعادة كلمة المرور، يرجى استخدام تطبيق SAWA APP.",
                ForgotPasswordStatus.WrongPlatform,
                "SawaApp");
        }

        // 2. SAWA App requested with a Doctor account
        if (requestPlatform == ClientPlatform.SawaApp && user.Value.Role != UserRole.Parent)
        {
            return new ForgotPasswordResponseDto(
                "هذا الحساب مسجل على لوحة تحكم الطبيب.\nلاستعادة كلمة المرور، يرجى استخدام لوحة تحكم الطبيب.",
                ForgotPasswordStatus.WrongPlatform,
                "DoctorDashboard");
        }

        var utcNow = DateTime.UtcNow;

        // Rate-limit check: cooldown of 60s between OTP requests
        var recentActiveToken = _dbContext.PasswordResetTokens
            .Where(t => t.Email == normalizedEmail && !t.IsUsed)
            .OrderByDescending(t => t.CreatedAtUtc)
            .FirstOrDefault();

        if (recentActiveToken != null && (utcNow - recentActiveToken.CreatedAtUtc) < CooldownDuration)
        {
            var remainingSeconds = (int)Math.Ceiling((CooldownDuration - (utcNow - recentActiveToken.CreatedAtUtc)).TotalSeconds);
            throw new BadRequestException($"يرجى الانتظار {remainingSeconds} ثانية قبل طلب رمز تحقق جديد.");
        }

        // Invalidate all previous unverified OTPs for this user/email
        var existingPendingTokens = _dbContext.PasswordResetTokens
            .Where(t => t.UserId == user.Value.UserId && !t.IsUsed)
            .ToList();

        foreach (var pending in existingPendingTokens)
        {
            pending.Invalidate();
        }

        // Generate cryptographically secure 6-digit OTP
        var otpNumber = RandomNumberGenerator.GetInt32(100000, 1000000);
        var plainOtp = otpNumber.ToString();

        var resetRecord = PasswordResetToken.Create(
            user.Value.UserId,
            normalizedEmail,
            plainOtp,
            TimeSpan.FromMinutes(PasswordResetToken.DefaultOtpValidityMinutes),
            utcNow);

        _dbContext.Add(resetRecord);
        await _dbContext.SaveChangesAsync(cancellationToken);

        // Dispatch transactional email via configured Email Service
        await _emailService.SendPasswordResetOtpAsync(
            normalizedEmail,
            plainOtp,
            PasswordResetToken.DefaultOtpValidityMinutes,
            cancellationToken);

        return new ForgotPasswordResponseDto(
            GenericResponse,
            ForgotPasswordStatus.ContinueReset,
            requestPlatform == ClientPlatform.DoctorDashboard ? "DoctorDashboard" : "SawaApp");
    }
}
