using Microsoft.AspNetCore.Identity;

namespace Mindora.Infrastructure.Identity;

/// <summary>
/// ASP.NET Core Identity user representing authentication credentials and identity.
/// Strictly contained in Infrastructure; Domain remains independent of Identity framework.
/// </summary>
public class ApplicationUser : IdentityUser<Guid>
{
    public string FullName { get; set; } = string.Empty;
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
}
