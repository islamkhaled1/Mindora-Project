namespace Mindora.Application.Features.Auth.ForgotPassword;

public record ForgotPasswordRequest(string Email, string? Platform = null);
