using FluentValidation;
using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Common.Validation;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Auth.SendVerificationOtp;

public class SendVerificationOtpHandler
{
    private readonly IIdentityService _identityService;
    private readonly IApplicationDbContext _dbContext;
    private readonly IEmailService _emailService;
    private readonly IValidator<SendVerificationOtpRequest> _validator;

    public SendVerificationOtpHandler(
        IIdentityService identityService,
        IApplicationDbContext dbContext,
        IEmailService emailService,
        IValidator<SendVerificationOtpRequest> validator)
    {
        _identityService = identityService;
        _dbContext = dbContext;
        _emailService = emailService;
        _validator = validator;
    }

    public async Task<SendVerificationOtpResponseDto> HandleAsync(
        SendVerificationOtpRequest request,
        CancellationToken cancellationToken = default)
    {
        await _validator.ValidateAndThrowAppAsync(request, cancellationToken);

        var platform = ClientPlatformParser.ParseOrDefault(request.Platform, ClientPlatform.SawaApp);
        var normalizedEmail = request.Email.Trim().ToLowerInvariant();

        var user = await _identityService.GetUserByEmailAsync(normalizedEmail, cancellationToken);

        // Anti-enumeration: Return generic success if account does not exist
        if (user == null)
        {
            return new SendVerificationOtpResponseDto(
                true,
                "إذا كان البريد الإلكتروني مسجلاً لدينا، فسيتم إرسال رمز التحقق.");
        }

        // Enforce platform boundaries strictly on server-side
        if (platform == ClientPlatform.SawaApp && user.Value.Role != UserRole.Parent)
        {
            throw new ForbiddenException("لا يمكن تأكيد حساب الطبيب عبر تطبيق SAWA.");
        }

        if (platform == ClientPlatform.DoctorDashboard && user.Value.Role != UserRole.Doctor)
        {
            throw new ForbiddenException("لا يمكن تأكيد حساب ولي الأمر عبر لوحة تحكم الطبيب.");
        }

        // Check if email is already confirmed
        var isConfirmed = await _identityService.IsEmailConfirmedAsync(normalizedEmail, cancellationToken);
        if (isConfirmed)
        {
            return new SendVerificationOtpResponseDto(
                true,
                "البريد الإلكتروني مؤكد بالفعل.",
                AlreadyVerified: true);
        }

        // Query active tokens for cooldown check and invalidation
        var activeTokens = _dbContext.EmailVerificationTokens
            .Where(t => t.UserId == user.Value.UserId && t.Platform == platform && t.IsActive)
            .ToList();

        if (activeTokens.Count > 0)
        {
            var latest = activeTokens.OrderByDescending(t => t.LastRequestedAtUtc).First();
            if (!latest.CanResend(DateTime.UtcNow, out var secondsRemaining))
            {
                throw new BadRequestException($"يرجى الانتظار {secondsRemaining} ثانية قبل طلب رمز تحقق جديد.");
            }

            // Invalidate existing active tokens before creating new one
            foreach (var token in activeTokens)
            {
                token.Invalidate();
            }
        }

        var otp = EmailVerificationToken.GenerateOtp();
        var verificationToken = EmailVerificationToken.Create(
            user.Value.UserId,
            normalizedEmail,
            platform,
            otp);

        _dbContext.Add(verificationToken);
        await _dbContext.SaveChangesAsync(cancellationToken);

        try
        {
            await _emailService.SendEmailVerificationOtpAsync(
                normalizedEmail,
                otp,
                EmailVerificationToken.DefaultOtpValidityMinutes,
                platform,
                cancellationToken);
        }
        catch (Exception)
        {
            throw new BadRequestException("تعذر إرسال رمز التحقق إلى بريدك الإلكتروني حالياً. يرجى المحاولة مرة أخرى لاحقاً.");
        }

        return new SendVerificationOtpResponseDto(
            true,
            "تم إرسال رمز التحقق بنجاح إلى بريدك الإلكتروني.");
    }
}
