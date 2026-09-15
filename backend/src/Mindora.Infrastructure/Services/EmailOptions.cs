namespace Mindora.Infrastructure.Services;

/// <summary>
/// Strongly typed configuration options for transactional email delivery via Brevo SMTP.
/// Credentials are read from environment variables or configuration and must never be hardcoded.
/// </summary>
public class EmailOptions
{
    public const string SectionName = "Email";

    public string SmtpHost { get; set; } = "smtp-relay.brevo.com";
    public int SmtpPort { get; set; } = 587;
    public string Username { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string FromEmail { get; set; } = "noreply@mindora.app";
    public string FromName { get; set; } = "Mindora";
    public bool EnableSsl { get; set; } = true;
    public int TimeoutMs { get; set; } = 15000;

    public bool IsConfigured =>
        !string.IsNullOrWhiteSpace(SmtpHost) &&
        !string.IsNullOrWhiteSpace(Username) &&
        !string.IsNullOrWhiteSpace(Password);
}
