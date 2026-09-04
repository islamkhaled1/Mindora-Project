namespace Mindora.Infrastructure.Identity;

/// <summary>
/// Strongly typed options for JWT Bearer token generation and validation.
/// </summary>
public class JwtOptions
{
    public const string SectionName = "Jwt";

    public string Issuer { get; set; } = "Mindora";
    public string Audience { get; set; } = "MindoraApp";
    public string SecretKey { get; set; } = string.Empty;
    public int ExpirationMinutes { get; set; } = 120;
}
