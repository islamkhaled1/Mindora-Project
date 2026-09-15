using Mindora.Application.Features.Auth.Models;

namespace Mindora.Application.Features.Auth.VerifyEmail;

public record VerifyEmailResponseDto(
    bool Succeeded,
    string Message,
    string? Token = null,
    DateTime? ExpiresAtUtc = null,
    AuthUserDto? User = null);
