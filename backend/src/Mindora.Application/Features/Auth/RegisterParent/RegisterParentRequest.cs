namespace Mindora.Application.Features.Auth.RegisterParent;

public record RegisterParentRequest(
    string Email,
    string Password,
    string FullName,
    string? PhoneNumber);
