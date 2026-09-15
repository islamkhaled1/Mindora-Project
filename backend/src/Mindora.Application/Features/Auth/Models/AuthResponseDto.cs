namespace Mindora.Application.Features.Auth.Models;

public record AuthUserDto(
    Guid Id,
    string Email,
    string FullName,
    string Role,
    Guid ProfileId);

public record AuthResponseDto(
    string? Token,
    DateTime? ExpiresAtUtc,
    AuthUserDto? User,
    bool RequiresEmailVerification = false,
    string? Message = null);
