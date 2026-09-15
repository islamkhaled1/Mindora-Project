namespace Mindora.Application.Features.Auth.SendVerificationOtp;

public record SendVerificationOtpRequest(
    string Email,
    string? Platform = null);
