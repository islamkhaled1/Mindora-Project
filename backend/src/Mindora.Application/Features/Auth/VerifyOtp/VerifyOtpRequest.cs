namespace Mindora.Application.Features.Auth.VerifyOtp;

public record VerifyOtpRequest(string Email, string Otp, string? Platform = null);
