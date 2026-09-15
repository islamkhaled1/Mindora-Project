namespace Mindora.Application.Common.Interfaces;

public record GoogleTokenPayload(
    string Subject,
    string Email,
    bool EmailVerified,
    string? Name,
    string? Picture);

public interface IGoogleTokenValidator
{
    Task<GoogleTokenPayload> ValidateAsync(string idToken, CancellationToken cancellationToken = default);
}
