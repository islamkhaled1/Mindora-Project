using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using Mindora.Domain.Enums;
using Mindora.Infrastructure.Identity;
using Mindora.Infrastructure.Services;
using Xunit;

namespace Mindora.UnitTests.Infrastructure;

public class AuthenticationAndJwtTests
{
    private static IOptions<JwtOptions> CreateJwtOptions(string secretKey = "MindoraTestSecretKeyMinimum32CharactersLong2026!")
    {
        return Options.Create(new JwtOptions
        {
            Issuer = "Mindora",
            Audience = "MindoraApp",
            SecretKey = secretKey,
            ExpirationMinutes = 60
        });
    }

    [Fact]
    public void JwtTokenService_Generates_Token_With_Required_Claims()
    {
        // Arrange
        var service = new JwtTokenService(CreateJwtOptions());
        var userId = Guid.NewGuid();
        var profileId = Guid.NewGuid();
        var email = "parent@mindora.com";
        var fullName = "Sarah Miller";
        var role = UserRole.Parent;

        // Act
        var tokenResult = service.GenerateToken(userId, email, fullName, role, profileId);

        // Assert
        Assert.NotNull(tokenResult.Token);
        Assert.True(tokenResult.ExpiresAtUtc > DateTime.UtcNow);

        var handler = new JwtSecurityTokenHandler();
        var jwtToken = handler.ReadJwtToken(tokenResult.Token);

        Assert.Equal("Mindora", jwtToken.Issuer);
        Assert.Contains("MindoraApp", jwtToken.Audiences);

        Assert.Equal(userId.ToString(), jwtToken.Claims.First(c => c.Type == JwtRegisteredClaimNames.Sub).Value);
        Assert.Equal(email, jwtToken.Claims.First(c => c.Type == JwtRegisteredClaimNames.Email).Value);
        Assert.Equal(fullName, jwtToken.Claims.First(c => c.Type == JwtRegisteredClaimNames.Name).Value);
        Assert.Equal("Parent", jwtToken.Claims.First(c => c.Type == "role").Value);
        Assert.Equal(profileId.ToString(), jwtToken.Claims.First(c => c.Type == "profile_id").Value);
    }

    [Fact]
    public void JwtTokenService_Throws_When_SecretKey_Is_Too_Short()
    {
        // Arrange
        var shortKeyOptions = CreateJwtOptions(secretKey: "short-key");

        // Act & Assert
        var ex = Assert.Throws<InvalidOperationException>(() => new JwtTokenService(shortKeyOptions));
        Assert.Contains("at least 32 characters", ex.Message);
    }

    [Fact]
    public void CurrentUserService_Extracts_Identity_From_ClaimsPrincipal()
    {
        // Arrange
        var userId = Guid.NewGuid();
        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, userId.ToString()),
            new(ClaimTypes.Role, "Doctor")
        };
        var identity = new ClaimsIdentity(claims, "TestAuth");
        var principal = new ClaimsPrincipal(identity);

        var httpContext = new DefaultHttpContext { User = principal };
        var httpContextAccessor = new HttpContextAccessor { HttpContext = httpContext };

        var currentUserService = new CurrentUserService(httpContextAccessor);

        // Act & Assert
        Assert.True(currentUserService.IsAuthenticated);
        Assert.Equal(userId, currentUserService.UserId);
        Assert.Equal(UserRole.Doctor, currentUserService.Role);
    }

    [Fact]
    public void CurrentUserService_Handles_Unauthenticated_Context_Safely()
    {
        // Arrange
        var httpContext = new DefaultHttpContext(); // No user identity
        var httpContextAccessor = new HttpContextAccessor { HttpContext = httpContext };

        var currentUserService = new CurrentUserService(httpContextAccessor);

        // Act & Assert
        Assert.False(currentUserService.IsAuthenticated);
        Assert.Null(currentUserService.UserId);
        Assert.Null(currentUserService.Role);
    }

    [Fact]
    public void CurrentUserService_Handles_Malformed_Claims_Safely()
    {
        // Arrange
        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, "not-a-valid-guid"),
            new(ClaimTypes.Role, "InvalidRoleValue")
        };
        var identity = new ClaimsIdentity(claims, "TestAuth");
        var principal = new ClaimsPrincipal(identity);

        var httpContext = new DefaultHttpContext { User = principal };
        var httpContextAccessor = new HttpContextAccessor { HttpContext = httpContext };

        var currentUserService = new CurrentUserService(httpContextAccessor);

        // Act & Assert (Must not throw uncontrolled exception)
        Assert.True(currentUserService.IsAuthenticated);
        Assert.Null(currentUserService.UserId);
        Assert.Null(currentUserService.Role);
    }
}
