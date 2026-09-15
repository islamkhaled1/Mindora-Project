namespace Mindora.Application.Features.Auth.ForgotPassword;

public static class ForgotPasswordStatus
{
    public const string ContinueReset = "ContinueReset";
    public const string WrongPlatform = "WrongPlatform";
}

public record ForgotPasswordResponseDto(
    string Message,
    string Status = ForgotPasswordStatus.ContinueReset,
    string? TargetPlatform = null);
