using Google.Apis.Auth;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;

namespace Mindora.Infrastructure.Identity;

/// <summary>
/// Production implementation of Google ID token validation using Google.Apis.Auth.
/// Validates cryptographic signature, issuer, audience, and expiration against Google's public keys.
/// </summary>
public class GoogleTokenValidator : IGoogleTokenValidator
{
    private readonly GoogleAuthOptions _options;
    private readonly ILogger<GoogleTokenValidator> _logger;

    public GoogleTokenValidator(
        IOptions<GoogleAuthOptions> options,
        ILogger<GoogleTokenValidator> logger)
    {
        _options = options.Value;
        _logger = logger;
    }

    public async Task<GoogleTokenPayload> ValidateAsync(string idToken, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(idToken))
        {
            throw new UnauthorizedException("Google ID token is required.");
        }

        try
        {
            var settings = new GoogleJsonWebSignature.ValidationSettings
            {
                Audience = new[] { _options.ClientId }
            };

            var payload = await GoogleJsonWebSignature.ValidateAsync(idToken, settings);

            if (payload == null)
            {
                throw new UnauthorizedException("Invalid Google ID token payload.");
            }

            if (!payload.EmailVerified)
            {
                throw new BadRequestException("Google email address is not verified.");
            }

            if (string.IsNullOrWhiteSpace(payload.Email))
            {
                throw new BadRequestException("Google ID token missing email claim.");
            }

            if (string.IsNullOrWhiteSpace(payload.Subject))
            {
                throw new BadRequestException("Google ID token missing subject claim.");
            }

            return new GoogleTokenPayload(
                payload.Subject,
                payload.Email.Trim().ToLowerInvariant(),
                payload.EmailVerified,
                payload.Name,
                payload.Picture);
        }
        catch (InvalidJwtException ex)
        {
            _logger.LogWarning("Google ID token validation failed: {Message}", ex.Message);
            throw new UnauthorizedException("Invalid or expired Google token.");
        }
        catch (BadRequestException)
        {
            throw;
        }
        catch (Exception ex)
        {
            _logger.LogWarning("Unexpected error validating Google ID token: {Message}", ex.Message);
            throw new UnauthorizedException("Failed to validate Google token.");
        }
    }
}
