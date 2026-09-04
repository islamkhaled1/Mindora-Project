using Mindora.Domain.Enums;

namespace Mindora.Application.Common.Interfaces;

/// <summary>
/// Abstraction for user account management, password authentication, and role checking.
/// Keeps ASP.NET Core Identity concepts strictly out of the Application layer.
/// </summary>
public interface IIdentityService
{
    Task<(bool Succeeded, Guid UserId, string[] Errors)> CreateUserAsync(
        string email,
        string password,
        string fullName,
        UserRole role,
        CancellationToken cancellationToken = default);

    Task<(bool Succeeded, Guid UserId, string Email, string FullName, UserRole Role, string[] Errors)> AuthenticateAsync(
        string email,
        string password,
        CancellationToken cancellationToken = default);

    Task<bool> UserExistsAsync(string email, CancellationToken cancellationToken = default);

    Task<(Guid UserId, string Email, string FullName, UserRole Role)?> GetUserByIdAsync(
        Guid userId,
        CancellationToken cancellationToken = default);
}
