using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using Mindora.Application;
using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Features.Auth.RegisterDoctor;
using Mindora.Application.Features.Auth.RegisterParent;
using Mindora.Application.Features.Children.CreateChild;
using Mindora.Application.Features.Progress.GetChildProgressHistory;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;
using Mindora.Infrastructure.Identity;
using Mindora.Infrastructure.Persistence;
using Mindora.Infrastructure.Services;
using Xunit;

namespace Mindora.UnitTests.Features.Progress;

public class ProgressPaginationTests : IDisposable
{
    private readonly ServiceProvider _serviceProvider;
    private readonly ApplicationDbContext _dbContext;
    private readonly IHttpContextAccessor _httpContextAccessor;

    public ProgressPaginationTests()
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

    private async Task<(Guid UserId, Guid ProfileId)> CreateDoctorAsync(string email, string name)
    {
        var handler = _serviceProvider.GetRequiredService<RegisterDoctorHandler>();
        var res = await handler.HandleAsync(new RegisterDoctorRequest(email, "Password123!", name, "Pediatrics", "Mindora Clinic", "LIC-123"));
        return (res.User.Id, res.User.ProfileId);
    }

    private async Task<Child> CreateChildAsync(Guid parentUserId, Guid parentProfileId, string childName = "Clara")
    {
        SetCurrentUser(parentUserId, "parent@test.com", "Parent Test", UserRole.Parent, parentProfileId);
        var handler = _serviceProvider.GetRequiredService<CreateChildHandler>();
        var res = await handler.HandleAsync(new CreateChildRequest(childName, new DateOnly(2018, 7, 10), null, DifficultyLevel.Beginner, DifficultyLevel.Beginner, DifficultyLevel.Beginner));
        return await _dbContext.Children.FirstAsync(c => c.Id == res.Id);
    }

    private Activity CreateActivity(string title, ActivityDomain domain = ActivityDomain.Movement)
    {
        var activity = Activity.Create(title, "Description", domain, DifficultyLevel.Beginner, "{}");
        _dbContext.Activities.Add(activity);
        _dbContext.SaveChanges();
        return activity;
    }

    private Session AddSessionWithAnalysis(Child child, Activity activity, DateTime date, double score)
    {
        var session = Session.Start(child.Id, activity.Id, activity.Domain, date);
        session.Complete(date.AddMinutes(5), 300);

        var analysis = SessionAnalysisResult.Create(
            session.Id,
            (decimal)score,
            (decimal)score,
            "Good",
            false,
            DifficultyAdjustment.Maintain,
            "{}",
            date.AddMinutes(5),
            false);

        session.AttachAnalysisResult(analysis);
        _dbContext.Sessions.Add(session);
        _dbContext.SessionAnalysisResults.Add(analysis);
        _dbContext.SaveChanges();
        return session;
    }

    [Fact]
    public async Task GetChildProgressHistory_WithDefaultPagination_ReturnsFirst20Items()
    {
        // Arrange
        var (parentUser, parentProfile) = await CreateParentAsync("parent_page@test.com", "Parent Page");
        var child = await CreateChildAsync(parentUser, parentProfile);
        var activity = CreateActivity("Activity 1");

        // Seed 25 completed sessions
        for (int i = 0; i < 25; i++)
        {
            AddSessionWithAnalysis(child, activity, DateTime.UtcNow.AddDays(-25 + i), 70.0 + i);
        }

        SetCurrentUser(parentUser, "parent_page@test.com", "Parent Page", UserRole.Parent, parentProfile);
        var handler = _serviceProvider.GetRequiredService<GetChildProgressHistoryHandler>();

        // Act
        var result = await handler.HandleAsync(child.Id, new GetChildProgressHistoryRequest());

        // Assert
        Assert.Equal(20, result.Count);
    }

    [Fact]
    public async Task GetChildProgressHistory_WithExplicitPageAndPageSize_ReturnsExpectedSubset()
    {
        // Arrange
        var (parentUser, parentProfile) = await CreateParentAsync("parent_page2@test.com", "Parent Page 2");
        var child = await CreateChildAsync(parentUser, parentProfile);
        var activity = CreateActivity("Activity 2");

        for (int i = 0; i < 15; i++)
        {
            AddSessionWithAnalysis(child, activity, DateTime.UtcNow.AddDays(-15 + i), 60.0 + i);
        }

        SetCurrentUser(parentUser, "parent_page2@test.com", "Parent Page 2", UserRole.Parent, parentProfile);
        var handler = _serviceProvider.GetRequiredService<GetChildProgressHistoryHandler>();

        // Act: Page 2, PageSize 5 (should return items 6-10)
        var result = await handler.HandleAsync(child.Id, new GetChildProgressHistoryRequest { Page = 2, PageSize = 5 });

        // Assert
        Assert.Equal(5, result.Count);
    }

    [Fact]
    public async Task GetChildProgressHistory_WithDomainFilter_FiltersAccurately()
    {
        // Arrange
        var (parentUser, parentProfile) = await CreateParentAsync("parent_dom@test.com", "Parent Dom");
        var child = await CreateChildAsync(parentUser, parentProfile);

        var moveActivity = CreateActivity("Movement Act", ActivityDomain.Movement);
        var speechActivity = CreateActivity("Speech Act", ActivityDomain.Speech);

        AddSessionWithAnalysis(child, moveActivity, DateTime.UtcNow.AddDays(-2), 80.0);
        AddSessionWithAnalysis(child, speechActivity, DateTime.UtcNow.AddDays(-1), 75.0);

        SetCurrentUser(parentUser, "parent_dom@test.com", "Parent Dom", UserRole.Parent, parentProfile);
        var handler = _serviceProvider.GetRequiredService<GetChildProgressHistoryHandler>();

        // Act: Filter by Movement
        var result = await handler.HandleAsync(child.Id, new GetChildProgressHistoryRequest { Domain = ActivityDomain.Movement.ToString() });

        // Assert
        Assert.Single(result);
        Assert.Equal(ActivityDomain.Movement.ToString(), result[0].Domain);
    }

    [Fact]
    public async Task GetChildProgressHistory_WithDateRangeFilter_ReturnsSessionsWithinRange()
    {
        // Arrange
        var (parentUser, parentProfile) = await CreateParentAsync("parent_date@test.com", "Parent Date");
        var child = await CreateChildAsync(parentUser, parentProfile);
        var activity = CreateActivity("Date Act");

        var now = DateTime.UtcNow;
        AddSessionWithAnalysis(child, activity, now.AddDays(-10), 70.0);
        AddSessionWithAnalysis(child, activity, now.AddDays(-5), 80.0);
        AddSessionWithAnalysis(child, activity, now.AddDays(-1), 90.0);

        SetCurrentUser(parentUser, "parent_date@test.com", "Parent Date", UserRole.Parent, parentProfile);
        var handler = _serviceProvider.GetRequiredService<GetChildProgressHistoryHandler>();

        // Act: between -7 days and -3 days (should only include the session from -5 days)
        var request = new GetChildProgressHistoryRequest
        {
            FromDate = now.AddDays(-7),
            ToDate = now.AddDays(-3)
        };
        var result = await handler.HandleAsync(child.Id, request);

        // Assert
        Assert.Single(result);
        Assert.Equal(80.0m, result[0].Score);
    }
}
