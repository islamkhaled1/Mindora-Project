using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using Mindora.Application;
using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Features.Activities.GetChildActivityPerformance;
using Mindora.Application.Features.Auth.RegisterDoctor;
using Mindora.Application.Features.Auth.RegisterParent;
using Mindora.Application.Features.Children.CreateChild;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;
using Mindora.Infrastructure.Identity;
using Mindora.Infrastructure.Persistence;
using Mindora.Infrastructure.Services;
using Xunit;

namespace Mindora.UnitTests.Features.Activities;

public class ActivityPerformanceTests : IDisposable
{
    private readonly ServiceProvider _serviceProvider;
    private readonly ApplicationDbContext _dbContext;
    private readonly IHttpContextAccessor _httpContextAccessor;

    public ActivityPerformanceTests()
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

    private async Task<Child> CreateChildAsync(Guid parentUserId, Guid parentProfileId, string childName = "Lily")
    {
        SetCurrentUser(parentUserId, "parent@test.com", "Parent Test", UserRole.Parent, parentProfileId);
        var handler = _serviceProvider.GetRequiredService<CreateChildHandler>();
        var res = await handler.HandleAsync(new CreateChildRequest(childName, new DateOnly(2019, 3, 20), null, DifficultyLevel.Beginner, DifficultyLevel.Beginner, DifficultyLevel.Beginner));
        return await _dbContext.Children.FirstAsync(c => c.Id == res.Id);
    }

    private Activity CreateActivity(string title, ActivityDomain domain = ActivityDomain.Movement)
    {
        var activity = Activity.Create(title, "Description", domain, DifficultyLevel.Beginner, "{}");
        _dbContext.Activities.Add(activity);
        _dbContext.SaveChanges();
        return activity;
    }

    [Fact]
    public async Task Owning_Parent_And_Assigned_Doctor_Can_Access_Performance()
    {
        // Arrange
        var (parentUser, parentProfile) = await CreateParentAsync("parent_perf@test.com", "Parent Perf");
        var child = await CreateChildAsync(parentUser, parentProfile);

        var (docUser, docProfile) = await CreateDoctorAsync("doc_perf@test.com", "Dr. Perf");
        _dbContext.DoctorChildAssignments.Add(DoctorChildAssignment.Create(docProfile, child.Id));
        await _dbContext.SaveChangesAsync();

        var activity = CreateActivity("Hand Tapping");

        var session = Session.Start(child.Id, activity.Id, activity.Domain);
        session.AddMetric("AccuracyPercentage", 95.0m);
        session.AddMetric("RepetitionCount", 20.0m);
        session.Complete(DateTime.UtcNow, 120);

        var analysis = SessionAnalysisResult.Create(session.Id, 95.0m, 95.0m, "Great", false, DifficultyAdjustment.Maintain, "{}", DateTime.UtcNow, false);
        session.AttachAnalysisResult(analysis);
        _dbContext.Sessions.Add(session);
        _dbContext.SessionAnalysisResults.Add(analysis);
        await _dbContext.SaveChangesAsync();

        var handler = _serviceProvider.GetRequiredService<GetChildActivityPerformanceHandler>();

        // Act 1: Parent queries
        SetCurrentUser(parentUser, "parent_perf@test.com", "Parent Perf", UserRole.Parent, parentProfile);
        var parentResult = await handler.HandleAsync(child.Id);

        // Act 2: Doctor queries
        SetCurrentUser(docUser, "doc_perf@test.com", "Dr. Perf", UserRole.Doctor, docProfile);
        var doctorResult = await handler.HandleAsync(child.Id);

        // Assert
        Assert.Single(parentResult);
        Assert.Single(doctorResult);
        Assert.Equal(parentResult[0].ActivityId, doctorResult[0].ActivityId);
        Assert.Equal(1, parentResult[0].TimesPlayed);
        Assert.Equal(2, parentResult[0].TotalPracticeMinutes); // 120s = 2 min
        Assert.Equal(95.0m, parentResult[0].AverageScore);
        Assert.Equal(95.0m, parentResult[0].AverageAccuracyPercentage);
        Assert.Equal(20.0m, parentResult[0].AverageRepetitions);
    }

    [Fact]
    public async Task Unassigned_Doctor_And_Unrelated_Parent_Are_Denied_Access()
    {
        // Arrange
        var (parent1User, parent1Profile) = await CreateParentAsync("p1@test.com", "P1");
        var (parent2User, parent2Profile) = await CreateParentAsync("p2@test.com", "P2");
        var child = await CreateChildAsync(parent1User, parent1Profile);

        var (docUser, docProfile) = await CreateDoctorAsync("doc_unassigned@test.com", "Dr. Unassigned");

        var handler = _serviceProvider.GetRequiredService<GetChildActivityPerformanceHandler>();

        // Unrelated Parent
        SetCurrentUser(parent2User, "p2@test.com", "P2", UserRole.Parent, parent2Profile);
        await Assert.ThrowsAsync<NotFoundException>(() => handler.HandleAsync(child.Id));

        // Unassigned Doctor
        SetCurrentUser(docUser, "doc_unassigned@test.com", "Dr. Unassigned", UserRole.Doctor, docProfile);
        await Assert.ThrowsAsync<NotFoundException>(() => handler.HandleAsync(child.Id));
    }

    [Fact]
    public async Task Aggregation_Computes_Accurate_Averages_Across_Multiple_Sessions_Without_Duplication()
    {
        // Arrange
        var (parentUser, parentProfile) = await CreateParentAsync("parent_agg@test.com", "Parent Agg");
        var child = await CreateChildAsync(parentUser, parentProfile);

        var activity = CreateActivity("Jump Squats");

        // Session 1: 180s, score 80, Accuracy 80%, Reps 10, ReactionTime 400ms
        var s1 = Session.Start(child.Id, activity.Id, activity.Domain, DateTime.UtcNow.AddDays(-2));
        s1.AddMetric("AccuracyPercentage", 80.0m);
        s1.AddMetric("RepetitionCount", 10.0m);
        s1.AddMetric("ReactionTimeMs", 400.0m);
        s1.Complete(DateTime.UtcNow.AddDays(-2).AddMinutes(3), 180);
        var a1 = SessionAnalysisResult.Create(s1.Id, 80.0m, 80.0m, "Good", false, DifficultyAdjustment.Maintain, "{}", DateTime.UtcNow, false);
        s1.AttachAnalysisResult(a1);

        // Session 2: 240s, score 90, Accuracy 90%, Reps 20, ReactionTime 300ms
        var s2 = Session.Start(child.Id, activity.Id, activity.Domain, DateTime.UtcNow.AddDays(-1));
        s2.AddMetric("AccuracyPercentage", 90.0m);
        s2.AddMetric("RepetitionCount", 20.0m);
        s2.AddMetric("ReactionTimeMs", 300.0m);
        s2.Complete(DateTime.UtcNow.AddDays(-1).AddMinutes(4), 240);
        var a2 = SessionAnalysisResult.Create(s2.Id, 90.0m, 90.0m, "Great", false, DifficultyAdjustment.Maintain, "{}", DateTime.UtcNow, false);
        s2.AttachAnalysisResult(a2);

        // Session 3: Abandoned (should be excluded!)
        var s3 = Session.Start(child.Id, activity.Id, activity.Domain, DateTime.UtcNow);
        s3.Abandon(DateTime.UtcNow.AddMinutes(1));

        _dbContext.Sessions.AddRange(s1, s2, s3);
        _dbContext.SessionAnalysisResults.AddRange(a1, a2);
        await _dbContext.SaveChangesAsync();

        SetCurrentUser(parentUser, "parent_agg@test.com", "Parent Agg", UserRole.Parent, parentProfile);
        var handler = _serviceProvider.GetRequiredService<GetChildActivityPerformanceHandler>();

        // Act
        var result = await handler.HandleAsync(child.Id);

        // Assert
        Assert.Single(result);
        var item = result[0];
        Assert.Equal(2, item.TimesPlayed);
        Assert.Equal(7, item.TotalPracticeMinutes); // (180 + 240) = 420s = 7 min
        Assert.Equal(85.0m, item.AverageScore); // (80 + 90) / 2
        Assert.Equal(85.0m, item.AverageAccuracyPercentage); // (80 + 90) / 2
        Assert.Equal(15.0m, item.AverageRepetitions); // (10 + 20) / 2
        Assert.Equal(350.0m, item.AverageReactionTimeMs); // (400 + 300) / 2
    }
}
