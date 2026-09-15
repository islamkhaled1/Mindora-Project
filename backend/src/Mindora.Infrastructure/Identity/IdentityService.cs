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

    public async Task<(Guid UserId, string Email, string FullName, UserRole Role)?> GetUserByEmailAsync(
        string email,
        CancellationToken cancellationToken = default)
    {
        var user = await _userManager.FindByEmailAsync(email);
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

    public async Task<(bool Succeeded, string[] Errors)> ResetPasswordAsync(
        Guid userId,
        string newPassword,
        CancellationToken cancellationToken = default)
    {
        var user = await _userManager.FindByIdAsync(userId.ToString());
        if (user == null)
        {
            return (false, new[] { "User was not found." });
        }

        var identityToken = await _userManager.GeneratePasswordResetTokenAsync(user);
        var resetResult = await _userManager.ResetPasswordAsync(user, identityToken, newPassword);
        if (!resetResult.Succeeded)
        {
            return (false, resetResult.Errors.Select(e => e.Description).ToArray());
        }

        await _userManager.UpdateSecurityStampAsync(user);
        return (true, Array.Empty<string>());
    }

    public async Task<(bool Succeeded, string[] Errors)> ChangePasswordAsync(
        Guid userId,
        string currentPassword,
        string newPassword,
        CancellationToken cancellationToken = default)
    {
        var user = await _userManager.FindByIdAsync(userId.ToString());
        if (user == null)
        {
            return (false, new[] { "User was not found." });
        }

        var changeResult = await _userManager.ChangePasswordAsync(user, currentPassword, newPassword);
        if (!changeResult.Succeeded)
        {
            return (false, changeResult.Errors.Select(e => e.Description).ToArray());
        }

        await _userManager.UpdateSecurityStampAsync(user);
        return (true, Array.Empty<string>());
    }

    public async Task<(bool Succeeded, Guid UserId, string Email, string FullName, UserRole Role, bool IsDoctorConflict, string[] Errors)> AuthenticateOrLinkExternalLoginAsync(
        string provider,
        string providerKey,
        string email,
        string fullName,
        CancellationToken cancellationToken = default)
    {
        var normalizedEmail = email.Trim().ToLowerInvariant();

        // 1. Check if user is already linked with this external login provider & key
        var userByLogin = await _userManager.FindByLoginAsync(provider, providerKey);
        if (userByLogin != null)
        {
            var roles = await _userManager.GetRolesAsync(userByLogin);
            var roleString = roles.FirstOrDefault();
            if (string.IsNullOrWhiteSpace(roleString) || !Enum.TryParse<UserRole>(roleString, ignoreCase: true, out var userRole))
            {
                return (false, Guid.Empty, string.Empty, string.Empty, default, false, new[] { "User does not have an assigned valid role." });
            }

            if (userRole == UserRole.Doctor)
            {
                return (false, userByLogin.Id, userByLogin.Email ?? normalizedEmail, userByLogin.FullName, UserRole.Doctor, true, new[] { "هذا الحساب مسجل بالفعل على لوحة تحكم الطبيب." });
            }

            return (true, userByLogin.Id, userByLogin.Email ?? normalizedEmail, userByLogin.FullName, userRole, false, Array.Empty<string>());
        }

        // 2. Check if a user with the same verified email already exists
        var userByEmail = await _userManager.FindByEmailAsync(normalizedEmail);
        if (userByEmail != null)
        {
            var roles = await _userManager.GetRolesAsync(userByEmail);
            var roleString = roles.FirstOrDefault();
            if (string.IsNullOrWhiteSpace(roleString) || !Enum.TryParse<UserRole>(roleString, ignoreCase: true, out var userRole))
            {
                return (false, Guid.Empty, string.Empty, string.Empty, default, false, new[] { "User does not have an assigned valid role." });
            }

            // CRITICAL: Existing Doctor account with SAME email must be BLOCKED from SAWA
            if (userRole == UserRole.Doctor)
            {
                return (false, userByEmail.Id, userByEmail.Email ?? normalizedEmail, userByEmail.FullName, UserRole.Doctor, true, new[] { "هذا الحساب مسجل بالفعل على لوحة تحكم الطبيب." });
            }

            // Securely link external login to the existing Parent account
            var addLoginResult = await _userManager.AddLoginAsync(userByEmail, new UserLoginInfo(provider, providerKey, provider));
            if (!addLoginResult.Succeeded)
            {
                // If it was already linked (e.g. race condition), check if login exists
                var logins = await _userManager.GetLoginsAsync(userByEmail);
                if (!logins.Any(l => l.LoginProvider == provider && l.ProviderKey == providerKey))
                {
                    return (false, Guid.Empty, string.Empty, string.Empty, default, false, addLoginResult.Errors.Select(e => e.Description).ToArray());
                }
            }

            if (!userByEmail.EmailConfirmed)
            {
                userByEmail.EmailConfirmed = true;
                await _userManager.UpdateAsync(userByEmail);
            }

            return (true, userByEmail.Id, userByEmail.Email ?? normalizedEmail, userByEmail.FullName, UserRole.Parent, false, Array.Empty<string>());
        }

        // 3. Brand new user -> create Parent account
        var newUser = new ApplicationUser
        {
            Id = Guid.NewGuid(),
            UserName = normalizedEmail,
            Email = normalizedEmail,
            EmailConfirmed = true,
            FullName = string.IsNullOrWhiteSpace(fullName) ? normalizedEmail.Split('@')[0] : fullName.Trim(),
            CreatedAtUtc = DateTime.UtcNow
        };

        var createResult = await _userManager.CreateAsync(newUser);
        if (!createResult.Succeeded)
        {
            return (false, Guid.Empty, string.Empty, string.Empty, default, false, createResult.Errors.Select(e => e.Description).ToArray());
        }

        var roleName = UserRole.Parent.ToString();
        if (!await _roleManager.RoleExistsAsync(roleName))
        {
            await _roleManager.CreateAsync(new IdentityRole<Guid>(roleName));
        }

        var roleResult = await _userManager.AddToRoleAsync(newUser, roleName);
        if (!roleResult.Succeeded)
        {
            await _userManager.DeleteAsync(newUser);
            return (false, Guid.Empty, string.Empty, string.Empty, default, false, roleResult.Errors.Select(e => e.Description).ToArray());
        }

        var loginResult = await _userManager.AddLoginAsync(newUser, new UserLoginInfo(provider, providerKey, provider));
        if (!loginResult.Succeeded)
        {
            await _userManager.DeleteAsync(newUser);
            return (false, Guid.Empty, string.Empty, string.Empty, default, false, loginResult.Errors.Select(e => e.Description).ToArray());
        }

        return (true, newUser.Id, newUser.Email, newUser.FullName, UserRole.Parent, false, Array.Empty<string>());
    }

    public async Task<bool> IsEmailConfirmedAsync(
        string email,
        CancellationToken cancellationToken = default)
    {
        var user = await _userManager.FindByEmailAsync(email.Trim().ToLowerInvariant());
        return user != null && user.EmailConfirmed;
    }

    public async Task<(bool Succeeded, string[] Errors)> ConfirmEmailAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var user = await _userManager.FindByIdAsync(userId.ToString());
        if (user == null)
        {
            return (false, new[] { "User was not found." });
        }

        if (user.EmailConfirmed)
        {
            return (true, Array.Empty<string>());
        }

        user.EmailConfirmed = true;
        var updateResult = await _userManager.UpdateAsync(user);
        if (!updateResult.Succeeded)
        {
            return (false, updateResult.Errors.Select(e => e.Description).ToArray());
        }

        await _userManager.UpdateSecurityStampAsync(user);
        return (true, Array.Empty<string>());
    }
}
