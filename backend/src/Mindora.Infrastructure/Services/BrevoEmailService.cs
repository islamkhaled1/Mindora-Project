using System.Net;
using System.Net.Mail;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Mindora.Application.Common.Interfaces;

namespace Mindora.Infrastructure.Services;

/// <summary>
/// Production Brevo SMTP implementation of IEmailService.
/// Delivers branded transactional emails using secure STARTTLS over port 587.
/// Safe by design: never logs credentials or plaintext tokens.
/// </summary>
public class BrevoEmailService : IEmailService
{
    private readonly EmailOptions _options;
    private readonly ILogger<BrevoEmailService> _logger;

    public BrevoEmailService(
        IOptions<EmailOptions> options,
        ILogger<BrevoEmailService> logger)
    {
        _options = options.Value;
        _logger = logger;
    }

    public async Task SendPasswordResetOtpAsync(
        string toEmail,
        string otpCode,
        int expiryMinutes,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(toEmail))
        {
            _logger.LogWarning("Cannot send password reset OTP: recipient email address is empty.");
            return;
        }

        if (!_options.IsConfigured)
        {
            _logger.LogWarning(
                "Brevo SMTP is not configured in this environment (SmtpHost: {Host}, UsernameConfigured: {HasUser}). OTP email was not sent over SMTP.",
                _options.SmtpHost,
                !string.IsNullOrWhiteSpace(_options.Username));
            return;
        }

        try
        {
            using var client = new SmtpClient(_options.SmtpHost, _options.SmtpPort);
            client.EnableSsl = _options.EnableSsl;
            client.UseDefaultCredentials = false;
            client.Credentials = new NetworkCredential(_options.Username, _options.Password);
            client.DeliveryMethod = SmtpDeliveryMethod.Network;
            client.Timeout = _options.TimeoutMs;

            var subject = "ميندورا | رمز إعادة تعيين كلمة المرور";
            var htmlBody = BuildOtpEmailBody(otpCode, expiryMinutes);

            using var message = new MailMessage
            {
                From = new MailAddress(_options.FromEmail, _options.FromName),
                Subject = subject,
                Body = htmlBody,
                IsBodyHtml = true
            };

            message.To.Add(new MailAddress(toEmail.Trim()));

            await client.SendMailAsync(message, cancellationToken);
            _logger.LogInformation("Password reset OTP email sent successfully to recipient.");
        }
        catch (SmtpException ex)
        {
            _logger.LogError("SMTP error occurred while sending password reset email: {Message} (StatusCode: {StatusCode})",
                ex.Message,
                ex.StatusCode);
            throw;
        }
        catch (Exception ex)
        {
            _logger.LogError("Unexpected error occurred while dispatching email via Brevo SMTP: {Message}", ex.Message);
            throw;
        }
    }

    public async Task SendEmailVerificationOtpAsync(
        string toEmail,
        string otpCode,
        int expiryMinutes,
        Mindora.Domain.Enums.ClientPlatform platform,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(toEmail))
        {
            _logger.LogWarning("Cannot send email verification OTP: recipient email address is empty.");
            return;
        }

        if (!_options.IsConfigured)
        {
            _logger.LogWarning(
                "Brevo SMTP is not configured in this environment (SmtpHost: {Host}, UsernameConfigured: {HasUser}). Verification email was not sent over SMTP.",
                _options.SmtpHost,
                !string.IsNullOrWhiteSpace(_options.Username));
            return;
        }

        try
        {
            using var client = new SmtpClient(_options.SmtpHost, _options.SmtpPort);
            client.EnableSsl = _options.EnableSsl;
            client.UseDefaultCredentials = false;
            client.Credentials = new NetworkCredential(_options.Username, _options.Password);
            client.DeliveryMethod = SmtpDeliveryMethod.Network;
            client.Timeout = _options.TimeoutMs;

            var platformName = platform == Mindora.Domain.Enums.ClientPlatform.DoctorDashboard
                ? "لوحة تحكم الطبيب"
                : "تطبيق SAWA";
            var subject = $"ميندورا | رمز تأكيد البريد الإلكتروني ({platformName})";
            var htmlBody = BuildVerificationOtpEmailBody(otpCode, expiryMinutes, platform);

            using var message = new MailMessage
            {
                From = new MailAddress(_options.FromEmail, _options.FromName),
                Subject = subject,
                Body = htmlBody,
                IsBodyHtml = true
            };

            message.To.Add(new MailAddress(toEmail.Trim()));

            await client.SendMailAsync(message, cancellationToken);
            _logger.LogInformation("Email verification OTP email sent successfully to recipient.");
        }
        catch (SmtpException ex)
        {
            _logger.LogError("SMTP error occurred while sending verification email: {Message} (StatusCode: {StatusCode})",
                ex.Message,
                ex.StatusCode);
            throw;
        }
        catch (Exception ex)
        {
            _logger.LogError("Unexpected error occurred while dispatching email via Brevo SMTP: {Message}", ex.Message);
            throw;
        }
    }

    private static string BuildVerificationOtpEmailBody(string otpCode, int expiryMinutes, Mindora.Domain.Enums.ClientPlatform platform)
    {
        var subtitle = platform == Mindora.Domain.Enums.ClientPlatform.DoctorDashboard
            ? "بوابة الأطباء والمتخصصين"
            : "نظام التأهيل النمائي الذكي للأطفال";

        return $"""
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>رمز تأكيد البريد الإلكتروني</title>
</head>
<body style="margin: 0; padding: 0; background-color: #F7FAFC; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; text-align: right; direction: rtl;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color: #F7FAFC; padding: 40px 20px;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" style="max-width: 520px; background-color: #FFFFFF; border: 1px solid #E4D4FF; border-radius: 24px; padding: 36px 32px; box-shadow: 0 4px 20px rgba(67, 47, 98, 0.05);">
          <!-- Header -->
          <tr>
            <td align="center" style="padding-bottom: 24px;">
              <h1 style="margin: 0; font-size: 26px; font-weight: 800; color: #432F62;">منصة ميندورا | Mindora</h1>
              <p style="margin: 6px 0 0 0; font-size: 13px; font-weight: 600; color: #8456D2;">{subtitle}</p>
            </td>
          </tr>

          <!-- Divider -->
          <tr>
            <td style="border-top: 1px solid #F0E8FF; padding-bottom: 24px;"></td>
          </tr>

          <!-- Greeting & Details -->
          <tr>
            <td>
              <h2 style="margin: 0 0 12px 0; font-size: 18px; font-weight: 700; color: #432F62;">تأكيد البريد الإلكتروني</h2>
              <p style="margin: 0 0 20px 0; font-size: 14px; line-height: 1.6; color: #74728A;">
                شكراً لتسجيلك في منصة ميندورا. لتأكيد وتفعيل حسابك، يرجى إدخال رمز التحقق (OTP) التالي في شاشة التأكيد:
              </p>
            </td>
          </tr>

          <!-- OTP Box -->
          <tr>
            <td align="center" style="padding: 16px 0 24px 0;">
              <div style="display: inline-block; background-color: #F0E8FF; border: 2px dashed #8456D2; border-radius: 16px; padding: 18px 36px; text-align: center;">
                <span style="font-size: 36px; font-weight: 900; letter-spacing: 8px; color: #432F62; font-family: monospace;">{otpCode}</span>
              </div>
            </td>
          </tr>

          <!-- Expiry Notice -->
          <tr>
            <td>
              <p style="margin: 0 0 16px 0; font-size: 13px; line-height: 1.5; color: #74728A;">
                ⏱ <strong>ملاحظة:</strong> هذا الرمز صالح للاستخدام لمرة واحدة فقط لمدة <strong>{expiryMinutes} دقائق</strong> من وقت إرساله.
              </p>
              <div style="background-color: #FFF5F2; border-right: 4px solid #FF6B4A; border-radius: 8px; padding: 12px 16px; margin-bottom: 24px;">
                <p style="margin: 0; font-size: 12px; line-height: 1.5; color: #BD3737; font-weight: 600;">
                  🔒 لأسباب أمنية: لا تشارك هذا الرمز مع أي شخص. لن يطلب منك فريق ميندورا هذا الرمز عبر أي وسيلة أخرى.
                </p>
              </div>
              <p style="margin: 0; font-size: 12px; line-height: 1.5; color: #A09EAD;">
                إذا لم تكن قد أنشأت هذا الحساب بنفسك، يمكنك تجاهل هذه الرسالة ولن يتم تفعيل الحساب.
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="border-top: 1px solid #F0E8FF; padding-top: 24px; margin-top: 24px; text-align: center;">
              <p style="margin: 0; font-size: 11px; color: #A09EAD;">
                © 2026 منصة ميندورا • جميع الحقوق محفوظة
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
""";
    }

    private static string BuildOtpEmailBody(string otpCode, int expiryMinutes)
    {
        return $"""
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>رمز استعادة كلمة المرور</title>
</head>
<body style="margin: 0; padding: 0; background-color: #F7FAFC; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; text-align: right; direction: rtl;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color: #F7FAFC; padding: 40px 20px;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" style="max-width: 520px; background-color: #FFFFFF; border: 1px solid #E4D4FF; border-radius: 24px; padding: 36px 32px; box-shadow: 0 4px 20px rgba(67, 47, 98, 0.05);">
          <!-- Header -->
          <tr>
            <td align="center" style="padding-bottom: 24px;">
              <h1 style="margin: 0; font-size: 26px; font-weight: 800; color: #432F62;">منصة ميندورا | SAWA</h1>
              <p style="margin: 6px 0 0 0; font-size: 13px; font-weight: 600; color: #8456D2;">نظام التأهيل النمائي الذكي للأطفال</p>
            </td>
          </tr>

          <!-- Divider -->
          <tr>
            <td style="border-top: 1px solid #F0E8FF; padding-bottom: 24px;"></td>
          </tr>

          <!-- Greeting & Details -->
          <tr>
            <td>
              <h2 style="margin: 0 0 12px 0; font-size: 18px; font-weight: 700; color: #432F62;">طلب إعادة تعيين كلمة المرور</h2>
              <p style="margin: 0 0 20px 0; font-size: 14px; line-height: 1.6; color: #74728A;">
                لقد تلقينا طلباً لإعادة تعيين كلمة المرور الخاصة بحسابك في منصة ميندورا. استخدم رمز التحقق التالي لإتمام العملية:
              </p>
            </td>
          </tr>

          <!-- OTP Box -->
          <tr>
            <td align="center" style="padding: 16px 0 24px 0;">
              <div style="display: inline-block; background-color: #F0E8FF; border: 2px dashed #8456D2; border-radius: 16px; padding: 18px 36px; text-align: center;">
                <span style="font-size: 36px; font-weight: 900; letter-spacing: 8px; color: #432F62; font-family: monospace;">{otpCode}</span>
              </div>
            </td>
          </tr>

          <!-- Expiry Notice -->
          <tr>
            <td>
              <p style="margin: 0 0 16px 0; font-size: 13px; line-height: 1.5; color: #74728A;">
                ⏱ <strong>ملاحظة:</strong> هذا الرمز صالح للاستخدام لمرة واحدة فقط لمدة <strong>{expiryMinutes} دقائق</strong> من وقت إرساله.
              </p>
              <div style="background-color: #FFF5F2; border-right: 4px solid #FF6B4A; border-radius: 8px; padding: 12px 16px; margin-bottom: 24px;">
                <p style="margin: 0; font-size: 12px; line-height: 1.5; color: #BD3737; font-weight: 600;">
                  🔒 لأسباب أمنية: لا تشارك هذا الرمز مع أي شخص. لن يطلب منك فريق ميندورا أو أي ممثل عن المنصة هذا الرمز عبر الهاتف أو البريد.
                </p>
              </div>
              <p style="margin: 0; font-size: 12px; line-height: 1.5; color: #A09EAD;">
                إذا لم تكن أنت من قام بهذا الطلب، يمكنك تجاهل هذه الرسالة بأمان، وستبقى كلمة المرور الحالية لحسابك آمنة وغير متأثرة.
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="border-top: 1px solid #F0E8FF; padding-top: 24px; margin-top: 24px; text-align: center;">
              <p style="margin: 0; font-size: 11px; color: #A09EAD;">
                © 2026 منصة ميندورا • جميع الحقوق محفوظة
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
""";
    }
}
