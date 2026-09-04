namespace Mindora.Application.Common.Models;

/// <summary>
/// Represents the result of generating an authentication token.
/// </summary>
public record AuthTokenResult(string Token, DateTime ExpiresAtUtc);
