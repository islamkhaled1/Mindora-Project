namespace Mindora.Application.Features.Auth.SendVerificationOtp;

public record SendVerificationOtpResponseDto(
    bool Succeeded,
    string Message,
    bool AlreadyVerified = false);
