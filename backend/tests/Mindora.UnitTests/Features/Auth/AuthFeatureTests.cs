using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using FluentValidation;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using Mindora.Application;
using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Features.Auth.GetCurrentUser;
using Mindora.Application.Features.Auth.Login;
using Mindora.Application.Features.Auth.RegisterDoctor;
using Mindora.Application.Features.Auth.RegisterParent;
using Mindora.Domain.Enums;
using Mindora.Infrastructure.Identity;
using Mindora.Infrastructure.Persistence;
using Mindora.Infrastructure.Services;
using Xunit;

namespace Mindora.UnitTests.Features.Auth;

public class AuthFeatureTests : IDisposable
{
    private readonly ServiceProvider _serviceProvider;
    private readonly ApplicationDbContext _dbContext;

    public AuthFeatureTests()
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

        services.AddHttpContextAccessor();
        services.AddScoped<ICurrentUserService, CurrentUserService>();

        services.AddApplicationServices();

        _serviceProvider = services.BuildServiceProvider();
        _dbContext = _serviceProvider.GetRequiredService<ApplicationDbContext>();
    }

    public void Dispose()
    {
        _dbContext.Dispose();
        _serviceProvider.Dispose();
    }

    [Fact]
    public async Task RegisterParent_Succeeds_And_Creates_ParentProfile()
    {
        // Arrange
        var handler = _serviceProvider.GetRequiredService<RegisterParentHandler>();
        var request = new RegisterParentRequest("parent1@example.com", "Password123!", "Sarah Parent", "+1234567890");

        // Act
        var response = await handler.HandleAsync(request);

        // Assert
        Assert.Null(response.Token);
        Assert.True(response.RequiresEmailVerification);
        Assert.NotNull(response.User);
        Assert.Equal("parent1@example.com", response.User.Email);
        Assert.Equal("Sarah Parent", response.User.FullName);
        Assert.Equal("Parent", response.User.Role);
        Assert.NotEqual(Guid.Empty, response.User.ProfileId);

        var profile = _dbContext.ParentProfiles.FirstOrDefault(p => p.Id == response.User.ProfileId);
        Assert.NotNull(profile);
        Assert.Equal(response.User.Id, profile.UserId);
        Assert.Equal("+1234567890", profile.PhoneNumber);
    }

    [Fact]
    public async Task RegisterDoctor_Succeeds_And_Creates_DoctorProfile()
    {
        // Arrange
        var handler = _serviceProvider.GetRequiredService<RegisterDoctorHandler>();
        var request = new RegisterDoctorRequest("doctor1@example.com", "Password123!", "Dr. John Doe", "Pediatrics", "Mindora Clinic", "LIC-998877");

        // Act
        var response = await handler.HandleAsync(request);

        // Assert
        Assert.Null(response.Token);
        Assert.True(response.RequiresEmailVerification);
        Assert.NotNull(response.User);
        Assert.Equal("doctor1@example.com", response.User.Email);
        Assert.Equal("Dr. John Doe", response.User.FullName);
        Assert.Equal("Doctor", response.User.Role);
        Assert.NotEqual(Guid.Empty, response.User.ProfileId);

        var profile = _dbContext.DoctorProfiles.FirstOrDefault(d => d.Id == response.User.ProfileId);
        Assert.NotNull(profile);
        Assert.Equal(response.User.Id, profile.UserId);
        Assert.Equal("Pediatrics", profile.Specialization);
        Assert.Equal("Mindora Clinic", profile.ClinicName);
        Assert.Equal("LIC-998877", profile.LicenseNumber);
    }

    [Fact]
    public async Task DuplicateEmail_Is_Rejected_With_ConflictException()
    {
        // Arrange
        var handler = _serviceProvider.GetRequiredService<RegisterParentHandler>();
        var request1 = new RegisterParentRequest("dup@example.com", "Password123!", "First User", null);
        var request2 = new RegisterParentRequest("dup@example.com", "Password123!", "Second User", null);

        await handler.HandleAsync(request1);

        // Act & Assert
        await Assert.ThrowsAsync<ConflictException>(() => handler.HandleAsync(request2));
    }

    [Fact]
    public async Task Invalid_Password_Fails_Validation()
    {
        // Arrange
        var validator = _serviceProvider.GetRequiredService<IValidator<RegisterParentRequest>>();
        var request = new RegisterParentRequest("short@example.com", "short", "Short Pass User", null);

        // Act
        var result = await validator.ValidateAsync(request);

        // Assert
        Assert.False(result.IsValid);
        Assert.Contains(result.Errors, e => e.PropertyName == "Password");
    }

    [Fact]
    public async Task Login_Succeeds_With_Correct_Credentials()
    {
        // Arrange
        var parentHandler = _serviceProvider.GetRequiredService<RegisterParentHandler>();
        var registered = await parentHandler.HandleAsync(new RegisterParentRequest("loginuser@example.com", "Password123!", "Login User", null));

        // Confirm email before login
        var identityService = _serviceProvider.GetRequiredService<IIdentityService>();
        await identityService.ConfirmEmailAsync(registered.User!.Id);

        var loginHandler = _serviceProvider.GetRequiredService<LoginHandler>();
        var loginRequest = new LoginRequest("loginuser@example.com", "Password123!");

        // Act
        var response = await loginHandler.HandleAsync(loginRequest);

        // Assert
        Assert.NotNull(response.Token);
        Assert.Equal("loginuser@example.com", response.User!.Email);
        Assert.Equal("Parent", response.User.Role);
        Assert.NotEqual(Guid.Empty, response.User.ProfileId);
    }

    [Fact]
    public async Task Login_Fails_Safely_With_Invalid_Credentials()
    {
        // Arrange
        var parentHandler = _serviceProvider.GetRequiredService<RegisterParentHandler>();
        var registered = await parentHandler.HandleAsync(new RegisterParentRequest("loginuser2@example.com", "Password123!", "Login User", null));

        var identityService = _serviceProvider.GetRequiredService<IIdentityService>();
        await identityService.ConfirmEmailAsync(registered.User!.Id);

        var loginHandler = _serviceProvider.GetRequiredService<LoginHandler>();
        var badPasswordRequest = new LoginRequest("loginuser2@example.com", "WrongPassword!");
        var nonExistentRequest = new LoginRequest("nonexistent@example.com", "Password123!");

        // Act & Assert
        var ex1 = await Assert.ThrowsAsync<UnauthorizedException>(() => loginHandler.HandleAsync(badPasswordRequest));
        Assert.Equal("Invalid email or password.", ex1.Message);

        var ex2 = await Assert.ThrowsAsync<UnauthorizedException>(() => loginHandler.HandleAsync(nonExistentRequest));
        Assert.Equal("Invalid email or password.", ex2.Message);
    }

    [Fact]
    public async Task Jwt_Contains_Correct_Claims()
    {
        // Arrange
        var handler = _serviceProvider.GetRequiredService<RegisterParentHandler>();
        var registered = await handler.HandleAsync(new RegisterParentRequest("jwtuser@example.com", "Password123!", "JWT User", null));

        var identityService = _serviceProvider.GetRequiredService<IIdentityService>();
        await identityService.ConfirmEmailAsync(registered.User!.Id);

        var loginHandler = _serviceProvider.GetRequiredService<LoginHandler>();
        var loginResponse = await loginHandler.HandleAsync(new LoginRequest("jwtuser@example.com", "Password123!"));

        // Act
        var jwtHandler = new JwtSecurityTokenHandler();
        var jwtToken = jwtHandler.ReadJwtToken(loginResponse.Token);

        // Assert
        Assert.Equal(registered.User.Id.ToString(), jwtToken.Claims.First(c => c.Type == JwtRegisteredClaimNames.Sub).Value);
        Assert.Equal("jwtuser@example.com", jwtToken.Claims.First(c => c.Type == JwtRegisteredClaimNames.Email).Value);
        Assert.Equal("Parent", jwtToken.Claims.First(c => c.Type == "role").Value);
        Assert.Equal(registered.User.ProfileId.ToString(), jwtToken.Claims.First(c => c.Type == "profile_id").Value);
    }

    [Fact]
    public async Task CurrentUser_Endpoint_Returns_Authenticated_Profile()
    {
        // Arrange
        var handler = _serviceProvider.GetRequiredService<RegisterParentHandler>();
        var registered = await handler.HandleAsync(new RegisterParentRequest("me@example.com", "Password123!", "Me Parent", null));

        // Simulate HttpContext with claims
        var httpContextAccessor = _serviceProvider.GetRequiredService<IHttpContextAccessor>();
        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, registered.User.Id.ToString()),
            new(ClaimTypes.Email, "me@example.com"),
            new(ClaimTypes.Name, "Me Parent"),
            new(ClaimTypes.Role, "Parent"),
            new("profile_id", registered.User.ProfileId.ToString())
        };
        var identity = new ClaimsIdentity(claims, "TestAuth");
        httpContextAccessor.HttpContext = new DefaultHttpContext { User = new ClaimsPrincipal(identity) };

        var meHandler = _serviceProvider.GetRequiredService<GetCurrentUserHandler>();

        // Act
        var result = await meHandler.HandleAsync();

        // Assert
        Assert.Equal(registered.User.Id, result.UserId);
        Assert.Equal("me@example.com", result.Email);
        Assert.Equal("Me Parent", result.FullName);
        Assert.Equal("Parent", result.Role);
        Assert.Equal(registered.User.ProfileId, result.ProfileId);
    }

    [Fact]
    public async Task CurrentUser_Throws_Unauthorized_When_Unauthenticated()
    {
        // Arrange (No HttpContext User)
        var httpContextAccessor = _serviceProvider.GetRequiredService<IHttpContextAccessor>();
        httpContextAccessor.HttpContext = new DefaultHttpContext();

        var meHandler = _serviceProvider.GetRequiredService<GetCurrentUserHandler>();

        // Act & Assert
        await Assert.ThrowsAsync<UnauthorizedException>(() => meHandler.HandleAsync());
    }

    [Fact]
    public async Task Doctor_Registration_Does_Not_Create_ParentProfile()
    {
        // Arrange
        var handler = _serviceProvider.GetRequiredService<RegisterDoctorHandler>();
        var response = await handler.HandleAsync(new RegisterDoctorRequest(
            "doconly@example.com", "Password123!", "Dr. Doc", "Neuro", null, null));

        // Assert
        var doctorProfile = _dbContext.DoctorProfiles.FirstOrDefault(d => d.UserId == response.User.Id);
        var parentProfile = _dbContext.ParentProfiles.FirstOrDefault(p => p.UserId == response.User.Id);

        Assert.NotNull(doctorProfile);
        Assert.Null(parentProfile);
    }

    [Fact]
    public async Task Parent_Registration_Does_Not_Create_DoctorProfile()
    {
        // Arrange
        var handler = _serviceProvider.GetRequiredService<RegisterParentHandler>();
        var response = await handler.HandleAsync(new RegisterParentRequest(
            "parentonly@example.com", "Password123!", "Parent Only", null));

        // Assert
        var parentProfile = _dbContext.ParentProfiles.FirstOrDefault(p => p.UserId == response.User.Id);
        var doctorProfile = _dbContext.DoctorProfiles.FirstOrDefault(d => d.UserId == response.User.Id);

        Assert.NotNull(parentProfile);
        Assert.Null(doctorProfile);
    }

    [Fact]
    public async Task RegisterDoctor_With_Gender_Succeeds_And_Persists_Gender()
    {
        // Arrange
        var handler = _serviceProvider.GetRequiredService<RegisterDoctorHandler>();
        var request = new RegisterDoctorRequest(
            "drsara_test@example.com",
            "StrongPass123!",
            "Dr. Sara Test",
            "Occupational Therapy",
            "Al-Amal Clinic",
            "LIC-12345",
            Gender: "Female");

        // Act
        var response = await handler.HandleAsync(request);

        // Assert
        Assert.NotNull(response);
        var profile = _dbContext.DoctorProfiles.FirstOrDefault(d => d.Id == response.User.ProfileId);
        Assert.NotNull(profile);
        Assert.Equal(Mindora.Domain.Enums.DoctorGender.Female, profile.Gender);
    }

    [Fact]
    public async Task RegisterDoctor_With_Invalid_Gender_Fails_Validation()
    {
        // Arrange
        var handler = _serviceProvider.GetRequiredService<RegisterDoctorHandler>();
        var request = new RegisterDoctorRequest(
            "drinvalid@example.com",
            "StrongPass123!",
            "Dr. Invalid",
            "Therapy",
            null,
            null,
            Gender: "NotAGender");

        // Act & Assert
        await Assert.ThrowsAsync<Mindora.Application.Common.Exceptions.ValidationException>(() =>
            handler.HandleAsync(request));
    }

    [Fact]
    public async Task Registration_ParentEmail_During_DoctorRegistration_RejectedAsSawaAppAccount()
    {
        // 1. Parent email during Doctor registration -> rejected as SAWA App account
        var parentHandler = _serviceProvider.GetRequiredService<RegisterParentHandler>();
        await parentHandler.HandleAsync(new RegisterParentRequest("sawa.parent@mindora.com", "Password123!", "Sawa Parent", null));

        var doctorHandler = _serviceProvider.GetRequiredService<RegisterDoctorHandler>();
        var ex = await Assert.ThrowsAsync<ConflictException>(() =>
            doctorHandler.HandleAsync(new RegisterDoctorRequest("sawa.parent@mindora.com", "Password123!", "Dr. Attempt", "Pediatrics", null, null)));

        Assert.Equal("هذا البريد الإلكتروني مسجل بالفعل على SAWA APP.", ex.Message);
    }

    [Fact]
    public async Task Registration_DoctorEmail_During_DoctorRegistration_RejectedAsDoctorDashboardAccount()
    {
        // 2. Doctor email during Doctor registration -> rejected as Doctor Dashboard account
        var doctorHandler = _serviceProvider.GetRequiredService<RegisterDoctorHandler>();
        await doctorHandler.HandleAsync(new RegisterDoctorRequest("clinic.doctor@mindora.com", "Password123!", "Dr. Initial", "Pediatrics", null, null));

        var ex = await Assert.ThrowsAsync<ConflictException>(() =>
            doctorHandler.HandleAsync(new RegisterDoctorRequest("clinic.doctor@mindora.com", "Password123!", "Dr. Second", "Neurology", null, null)));

        Assert.Equal("هذا البريد الإلكتروني مسجل بالفعل على لوحة تحكم الطبيب.", ex.Message);
    }

    [Fact]
    public async Task Registration_DoctorEmail_During_ParentRegistration_RejectedAsDoctorDashboardAccount()
    {
        // 3. Doctor email during Parent registration -> rejected as Doctor Dashboard account
        var doctorHandler = _serviceProvider.GetRequiredService<RegisterDoctorHandler>();
        await doctorHandler.HandleAsync(new RegisterDoctorRequest("clinic.doc@mindora.com", "Password123!", "Dr. Initial", "Pediatrics", null, null));

        var parentHandler = _serviceProvider.GetRequiredService<RegisterParentHandler>();
        var ex = await Assert.ThrowsAsync<ConflictException>(() =>
            parentHandler.HandleAsync(new RegisterParentRequest("clinic.doc@mindora.com", "Password123!", "Parent Attempt", null)));

        Assert.Equal("هذا البريد الإلكتروني مسجل بالفعل على لوحة تحكم الطبيب.", ex.Message);
    }

    [Fact]
    public async Task Registration_ParentEmail_During_ParentRegistration_RejectedAsSawaAppAccount()
    {
        // 4. Parent email during Parent registration -> rejected as SAWA App account
        var parentHandler = _serviceProvider.GetRequiredService<RegisterParentHandler>();
        await parentHandler.HandleAsync(new RegisterParentRequest("sawa.mom@mindora.com", "Password123!", "Mom First", null));

        var ex = await Assert.ThrowsAsync<ConflictException>(() =>
            parentHandler.HandleAsync(new RegisterParentRequest("sawa.mom@mindora.com", "Password123!", "Mom Second", null)));

        Assert.Equal("هذا البريد الإلكتروني مسجل بالفعل على SAWA APP.", ex.Message);
    }

    [Fact]
    public async Task Registration_NewEmail_RegistrationSucceeds()
    {
        // 5. New email -> registration succeeds
        var parentHandler = _serviceProvider.GetRequiredService<RegisterParentHandler>();
        var parentResponse = await parentHandler.HandleAsync(new RegisterParentRequest("fresh.parent@mindora.com", "Password123!", "Fresh Parent", null));
        Assert.True(parentResponse.RequiresEmailVerification);
        Assert.NotNull(parentResponse.User);

        var doctorHandler = _serviceProvider.GetRequiredService<RegisterDoctorHandler>();
        var doctorResponse = await doctorHandler.HandleAsync(new RegisterDoctorRequest("fresh.doctor@mindora.com", "Password123!", "Dr. Fresh", "Pediatrics", null, null));
        Assert.True(doctorResponse.RequiresEmailVerification);
        Assert.NotNull(doctorResponse.User);
    }
}
