namespace Mindora.Application.Features.Auth.ResetPassword;

public record ResetPasswordRequest(
    string ResetToken,
    string NewPassword,
    string ConfirmPassword,
    string? Platform = null);
