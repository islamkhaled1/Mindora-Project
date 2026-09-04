namespace Mindora.Application.Features.Auth.GetCurrentUser;

public record CurrentUserDto(
    Guid UserId,
    string Email,
    string FullName,
    string Role,
    Guid ProfileId);
