using Microsoft.AspNetCore.Identity;
using Mindora.Application.Common.Interfaces;
using Mindora.Domain.Enums;

namespace Mindora.Infrastructure.Identity;

public class IdentityService : IIdentityService
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly RoleManager<IdentityRole<Guid>> _roleManager;

    public IdentityService(
        UserManager<ApplicationUser> userManager,
        RoleManager<IdentityRole<Guid>> roleManager)
    {
        _userManager = userManager;
        _roleManager = roleManager;
    }

    public async Task<(bool Succeeded, Guid UserId, string[] Errors)> CreateUserAsync(
        string email,
        string password,
        string fullName,
        UserRole role,
        CancellationToken cancellationToken = default)
    {
        var existing = await _userManager.FindByEmailAsync(email);
        if (existing != null)
        {
            return (false, Guid.Empty, new[] { "A user with this email address already exists." });
        }

        var user = new ApplicationUser
        {
            Id = Guid.NewGuid(),
            UserName = email.Trim().ToLowerInvariant(),
            Email = email.Trim().ToLowerInvariant(),
            FullName = fullName.Trim(),
            CreatedAtUtc = DateTime.UtcNow
        };

        var createResult = await _userManager.CreateAsync(user, password);
        if (!createResult.Succeeded)
        {
            return (false, Guid.Empty, createResult.Errors.Select(e => e.Description).ToArray());
        }

        var roleName = role.ToString();
        if (!await _roleManager.RoleExistsAsync(roleName))
        {
            await _roleManager.CreateAsync(new IdentityRole<Guid>(roleName));
        }

        var roleResult = await _userManager.AddToRoleAsync(user, roleName);
        if (!roleResult.Succeeded)
        {
            // Clean up created user if role assignment fails
            await _userManager.DeleteAsync(user);
            return (false, Guid.Empty, roleResult.Errors.Select(e => e.Description).ToArray());
        }

        return (true, user.Id, Array.Empty<string>());
    }

    public async Task<(bool Succeeded, Guid UserId, string Email, string FullName, UserRole Role, string[] Errors)> AuthenticateAsync(
        string email,
        string password,
        CancellationToken cancellationToken = default)
    {
        var user = await _userManager.FindByEmailAsync(email);
        if (user == null)
        {
            return (false, Guid.Empty, string.Empty, string.Empty, default, new[] { "Invalid email or password." });
        }

        var isPasswordValid = await _userManager.CheckPasswordAsync(user, password);
        if (!isPasswordValid)
        {
            return (false, Guid.Empty, string.Empty, string.Empty, default, new[] { "Invalid email or password." });
        }

        var roles = await _userManager.GetRolesAsync(user);
        var roleString = roles.FirstOrDefault();

        if (string.IsNullOrWhiteSpace(roleString) || !Enum.TryParse<UserRole>(roleString, ignoreCase: true, out var role))
        {
            return (false, Guid.Empty, string.Empty, string.Empty, default, new[] { "User does not have an assigned valid role." });
        }

        return (true, user.Id, user.Email ?? email, user.FullName, role, Array.Empty<string>());
    }

    public async Task<bool> UserExistsAsync(string email, CancellationToken cancellationToken = default)
    {
        var user = await _userManager.FindByEmailAsync(email);
        return user != null;
    }

    public async Task<(Guid UserId, string Email, string FullName, UserRole Role)?> GetUserByIdAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var user = await _userManager.FindByIdAsync(userId.ToString());
        if (user == null)
        {
            return null;
        }

        var roles = await _userManager.GetRolesAsync(user);
        var roleString = roles.FirstOrDefault();

        if (string.IsNullOrWhiteSpace(roleString) || !Enum.TryParse<UserRole>(roleString, ignoreCase: true, out var role))
        {
            return null;
        }

        return (user.Id, user.Email ?? string.Empty, user.FullName, role);
    }
}
