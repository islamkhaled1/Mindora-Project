namespace Mindora.Application.Common.Interfaces;

/// <summary>
/// Abstraction for transactional email delivery (e.g. Brevo SMTP).
/// Keeps transport, SMTP protocols, and external mail service dependencies out of the Application layer.
/// </summary>
public interface IEmailService
{
    /// <summary>
    /// Sends a branded password reset verification code (OTP) to the specified recipient.
    /// </summary>
    Task SendPasswordResetOtpAsync(
        string toEmail,
        string otpCode,
        int expiryMinutes,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Sends a branded email verification code (OTP) to confirm a newly registered parent or doctor account.
    /// </summary>
    Task SendEmailVerificationOtpAsync(
        string toEmail,
        string otpCode,
        int expiryMinutes,
        Mindora.Domain.Enums.ClientPlatform platform,
        CancellationToken cancellationToken = default);
}
