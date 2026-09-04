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
using Mindora.Application.Features.Activities.GetActivities;
using Mindora.Application.Features.Activities.GetActivityById;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;
using Mindora.Infrastructure.Identity;
using Mindora.Infrastructure.Persistence;
using Mindora.Infrastructure.Services;
using Xunit;

namespace Mindora.UnitTests.Features.Activities;

public class ActivitiesFeatureTests : IDisposable
{
    private readonly ServiceProvider _serviceProvider;
    private readonly ApplicationDbContext _dbContext;
    private readonly IHttpContextAccessor _httpContextAccessor;

    public ActivitiesFeatureTests()
    {
        var services = new ServiceCollection();
        services.AddLogging();

        var dbName = Guid.NewGuid().ToString();
        services.AddDbContext<ApplicationDbContext>(options =>
            options.UseInMemoryDatabase(dbName));

        services.AddScoped<IApplicationDbContext>(sp => sp.GetRequiredService<ApplicationDbContext>());

        services.AddIdentity<ApplicationUser, IdentityRole<Guid>>()
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
        _httpContextAccessor = _serviceProvider.GetRequiredService<IHttpContextAccessor>();

        SeedActivities();
    }

    public void Dispose()
    {
        _dbContext.Dispose();
        _serviceProvider.Dispose();
    }

    private void SetAuthenticatedUser(UserRole role = UserRole.Parent)
    {
        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, Guid.NewGuid().ToString()),
            new(ClaimTypes.Email, "user@test.com"),
            new(ClaimTypes.Role, role.ToString()),
            new("profile_id", Guid.NewGuid().ToString())
        };
        var identity = new ClaimsIdentity(claims, "TestAuth");
        _httpContextAccessor.HttpContext = new DefaultHttpContext { User = new ClaimsPrincipal(identity) };
    }

    private void SeedActivities()
    {
        // Active Movement Beginner
        _dbContext.Activities.Add(new Activity(
            Guid.Parse("11111111-1111-1111-1111-111111111111"),
            "Balance Beam Walk",
            "Walk across the beam maintaining balance.",
            ActivityDomain.Movement,
            DifficultyLevel.Beginner,
            null,
            isActive: true));

        // Active Movement Intermediate
        _dbContext.Activities.Add(new Activity(
            Guid.Parse("22222222-2222-2222-2222-222222222222"),
            "Obstacle Hop",
            "Hop over obstacles dynamically.",
            ActivityDomain.Movement,
            DifficultyLevel.Intermediate,
            null,
            isActive: true));

        // Active Speech Beginner
        _dbContext.Activities.Add(new Activity(
            Guid.Parse("33333333-3333-3333-3333-333333333333"),
            "Animal Sound Echo",
            "Repeat animal vocalizations.",
            ActivityDomain.Speech,
            DifficultyLevel.Beginner,
            null,
            isActive: true));

        // Inactive Attention Activity (Must NEVER be returned to clients)
        _dbContext.Activities.Add(new Activity(
            Guid.Parse("44444444-4444-4444-4444-444444444444"),
            "Secret Attention Test",
            "Unreleased testing activity.",
            ActivityDomain.Attention,
            DifficultyLevel.Advanced,
            null,
            isActive: false));

        _dbContext.SaveChanges();
    }

    [Fact]
    public async Task GetActivities_Returns_Active_Activities_Only()
    {
        // Arrange
        SetAuthenticatedUser();
        var handler = _serviceProvider.GetRequiredService<GetActivitiesHandler>();
        var request = new GetActivitiesRequest();

        // Act
        var result = await handler.HandleAsync(request);

        // Assert
        Assert.Equal(3, result.Count);
        Assert.DoesNotContain(result, a => a.Title == "Secret Attention Test");
        Assert.Contains(result, a => a.Title == "Balance Beam Walk");
        Assert.Contains(result, a => a.Title == "Obstacle Hop");
        Assert.Contains(result, a => a.Title == "Animal Sound Echo");
    }

    [Fact]
    public async Task GetActivities_Filters_By_Domain()
    {
        // Arrange
        SetAuthenticatedUser();
        var handler = _serviceProvider.GetRequiredService<GetActivitiesHandler>();
        var request = new GetActivitiesRequest(Domain: "Movement");

        // Act
        var result = await handler.HandleAsync(request);

        // Assert
        Assert.Equal(2, result.Count);
        Assert.All(result, a => Assert.Equal("Movement", a.Domain));
    }

    [Fact]
    public async Task GetActivities_Filters_By_Difficulty()
    {
        // Arrange
        SetAuthenticatedUser();
        var handler = _serviceProvider.GetRequiredService<GetActivitiesHandler>();
        var request = new GetActivitiesRequest(Difficulty: "Beginner");

        // Act
        var result = await handler.HandleAsync(request);

        // Assert
        Assert.Equal(2, result.Count);
        Assert.All(result, a => Assert.Equal("Beginner", a.BaseDifficulty));
    }

    [Fact]
    public async Task GetActivities_Filters_By_Domain_And_Difficulty_Combined()
    {
        // Arrange
        SetAuthenticatedUser();
        var handler = _serviceProvider.GetRequiredService<GetActivitiesHandler>();
        var request = new GetActivitiesRequest(Domain: "Movement", Difficulty: "Intermediate");

        // Act
        var result = await handler.HandleAsync(request);

        // Assert
        Assert.Single(result);
        Assert.Equal("Obstacle Hop", result[0].Title);
        Assert.Equal("Movement", result[0].Domain);
        Assert.Equal("Intermediate", result[0].BaseDifficulty);
    }

    [Fact]
    public async Task GetActivities_Throws_ValidationException_On_Invalid_Filters()
    {
        // Arrange
        SetAuthenticatedUser();
        var handler = _serviceProvider.GetRequiredService<GetActivitiesHandler>();
        var badDomainRequest = new GetActivitiesRequest(Domain: "InvalidDomainName");
        var badDifficultyRequest = new GetActivitiesRequest(Difficulty: "UltraSuperHard");

        // Act & Assert
        await Assert.ThrowsAsync<Mindora.Application.Common.Exceptions.ValidationException>(() =>
            handler.HandleAsync(badDomainRequest));

        await Assert.ThrowsAsync<Mindora.Application.Common.Exceptions.ValidationException>(() =>
            handler.HandleAsync(badDifficultyRequest));
    }

    [Fact]
    public async Task GetActivityById_Returns_Active_Activity()
    {
        // Arrange
        SetAuthenticatedUser();
        var handler = _serviceProvider.GetRequiredService<GetActivityByIdHandler>();
        var activityId = Guid.Parse("11111111-1111-1111-1111-111111111111");

        // Act
        var result = await handler.HandleAsync(activityId);

        // Assert
        Assert.NotNull(result);
        Assert.Equal(activityId, result.Id);
        Assert.Equal("Balance Beam Walk", result.Title);
    }

    [Fact]
    public async Task GetActivityById_Throws_NotFound_When_Inactive()
    {
        // Arrange
        SetAuthenticatedUser();
        var handler = _serviceProvider.GetRequiredService<GetActivityByIdHandler>();
        var inactiveId = Guid.Parse("44444444-4444-4444-4444-444444444444");

        // Act & Assert: Inactive activity must return NotFoundException
        await Assert.ThrowsAsync<NotFoundException>(() => handler.HandleAsync(inactiveId));
    }

    [Fact]
    public async Task GetActivityById_Throws_NotFound_When_Missing()
    {
        // Arrange
        SetAuthenticatedUser();
        var handler = _serviceProvider.GetRequiredService<GetActivityByIdHandler>();
        var missingId = Guid.NewGuid();

        // Act & Assert
        await Assert.ThrowsAsync<NotFoundException>(() => handler.HandleAsync(missingId));
    }

    [Fact]
    public async Task Unauthenticated_User_Cannot_Access_Activities()
    {
        // Arrange (No HttpContext User)
        _httpContextAccessor.HttpContext = new DefaultHttpContext();
        var getActivitiesHandler = _serviceProvider.GetRequiredService<GetActivitiesHandler>();
        var getByIdHandler = _serviceProvider.GetRequiredService<GetActivityByIdHandler>();

        // Act & Assert
        await Assert.ThrowsAsync<UnauthorizedException>(() => getActivitiesHandler.HandleAsync(new GetActivitiesRequest()));
        await Assert.ThrowsAsync<UnauthorizedException>(() => getByIdHandler.HandleAsync(Guid.NewGuid()));
    }
}
