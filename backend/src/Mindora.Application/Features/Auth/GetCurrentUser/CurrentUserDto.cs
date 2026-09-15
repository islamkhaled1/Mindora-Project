namespace Mindora.Application.Features.Auth.GetCurrentUser;

public record CurrentUserDto(
    Guid UserId,
    string Email,
    string FullName,
    string Role,
    Guid ProfileId,
    string? Gender = null,
    string? Specialization = null,
    string? ClinicName = null,
    string? ReferralCode = null);
