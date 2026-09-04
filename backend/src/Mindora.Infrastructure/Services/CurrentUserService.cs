using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Mindora.Application.Common.Interfaces;
using Mindora.Domain.Enums;

namespace Mindora.Infrastructure.Services;

/// <summary>
/// Implements ICurrentUserService by safely inspecting the current HTTP request ClaimsPrincipal.
/// Keeps HTTP concerns strictly isolated in Infrastructure.
/// </summary>
public class CurrentUserService : ICurrentUserService
{
    private readonly IHttpContextAccessor _httpContextAccessor;

    public CurrentUserService(IHttpContextAccessor httpContextAccessor)
    {
        _httpContextAccessor = httpContextAccessor;
    }

    public Guid? UserId
    {
        get
        {
            var user = _httpContextAccessor.HttpContext?.User;
            if (user?.Identity?.IsAuthenticated != true)
            {
                return null;
            }

            var userIdClaim = user.FindFirst(ClaimTypes.NameIdentifier)?.Value
                ?? user.FindFirst(JwtRegisteredClaimNames.Sub)?.Value
                ?? user.FindFirst("sub")?.Value;

            if (Guid.TryParse(userIdClaim, out var userId))
            {
                return userId;
            }

            return null;
        }
    }

    public UserRole? Role
    {
        get
        {
            var user = _httpContextAccessor.HttpContext?.User;
            if (user?.Identity?.IsAuthenticated != true)
            {
                return null;
            }

            var roleClaim = user.FindFirst(ClaimTypes.Role)?.Value
                ?? user.FindFirst("role")?.Value;

            if (!string.IsNullOrWhiteSpace(roleClaim) &&
                Enum.TryParse<UserRole>(roleClaim, ignoreCase: true, out var role))
            {
                return role;
            }

            return null;
        }
    }

    public bool IsAuthenticated =>
        _httpContextAccessor.HttpContext?.User?.Identity?.IsAuthenticated ?? false;
}
