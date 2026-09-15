using FluentValidation;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using Mindora.Application;
using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Features.Auth.ForgotPassword;
using Mindora.Application.Features.Auth.Login;
using Mindora.Application.Features.Auth.Models;
using Mindora.Application.Features.Auth.RegisterDoctor;
using Mindora.Application.Features.Auth.RegisterParent;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;
using Mindora.Infrastructure.Identity;
using Mindora.Infrastructure.Persistence;
using Mindora.Infrastructure.Services;
using Xunit;

namespace Mindora.UnitTests.Features.Auth;

public class TestGoogleTokenValidator : IGoogleTokenValidator
{
    public Func<string, Task<GoogleTokenPayload>>? ValidatorFunc { get; set; }

    public Task<GoogleTokenPayload> ValidateAsync(string idToken, CancellationToken cancellationToken = default)
    {
        if (ValidatorFunc != null)
        {
            return ValidatorFunc(idToken);
        }

        if (idToken == "valid_parent_token")
        {
            return Task.FromResult(new GoogleTokenPayload(
                Subject: "google-sub-12345",
                Email: "parent.google@test.com",
                EmailVerified: true,
                Name: "Google Parent",
                Picture: "https://photo.jpg"));
        }

        if (idToken == "unverified_email_token")
        {
            return Task.FromResult(new GoogleTokenPayload(
                Subject: "google-sub-unverified",
                Email: "unverified@test.com",
                EmailVerified: false,
                Name: "Unverified User",
                Picture: null));
        }

        if (idToken == "doctor_token")
        {
            return Task.FromResult(new GoogleTokenPayload(
                Subject: "google-sub-doctor",
                Email: "doctor@test.com",
                EmailVerified: true,
                Name: "Dr. Ahmed",
                Picture: null));
        }

        if (idToken == "wrong_audience_token")
        {
            throw new UnauthorizedException("Invalid or expired Google token.");
        }

        if (idToken == "expired_token")
        {
            throw new UnauthorizedException("Invalid or expired Google token.");
        }

        if (idToken == "tampered_token")
        {
            throw new UnauthorizedException("Invalid or expired Google token.");
        }

        throw new UnauthorizedException("Unknown token.");
    }
}

public class GoogleAuthFeatureTests : IDisposable
{
    private readonly ServiceProvider _serviceProvider;
    private readonly ApplicationDbContext _dbContext;
    private readonly IIdentityService _identityService;
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly TestGoogleTokenValidator _googleTokenValidator;
    private readonly GoogleLoginHandler _googleLoginHandler;
    private readonly LoginHandler _loginHandler;
    private readonly ForgotPasswordHandler _forgotPasswordHandler;

    public GoogleAuthFeatureTests()
    {
        var services = new ServiceCollection();
        services.AddLogging();

        var dbName = Guid.NewGuid().ToString();
        services.AddDbContext<ApplicationDbContext>(options =>
            options.UseInMemoryDatabase(dbName));

        services.AddScoped<IApplicationDbContext>(sp => sp.GetRequiredService<ApplicationDbContext>());

        services.AddIdentity<ApplicationUser, IdentityRole<Guid>>(options =>
        {
            options.Password.RequireDigit = true;
            options.Password.RequiredLength = 8;
            options.Password.RequireNonAlphanumeric = false;
            options.Password.RequireUppercase = false;
            options.Password.RequireLowercase = false;
            options.User.RequireUniqueEmail = true;
        })
        .AddEntityFrameworkStores<ApplicationDbContext>()
        .AddDefaultTokenProviders();

        services.AddScoped<IIdentityService, IdentityService>();

        services.Configure<JwtOptions>(opt =>
        {
            opt.Issuer = "Mindora";
            opt.Audience = "MindoraApp";
            opt.SecretKey = "MindoraTestSecretKeyMinimum32CharactersLong2026!";
            opt.ExpirationMinutes = 60;
        });
        services.AddScoped<IJwtTokenService, JwtTokenService>();

        _googleTokenValidator = new TestGoogleTokenValidator();
        services.AddSingleton<IGoogleTokenValidator>(_googleTokenValidator);

        services.AddSingleton<IEmailService>(new MockEmailService());
        services.AddHttpContextAccessor();
        services.AddScoped<ICurrentUserService, CurrentUserService>();

        services.AddApplicationServices();

        _serviceProvider = services.BuildServiceProvider();
        _dbContext = _serviceProvider.GetRequiredService<ApplicationDbContext>();
        _identityService = _serviceProvider.GetRequiredService<IIdentityService>();
        _userManager = _serviceProvider.GetRequiredService<UserManager<ApplicationUser>>();
        _googleLoginHandler = _serviceProvider.GetRequiredService<GoogleLoginHandler>();
        _loginHandler = _serviceProvider.GetRequiredService<LoginHandler>();
        _forgotPasswordHandler = _serviceProvider.GetRequiredService<ForgotPasswordHandler>();
    }

    public void Dispose()
    {
        _dbContext.Dispose();
        _serviceProvider.Dispose();
    }

    private class MockEmailService : IEmailService
    {
        public Task SendPasswordResetOtpAsync(string toEmail, string otpCode, int expiryMinutes, CancellationToken cancellationToken = default)
            => Task.CompletedTask;

        public Task SendEmailVerificationOtpAsync(string toEmail, string otpCode, int expiryMinutes, ClientPlatform platform, CancellationToken cancellationToken = default)
            => Task.CompletedTask;
    }

    [Fact]
    public async Task Scenario1_ValidGoogleToken_NewEmail_CreatesParentAccountAndProfile()
    {
        // Act
        var result = await _googleLoginHandler.HandleAsync(new GoogleLoginRequest("valid_parent_token"));

        // Assert
        Assert.NotNull(result);
        Assert.NotEmpty(result.Token);
        Assert.Equal("parent.google@test.com", result.User.Email);
        Assert.Equal("Parent", result.User.Role);
        Assert.NotEqual(Guid.Empty, result.User.ProfileId);

        var user = await _userManager.FindByEmailAsync("parent.google@test.com");
        Assert.NotNull(user);
        Assert.True(user.EmailConfirmed);

        var profile = await _dbContext.ParentProfiles.FirstOrDefaultAsync(p => p.UserId == user.Id);
        Assert.NotNull(profile);
        Assert.Equal(result.User.ProfileId, profile.Id);
    }

    [Fact]
    public async Task Scenario2_ValidGoogleToken_ExistingParent_LogsInSuccessfully()
    {
        // Arrange: Create existing Parent account with password
        var regHandler = _serviceProvider.GetRequiredService<RegisterParentHandler>();
        var regResult = await regHandler.HandleAsync(new RegisterParentRequest("parent.google@test.com", "Password123!", "Existing Parent", "01012345678"));

        // Act: Login via Google with the same email
        var googleResult = await _googleLoginHandler.HandleAsync(new GoogleLoginRequest("valid_parent_token"));

        // Assert
        Assert.NotNull(googleResult);
        Assert.Equal(regResult.User.Id, googleResult.User.Id);
        Assert.Equal("parent.google@test.com", googleResult.User.Email);
        Assert.Equal("Parent", googleResult.User.Role);
    }

    [Fact]
    public async Task Scenario3_ExistingParentEmail_DoesNotCreateDuplicateUser()
    {
        // Arrange
        var regHandler = _serviceProvider.GetRequiredService<RegisterParentHandler>();
        await regHandler.HandleAsync(new RegisterParentRequest("parent.google@test.com", "Password123!", "Existing Parent", "01012345678"));

        // Act
        await _googleLoginHandler.HandleAsync(new GoogleLoginRequest("valid_parent_token"));

        // Assert
        var users = await _userManager.Users.Where(u => u.Email == "parent.google@test.com").ToListAsync();
        Assert.Single(users);
    }

    [Fact]
    public async Task Scenario4_GoogleSub_CreatesProperAspNetUserLogins()
    {
        // Act
        var result = await _googleLoginHandler.HandleAsync(new GoogleLoginRequest("valid_parent_token"));

        // Assert
        var user = await _userManager.FindByIdAsync(result.User.Id.ToString());
        Assert.NotNull(user);
        var logins = await _userManager.GetLoginsAsync(user);
        Assert.Contains(logins, l => l.LoginProvider == "Google" && l.ProviderKey == "google-sub-12345");
    }

    [Fact]
    public async Task Scenario5_RepeatedSameGoogleSub_LogsIntoSameAccount()
    {
        // First login
        var result1 = await _googleLoginHandler.HandleAsync(new GoogleLoginRequest("valid_parent_token"));

        // Second login with same token / sub
        var result2 = await _googleLoginHandler.HandleAsync(new GoogleLoginRequest("valid_parent_token"));

        // Assert: Same user ID and same profile ID
        Assert.Equal(result1.User.Id, result2.User.Id);
        Assert.Equal(result1.User.ProfileId, result2.User.ProfileId);

        var totalUsers = await _userManager.Users.CountAsync();
        Assert.Equal(1, totalUsers);

        var totalProfiles = await _dbContext.ParentProfiles.CountAsync();
        Assert.Equal(1, totalProfiles);
    }

    [Fact]
    public async Task Scenario6_ExistingDoctorEmail_IsBlockedFromSawa()
    {
        // Arrange: Create Doctor account with email "doctor@test.com"
        var docHandler = _serviceProvider.GetRequiredService<RegisterDoctorHandler>();
        await docHandler.HandleAsync(new RegisterDoctorRequest(
            "doctor@test.com",
            "DocPass123!",
            "Dr. Ahmed",
            "Specialist",
            "Clinic A",
            "LIC123",
            "Male"));

        // Act & Assert: Google Sign-In with Doctor's email must throw ConflictException with specific Arabic message
        var ex = await Assert.ThrowsAsync<ConflictException>(() =>
            _googleLoginHandler.HandleAsync(new GoogleLoginRequest("doctor_token")));

        Assert.Equal("هذا الحساب مسجل بالفعل على لوحة تحكم الطبيب.", ex.Message);

        // Confirm role was NOT converted to Parent
        var user = await _userManager.FindByEmailAsync("doctor@test.com");
        Assert.NotNull(user);
        var roles = await _userManager.GetRolesAsync(user);
        Assert.Contains("Doctor", roles);
        Assert.DoesNotContain("Parent", roles);
    }

    [Fact]
    public async Task Scenario7_UnverifiedGoogleEmail_IsRejected()
    {
        // Act & Assert: Token with EmailVerified = false must be rejected
        var ex = await Assert.ThrowsAsync<BadRequestException>(() =>
            _googleLoginHandler.HandleAsync(new GoogleLoginRequest("unverified_email_token")));

        Assert.Equal("Google email address is not verified.", ex.Message);
    }

    [Fact]
    public async Task Scenario8_WrongAudienceToken_IsRejected()
    {
        // Act & Assert
        await Assert.ThrowsAsync<UnauthorizedException>(() =>
            _googleLoginHandler.HandleAsync(new GoogleLoginRequest("wrong_audience_token")));
    }

    [Fact]
    public async Task Scenario9_ExpiredToken_IsRejected()
    {
        // Act & Assert
        await Assert.ThrowsAsync<UnauthorizedException>(() =>
            _googleLoginHandler.HandleAsync(new GoogleLoginRequest("expired_token")));
    }

    [Fact]
    public async Task Scenario10_InvalidOrTamperedToken_IsRejected()
    {
        // Act & Assert
        await Assert.ThrowsAsync<UnauthorizedException>(() =>
            _googleLoginHandler.HandleAsync(new GoogleLoginRequest("tampered_token")));
    }

    [Fact]
    public async Task Scenario11_ExistingParentEmail_WithoutExternalLogin_SafelyLinked()
    {
        // Arrange: Existing Parent registered through standard email/password
        var regHandler = _serviceProvider.GetRequiredService<RegisterParentHandler>();
        await regHandler.HandleAsync(new RegisterParentRequest("parent.google@test.com", "Password123!", "Existing Parent", null));

        var userBefore = await _userManager.FindByEmailAsync("parent.google@test.com");
        Assert.NotNull(userBefore);
        var loginsBefore = await _userManager.GetLoginsAsync(userBefore);
        Assert.Empty(loginsBefore);

        // Act: Sign in with Google
        var result = await _googleLoginHandler.HandleAsync(new GoogleLoginRequest("valid_parent_token"));

        // Assert: Logins now contain Google external login
        var loginsAfter = await _userManager.GetLoginsAsync(userBefore);
        Assert.Single(loginsAfter);
        Assert.Equal("Google", loginsAfter[0].LoginProvider);
        Assert.Equal("google-sub-12345", loginsAfter[0].ProviderKey);
    }

    [Fact]
    public async Task Scenario12_DuplicateExternalLogin_Prevented()
    {
        // First login links the Google sub
        await _googleLoginHandler.HandleAsync(new GoogleLoginRequest("valid_parent_token"));

        // Repeat login
        await _googleLoginHandler.HandleAsync(new GoogleLoginRequest("valid_parent_token"));

        var user = await _userManager.FindByEmailAsync("parent.google@test.com");
        Assert.NotNull(user);
        var logins = await _userManager.GetLoginsAsync(user);
        Assert.Single(logins); // Exactly 1 login entry, not duplicated
    }

    [Fact]
    public async Task Scenario13_RoleRemainsParent()
    {
        var result = await _googleLoginHandler.HandleAsync(new GoogleLoginRequest("valid_parent_token"));

        var user = await _userManager.FindByIdAsync(result.User.Id.ToString());
        Assert.NotNull(user);
        var roles = await _userManager.GetRolesAsync(user);
        Assert.Equal(new[] { "Parent" }, roles);
    }

    [Fact]
    public async Task Scenario14_ExistingEmailPasswordLogin_RemainsFunctional()
    {
        // Arrange: Parent registered with password
        var regHandler = _serviceProvider.GetRequiredService<RegisterParentHandler>();
        await regHandler.HandleAsync(new RegisterParentRequest("parent.google@test.com", "Password123!", "Normal Parent", null));

        // Act 1: User signs in with Google (linking the account)
        var googleResult = await _googleLoginHandler.HandleAsync(new GoogleLoginRequest("valid_parent_token"));
        Assert.NotNull(googleResult);

        // Act 2: User subsequently signs in with original email and password
        var pwResult = await _loginHandler.HandleAsync(new LoginRequest("parent.google@test.com", "Password123!"));

        // Assert: Email/password authentication still succeeds seamlessly
        Assert.NotNull(pwResult);
        Assert.Equal(googleResult.User.Id, pwResult.User.Id);
    }

    [Fact]
    public async Task Scenario15_ExistingPlatformAwareForgotPassword_RemainsFunctional()
    {
        // Arrange: User signs in with Google
        await _googleLoginHandler.HandleAsync(new GoogleLoginRequest("valid_parent_token"));

        // Act: Request forgot password on SAWA platform
        var fpResponse = await _forgotPasswordHandler.HandleAsync(new ForgotPasswordRequest("parent.google@test.com", "SawaApp"));

        // Assert: OTP generated and flow continues
        Assert.Equal(ForgotPasswordStatus.ContinueReset, fpResponse.Status);

        // Attempting forgot password from DoctorDashboard with this parent account must return WrongPlatform
        var doctorFpResponse = await _forgotPasswordHandler.HandleAsync(new ForgotPasswordRequest("parent.google@test.com", "DoctorDashboard"));
        Assert.Equal(ForgotPasswordStatus.WrongPlatform, doctorFpResponse.Status);
    }

    [Fact]
    public async Task Scenario16_EmptyToken_FailsValidation()
    {
        await Assert.ThrowsAsync<Mindora.Application.Common.Exceptions.ValidationException>(() =>
            _googleLoginHandler.HandleAsync(new GoogleLoginRequest("")));
    }
}
