using Mindora.Domain.Enums;

namespace Mindora.Application.Common.Interfaces;

/// <summary>
/// Provides access to the current authenticated user's identity and role.
/// Domain-neutral; decoupled from HTTP context and ASP.NET Core claims.
/// </summary>
public interface ICurrentUserService
{
    Guid? UserId { get; }
    UserRole? Role { get; }
    bool IsAuthenticated { get; }
}
