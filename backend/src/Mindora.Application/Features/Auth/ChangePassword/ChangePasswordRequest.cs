namespace Mindora.Application.Features.Auth.ChangePassword;

public record ChangePasswordRequest(
    string CurrentPassword,
    string NewPassword,
    string ConfirmPassword);
