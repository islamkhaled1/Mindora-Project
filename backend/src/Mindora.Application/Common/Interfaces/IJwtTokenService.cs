using Mindora.Application.Common.Models;
using Mindora.Domain.Enums;

namespace Mindora.Application.Common.Interfaces;

/// <summary>
/// Abstraction for generating authentication tokens for authenticated users.
/// Implemented by Infrastructure; decoupled from ASP.NET Identity and JWT libraries.
/// </summary>
public interface IJwtTokenService
{
    AuthTokenResult GenerateToken(Guid userId, string email, string fullName, UserRole role, Guid profileId);
}
