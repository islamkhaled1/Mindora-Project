namespace Mindora.Application.Features.Auth.VerifyEmail;

public record VerifyEmailRequest(
    string Email,
    string Otp,
    string? Platform = null);
