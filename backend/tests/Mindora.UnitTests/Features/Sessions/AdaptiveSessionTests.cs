using System.Security.Claims;
using FluentValidation;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using Mindora.Application;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Features.Auth.RegisterParent;
using Mindora.Application.Features.Children.CreateChild;
using Mindora.Application.Features.Sessions.StartSession;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;
using Mindora.Infrastructure.Identity;
using Mindora.Infrastructure.Persistence;
using Mindora.Infrastructure.Services;
using Xunit;

namespace Mindora.UnitTests.Features.Sessions;

public class AdaptiveSessionTests : IDisposable
{
    private readonly ServiceProvider _serviceProvider;
    private readonly ApplicationDbContext _dbContext;
    private readonly IHttpContextAccessor _httpContextAccessor;

    public AdaptiveSessionTests()
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
        services.AddSingleton<ILinkingRateLimiter, LinkingRateLimiter>();

        services.AddApplicationServices();

        _serviceProvider = services.BuildServiceProvider();
        _dbContext = _serviceProvider.GetRequiredService<ApplicationDbContext>();
        _httpContextAccessor = _serviceProvider.GetRequiredService<IHttpContextAccessor>();
    }

    public void Dispose()
    {
        _dbContext.Dispose();
        _serviceProvider.Dispose();
    }

    private void SetCurrentUser(Guid userId, string email, string fullName, UserRole role, Guid profileId)
    {
        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, userId.ToString()),
            new(ClaimTypes.Email, email),
            new(ClaimTypes.Name, fullName),
            new(ClaimTypes.Role, role.ToString()),
            new("profile_id", profileId.ToString())
        };
        var identity = new ClaimsIdentity(claims, "TestAuth");
        _httpContextAccessor.HttpContext = new DefaultHttpContext { User = new ClaimsPrincipal(identity) };
    }

    private async Task<(Guid UserId, Guid ProfileId)> CreateParentAsync(string email, string name)
    {
        var handler = _serviceProvider.GetRequiredService<RegisterParentHandler>();
        var res = await handler.HandleAsync(new RegisterParentRequest(email, "Password123!", name, null));
        return (res.User.Id, res.User.ProfileId);
    }

    private async Task<Child> CreateChildAsync(Guid parentUserId, Guid parentProfileId, DifficultyLevel level)
    {
        SetCurrentUser(parentUserId, "parent@test.com", "Parent Test", UserRole.Parent, parentProfileId);
        var handler = _serviceProvider.GetRequiredService<CreateChildHandler>();
        var res = await handler.HandleAsync(new CreateChildRequest("Adaptive Kid", new DateOnly(2018, 5, 12), null, level, DifficultyLevel.Beginner, DifficultyLevel.Beginner));
        return await _dbContext.Children.FirstAsync(c => c.Id == res.Id);
    }

    private Activity CreateActivity(string title, ActivityDomain domain = ActivityDomain.Movement)
    {
        var activity = Activity.Create(title, "Description", domain, DifficultyLevel.Beginner, "{\"pacing\":1.0}");
        _dbContext.Activities.Add(activity);
        _dbContext.SaveChanges();
        return activity;
    }

    [Fact]
    public async Task Next_Session_Uses_Recommendation_Increase_Without_Mutating_Baseline_Level()
    {
        // Arrange
        var (parentUser, parentProfile) = await CreateParentAsync("parent_adapt@test.com", "Parent Adapt");
        var child = await CreateChildAsync(parentUser, parentProfile, DifficultyLevel.Beginner);
        var activity = CreateActivity("Hand Eye Coordination");

        // Previous completed session with Increase recommendation
        var prevSession = Session.Start(child.Id, activity.Id, activity.Domain, DateTime.UtcNow.AddHours(-2));
        prevSession.Complete(DateTime.UtcNow.AddHours(-1), 180);

        var analysis = SessionAnalysisResult.Create(
            prevSession.Id,
            90.0m,
            90.0m,
            "Child performed exceptionally well.",
            false,
            DifficultyAdjustment.Increase,
            "{\"pacing\":1.25,\"repsTarget\":15}",
            DateTime.UtcNow.AddHours(-1),
            false);

        prevSession.AttachAnalysisResult(analysis);
        _dbContext.Sessions.Add(prevSession);
        _dbContext.SessionAnalysisResults.Add(analysis);
        await _dbContext.SaveChangesAsync();

        SetCurrentUser(parentUser, "parent_adapt@test.com", "Parent Adapt", UserRole.Parent, parentProfile);
        var startHandler = _serviceProvider.GetRequiredService<StartSessionHandler>();

        // Act
        var nextSessionDto = await startHandler.HandleAsync(new StartSessionRequest(child.Id, activity.Id));

        // Assert
        Assert.NotNull(nextSessionDto);
        // Effective target difficulty elevated to Intermediate
        Assert.Equal(DifficultyLevel.Intermediate.ToString(), nextSessionDto.TargetDifficulty);
        Assert.Equal("{\"pacing\":1.25,\"repsTarget\":15}", nextSessionDto.AdaptiveSettingsJson);

        // CRITICAL INVARIANT: Baseline level in Child entity was NOT modified
        var reloadedChild = await _dbContext.Children.FindAsync(child.Id);
        Assert.NotNull(reloadedChild);
        Assert.Equal(DifficultyLevel.Beginner, reloadedChild.CurrentMovementLevel);
    }

    [Fact]
    public async Task Next_Session_Uses_Recommendation_Decrease_Without_Mutating_Baseline_Level()
    {
        // Arrange
        var (parentUser, parentProfile) = await CreateParentAsync("parent_dec@test.com", "Parent Dec");
        var child = await CreateChildAsync(parentUser, parentProfile, DifficultyLevel.Intermediate);
        var activity = CreateActivity("Jump Rhythm");

        // Previous completed session with Decrease recommendation
        var prevSession = Session.Start(child.Id, activity.Id, activity.Domain, DateTime.UtcNow.AddHours(-3));
        prevSession.Complete(DateTime.UtcNow.AddHours(-2), 120);

        var analysis = SessionAnalysisResult.Create(
            prevSession.Id,
            45.0m,
            45.0m,
            "Child needed assistance.",
            true,
            DifficultyAdjustment.Decrease,
            "{\"pacing\":0.8}",
            DateTime.UtcNow.AddHours(-2),
            false);

        prevSession.AttachAnalysisResult(analysis);
        _dbContext.Sessions.Add(prevSession);
        _dbContext.SessionAnalysisResults.Add(analysis);
        await _dbContext.SaveChangesAsync();

        SetCurrentUser(parentUser, "parent_dec@test.com", "Parent Dec", UserRole.Parent, parentProfile);
        var startHandler = _serviceProvider.GetRequiredService<StartSessionHandler>();

        // Act
        var nextSessionDto = await startHandler.HandleAsync(new StartSessionRequest(child.Id, activity.Id));

        // Assert
        Assert.NotNull(nextSessionDto);
        // Effective target difficulty demoted from Intermediate to Beginner
        Assert.Equal(DifficultyLevel.Beginner.ToString(), nextSessionDto.TargetDifficulty);
        Assert.Equal("{\"pacing\":0.8}", nextSessionDto.AdaptiveSettingsJson);

        // Baseline level preserved
        var reloadedChild = await _dbContext.Children.FindAsync(child.Id);
        Assert.NotNull(reloadedChild);
        Assert.Equal(DifficultyLevel.Intermediate, reloadedChild.CurrentMovementLevel);
    }

    [Fact]
    public async Task Initial_Session_Without_Previous_History_Uses_Child_Baseline_Level()
    {
        // Arrange
        var (parentUser, parentProfile) = await CreateParentAsync("parent_init@test.com", "Parent Init");
        var child = await CreateChildAsync(parentUser, parentProfile, DifficultyLevel.Intermediate);
        var activity = CreateActivity("Initial Move");

        SetCurrentUser(parentUser, "parent_init@test.com", "Parent Init", UserRole.Parent, parentProfile);
        var startHandler = _serviceProvider.GetRequiredService<StartSessionHandler>();

        // Act
        var sessionDto = await startHandler.HandleAsync(new StartSessionRequest(child.Id, activity.Id));

        // Assert
        Assert.Equal(DifficultyLevel.Intermediate.ToString(), sessionDto.TargetDifficulty);
        Assert.Equal("{\"pacing\":1.0}", sessionDto.AdaptiveSettingsJson);
    }
}
