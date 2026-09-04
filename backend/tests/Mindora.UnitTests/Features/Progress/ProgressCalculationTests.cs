using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using Mindora.Application;
using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Features.Auth.RegisterParent;
using Mindora.Application.Features.Children.CreateChild;
using Mindora.Application.Features.Progress.GetChildProgress;
using Mindora.Application.Features.Progress.GetChildProgressHistory;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;
using Mindora.Infrastructure.Identity;
using Mindora.Infrastructure.Persistence;
using Mindora.Infrastructure.Services;
using Xunit;

namespace Mindora.UnitTests.Features.Progress;

public class ProgressCalculationTests : IDisposable
{
    private readonly ServiceProvider _serviceProvider;
    private readonly ApplicationDbContext _dbContext;
    private readonly IHttpContextAccessor _httpContextAccessor;

    public ProgressCalculationTests()
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

    private async Task<Guid> CreateChildAsync(Guid parentId, Guid profileId, string name)
    {
        SetCurrentUser(parentId, "parent@test.com", "Parent Test", UserRole.Parent, profileId);
        var handler = _serviceProvider.GetRequiredService<CreateChildHandler>();
        var res = await handler.HandleAsync(new CreateChildRequest(
            name, new DateOnly(2018, 1, 1), null, DifficultyLevel.Beginner, DifficultyLevel.Beginner, DifficultyLevel.Beginner));
        return res.Id;
    }

    [Fact]
    public async Task Progress_Query_Prevents_Row_Multiplication_When_Session_Has_Many_Metrics()
    {
        // Arrange
        var (parentId, profileId) = await CreateParentAsync("parent_nomulti@test.com", "Parent NoMulti");
        var childId = await CreateChildAsync(parentId, profileId, "NoMulti Child");

        var activityId = Guid.NewGuid();
        _dbContext.Activities.Add(Activity.Create("Test Activity", "Desc", ActivityDomain.Movement, DifficultyLevel.Beginner));

        // Create ONE session
        var session = Session.Start(childId, activityId, ActivityDomain.Movement, DateTime.UtcNow);

        // Add 15 performance metrics to this single session
        for (int i = 0; i < 15; i++)
        {
            var metric = session.AddMetric("AccuracyPercentage", 80.00m);
            _dbContext.PerformanceMetrics.Add(metric);
        }

        // Complete session
        session.Complete(DateTime.UtcNow, 120);
        var analysis = SessionAnalysisResult.Create(
            session.Id, 80.00m, 80.00m, "Good performance.", false, DifficultyAdjustment.Maintain);
        session.AttachAnalysisResult(analysis);

        _dbContext.Sessions.Add(session);
        _dbContext.SessionAnalysisResults.Add(analysis);
        await _dbContext.SaveChangesAsync();

        SetCurrentUser(parentId, "parent_nomulti@test.com", "Parent NoMulti", UserRole.Parent, profileId);
        var handler = _serviceProvider.GetRequiredService<GetChildProgressHandler>();

        // Act
        var progress = await handler.HandleAsync(childId);

        // Assert:
        // Despite 15 metric rows, TotalCompletedSessions MUST BE 1, practice minutes must be 2 (120 sec), average score 80.00
        Assert.Equal(1, progress.TotalCompletedSessions);
        Assert.Equal(2, progress.TotalPracticeMinutes);
        Assert.Equal(80.00m, progress.OverallAverageScore);
    }

    [Fact]
    public async Task Progress_Counts_Only_Completed_Sessions()
    {
        // Arrange
        var (parentId, profileId) = await CreateParentAsync("parent_status@test.com", "Parent Status");
        var childId = await CreateChildAsync(parentId, profileId, "Status Child");

        var act = Activity.Create("Movement Act", "Desc", ActivityDomain.Movement, DifficultyLevel.Beginner);
        _dbContext.Activities.Add(act);

        // 1 Completed session
        var completed = Session.Start(childId, act.Id, ActivityDomain.Movement, DateTime.UtcNow.AddHours(-2));
        completed.Complete(DateTime.UtcNow.AddHours(-1), 180);
        var analysis = SessionAnalysisResult.Create(completed.Id, 90.00m, 90.00m, "Great effort.", false, DifficultyAdjustment.Increase);
        completed.AttachAnalysisResult(analysis);
        _dbContext.Sessions.Add(completed);
        _dbContext.SessionAnalysisResults.Add(analysis);

        // 1 Started session
        var started = Session.Start(childId, act.Id, ActivityDomain.Movement, DateTime.UtcNow);
        _dbContext.Sessions.Add(started);

        // 1 Abandoned session
        var abandoned = Session.Start(childId, act.Id, ActivityDomain.Movement, DateTime.UtcNow.AddHours(-4));
        abandoned.Abandon(DateTime.UtcNow.AddHours(-3));
        _dbContext.Sessions.Add(abandoned);

        await _dbContext.SaveChangesAsync();

        SetCurrentUser(parentId, "parent_status@test.com", "Parent Status", UserRole.Parent, profileId);
        var handler = _serviceProvider.GetRequiredService<GetChildProgressHandler>();

        // Act
        var progress = await handler.HandleAsync(childId);

        // Assert: Only the 1 Completed session is counted
        Assert.Equal(1, progress.TotalCompletedSessions);
        Assert.Equal(3, progress.TotalPracticeMinutes); // 180 sec / 60
        Assert.Equal(90.00m, progress.OverallAverageScore);
    }

    [Fact]
    public async Task CurrentStreak_Correctly_Counts_Consecutive_UTC_Days_And_Consolidates_Same_Day()
    {
        // Arrange
        var (parentId, profileId) = await CreateParentAsync("parent_streak@test.com", "Parent Streak");
        var childId = await CreateChildAsync(parentId, profileId, "Streak Child");

        var act = Activity.Create("Act", "Desc", ActivityDomain.Speech, DifficultyLevel.Beginner);
        _dbContext.Activities.Add(act);

        var today = DateTime.UtcNow;
        var yesterday = today.AddDays(-1);
        var twoDaysAgo = today.AddDays(-2);

        // Session 1: Two days ago
        var s1 = Session.Start(childId, act.Id, ActivityDomain.Speech, twoDaysAgo);
        s1.Complete(twoDaysAgo.AddMinutes(10), 600);
        _dbContext.Sessions.Add(s1);

        // Session 2 & 3: Yesterday (Multiple sessions on same date should count as 1 day)
        var s2 = Session.Start(childId, act.Id, ActivityDomain.Speech, yesterday.AddHours(2));
        s2.Complete(yesterday.AddHours(3), 600);
        _dbContext.Sessions.Add(s2);

        var s3 = Session.Start(childId, act.Id, ActivityDomain.Speech, yesterday.AddHours(5));
        s3.Complete(yesterday.AddHours(6), 600);
        _dbContext.Sessions.Add(s3);

        // Session 4: Today
        var s4 = Session.Start(childId, act.Id, ActivityDomain.Speech, today);
        s4.Complete(today.AddMinutes(10), 600);
        _dbContext.Sessions.Add(s4);

        await _dbContext.SaveChangesAsync();

        SetCurrentUser(parentId, "parent_streak@test.com", "Parent Streak", UserRole.Parent, profileId);
        var handler = _serviceProvider.GetRequiredService<GetChildProgressHandler>();

        // Act
        var progress = await handler.HandleAsync(childId);

        // Assert: 3 consecutive days (today, yesterday, two days ago)
        Assert.Equal(3, progress.CurrentStreakDays);
        Assert.Equal(4, progress.TotalCompletedSessions);
    }

    [Fact]
    public async Task ProgressHistory_Returns_Sessions_In_Chronological_Order()
    {
        // Arrange
        var (parentId, profileId) = await CreateParentAsync("parent_hist@test.com", "Parent Hist");
        var childId = await CreateChildAsync(parentId, profileId, "Hist Child");

        var act = Activity.Create("History Act", "Desc", ActivityDomain.Attention, DifficultyLevel.Beginner);
        _dbContext.Activities.Add(act);

        var time1 = DateTime.UtcNow.AddDays(-3);
        var time2 = DateTime.UtcNow.AddDays(-1);

        var sessionOld = Session.Start(childId, act.Id, ActivityDomain.Attention, time1);
        sessionOld.Complete(time1.AddMinutes(5), 300);
        var analysisOld = SessionAnalysisResult.Create(sessionOld.Id, 70m, 70m, "First", false, DifficultyAdjustment.Maintain);
        sessionOld.AttachAnalysisResult(analysisOld);

        var sessionNew = Session.Start(childId, act.Id, ActivityDomain.Attention, time2);
        sessionNew.Complete(time2.AddMinutes(5), 300);
        var analysisNew = SessionAnalysisResult.Create(sessionNew.Id, 85m, 85m, "Second", false, DifficultyAdjustment.Increase);
        sessionNew.AttachAnalysisResult(analysisNew);

        _dbContext.Sessions.AddRange(sessionNew, sessionOld); // Added out of order
        _dbContext.SessionAnalysisResults.AddRange(analysisNew, analysisOld);
        await _dbContext.SaveChangesAsync();

        SetCurrentUser(parentId, "parent_hist@test.com", "Parent Hist", UserRole.Parent, profileId);
        var handler = _serviceProvider.GetRequiredService<GetChildProgressHistoryHandler>();

        // Act
        var history = await handler.HandleAsync(childId);

        // Assert: Must be chronologically ascending
        Assert.Equal(2, history.Count);
        Assert.Equal(sessionOld.Id, history[0].SessionId);
        Assert.Equal(sessionNew.Id, history[1].SessionId);
        Assert.Equal(70m, history[0].Score);
        Assert.Equal(85m, history[1].Score);
    }
}
