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
using Mindora.Application.Common.Models;
using Mindora.Application.Features.Auth.RegisterDoctor;
using Mindora.Application.Features.Auth.RegisterParent;
using Mindora.Application.Features.Children.AssignDoctor;
using Mindora.Application.Features.Children.CreateChild;
using Mindora.Application.Features.Sessions.CompleteSession;
using Mindora.Application.Features.Sessions.GetSessionDetails;
using Mindora.Application.Features.Sessions.Models;
using Mindora.Application.Features.Sessions.RecordMetrics;
using Mindora.Application.Features.Sessions.StartSession;
using Mindora.Domain.Common;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;
using Mindora.Infrastructure.Ai;
using Mindora.Infrastructure.Identity;
using Mindora.Infrastructure.Persistence;
using Mindora.Infrastructure.Services;
using Xunit;

namespace Mindora.UnitTests.Features.Sessions;

public class SessionLifecycleTests : IDisposable
{
    private readonly ServiceProvider _serviceProvider;
    private readonly ApplicationDbContext _dbContext;
    private readonly IHttpContextAccessor _httpContextAccessor;
    private readonly TrackingAiAnalysisService _trackingAiService;

    public SessionLifecycleTests()
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

        // Register Tracking AI Service to monitor AI invocations and idempotency
        _trackingAiService = new TrackingAiAnalysisService();
        services.AddSingleton<IAiAnalysisService>(_trackingAiService);

        services.AddApplicationServices();

        _serviceProvider = services.BuildServiceProvider();
        _dbContext = _serviceProvider.GetRequiredService<ApplicationDbContext>();
        _httpContextAccessor = _serviceProvider.GetRequiredService<IHttpContextAccessor>();

        SeedActivity();
    }

    public void Dispose()
    {
        _dbContext.Dispose();
        _serviceProvider.Dispose();
    }

    private readonly Guid _activityId = Guid.Parse("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa");

    private void SeedActivity()
    {
        _dbContext.Activities.Add(new Activity(
            _activityId,
            "Balance Path Walking",
            "Follow the designated line.",
            ActivityDomain.Movement,
            DifficultyLevel.Beginner,
            null,
            isActive: true));
        _dbContext.SaveChanges();
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
    public async Task StartSession_Uses_Activity_Domain_Authoritatively()
    {
        // Arrange
        var (parentId, profileId) = await CreateParentAsync("parent_session@test.com", "Parent Session");
        var childId = await CreateChildAsync(parentId, profileId, "Session Child");

        SetCurrentUser(parentId, "parent_session@test.com", "Parent Session", UserRole.Parent, profileId);
        var handler = _serviceProvider.GetRequiredService<StartSessionHandler>();

        // Act
        var session = await handler.HandleAsync(new StartSessionRequest(childId, _activityId));

        // Assert
        Assert.NotNull(session);
        Assert.Equal(childId, session.ChildId);
        Assert.Equal(_activityId, session.ActivityId);
        Assert.Equal("Movement", session.Domain); // Inherited from Activity.Domain
        Assert.Equal("Started", session.Status);
    }

    [Fact]
    public async Task Started_Session_Accepts_Metrics()
    {
        // Arrange
        var (parentId, profileId) = await CreateParentAsync("parent_metric@test.com", "Parent Metric");
        var childId = await CreateChildAsync(parentId, profileId, "Metric Child");

        SetCurrentUser(parentId, "parent_metric@test.com", "Parent Metric", UserRole.Parent, profileId);
        var startHandler = _serviceProvider.GetRequiredService<StartSessionHandler>();
        var session = await startHandler.HandleAsync(new StartSessionRequest(childId, _activityId));

        var recordHandler = _serviceProvider.GetRequiredService<RecordMetricsHandler>();
        var request = new RecordMetricsRequest(new List<MetricInputDto>
        {
            new("AccuracyPercentage", 90.00m),
            new("ReactionTimeMs", 1850.00m)
        });

        // Act
        var metrics = await recordHandler.HandleAsync(session.Id, request);

        // Assert
        Assert.Equal(2, metrics.Count);
        Assert.Equal(90.00m, metrics[0].Value);
        Assert.Equal(1850.00m, metrics[1].Value);

        var savedCount = _dbContext.PerformanceMetrics.Count(m => m.SessionId == session.Id);
        Assert.Equal(2, savedCount);
    }

    [Fact]
    public async Task Completed_Session_Rejects_New_Metrics()
    {
        // Arrange
        var (parentId, profileId) = await CreateParentAsync("parent_rej@test.com", "Parent Rej");
        var childId = await CreateChildAsync(parentId, profileId, "Rej Child");

        SetCurrentUser(parentId, "parent_rej@test.com", "Parent Rej", UserRole.Parent, profileId);
        var startHandler = _serviceProvider.GetRequiredService<StartSessionHandler>();
        var session = await startHandler.HandleAsync(new StartSessionRequest(childId, _activityId));

        var completeHandler = _serviceProvider.GetRequiredService<CompleteSessionHandler>();
        await completeHandler.HandleAsync(session.Id, new CompleteSessionRequest(60));

        var recordHandler = _serviceProvider.GetRequiredService<RecordMetricsHandler>();

        // Act & Assert: DomainException thrown when adding metrics to completed session
        await Assert.ThrowsAsync<DomainException>(() =>
            recordHandler.HandleAsync(session.Id, new RecordMetricsRequest(new List<MetricInputDto>
            {
                new("AccuracyPercentage", 95.00m)
            })));
    }

    [Fact]
    public async Task Idempotent_Completion_Does_Not_Invoke_AI_Again_Nor_Duplicate_Data()
    {
        // Arrange
        var (parentId, profileId) = await CreateParentAsync("parent_idemp@test.com", "Parent Idemp");
        var childId = await CreateChildAsync(parentId, profileId, "Idemp Child");

        SetCurrentUser(parentId, "parent_idemp@test.com", "Parent Idemp", UserRole.Parent, profileId);
        var startHandler = _serviceProvider.GetRequiredService<StartSessionHandler>();
        var session = await startHandler.HandleAsync(new StartSessionRequest(childId, _activityId));

        var completeHandler = _serviceProvider.GetRequiredService<CompleteSessionHandler>();
        var completeRequest = new CompleteSessionRequest(120, new List<MetricInputDto>
        {
            new("AccuracyPercentage", 88.00m)
        });

        // Act 1: First completion
        var firstResult = await completeHandler.HandleAsync(session.Id, completeRequest);
        int initialAiCallCount = _trackingAiService.CallCount;

        // Act 2: Second completion on same session
        var secondResult = await completeHandler.HandleAsync(session.Id, completeRequest);

        // Assert
        Assert.Equal(1, initialAiCallCount);
        Assert.Equal(1, _trackingAiService.CallCount); // AI was NOT invoked again!

        Assert.Equal(firstResult.Id, secondResult.Id);
        Assert.Equal(firstResult.EndTimeUtc, secondResult.EndTimeUtc);
        Assert.Equal(firstResult.AnalysisResult?.OverallPerformanceScore, secondResult.AnalysisResult?.OverallPerformanceScore);

        // Verify exactly one analysis result row exists
        var analysisCount = _dbContext.SessionAnalysisResults.Count(r => r.SessionId == session.Id);
        Assert.Equal(1, analysisCount);

        // Verify metrics were not duplicated
        var metricCount = _dbContext.PerformanceMetrics.Count(m => m.SessionId == session.Id);
        Assert.Equal(1, metricCount);
    }

    [Fact]
    public async Task Metric_Validation_Enforces_Type_And_Value_Rules()
    {
        var validator = new RecordMetricsValidator();

        // 1. Accuracy valid boundaries
        var validAcc = new RecordMetricsRequest(new List<MetricInputDto> { new("AccuracyPercentage", 0m), new("AccuracyPercentage", 100m) });
        var res1 = await validator.ValidateAsync(validAcc);
        Assert.True(res1.IsValid);

        // 2. Accuracy out of bounds
        var badAcc1 = new RecordMetricsRequest(new List<MetricInputDto> { new("AccuracyPercentage", -1m) });
        var badAcc2 = new RecordMetricsRequest(new List<MetricInputDto> { new("AccuracyPercentage", 101m) });
        Assert.False((await validator.ValidateAsync(badAcc1)).IsValid);
        Assert.False((await validator.ValidateAsync(badAcc2)).IsValid);

        // 3. Negative durations/latencies/counts
        var negRep = new RecordMetricsRequest(new List<MetricInputDto> { new("RepetitionCount", -1m) });
        var negReact = new RecordMetricsRequest(new List<MetricInputDto> { new("ReactionTimeMs", -50m) });
        var negLatency = new RecordMetricsRequest(new List<MetricInputDto> { new("ResponseLatencyMs", -10m) });
        var negDuration = new RecordMetricsRequest(new List<MetricInputDto> { new("AttentionDurationSeconds", -5m) });
        Assert.False((await validator.ValidateAsync(negRep)).IsValid);
        Assert.False((await validator.ValidateAsync(negReact)).IsValid);
        Assert.False((await validator.ValidateAsync(negLatency)).IsValid);
        Assert.False((await validator.ValidateAsync(negDuration)).IsValid);

        // 4. Unknown metric type
        var unknown = new RecordMetricsRequest(new List<MetricInputDto> { new("ArbitraryMetricName", 50m) });
        var resUnknown = await validator.ValidateAsync(unknown);
        Assert.False(resUnknown.IsValid);
        Assert.Contains(resUnknown.Errors, e => e.ErrorMessage.Contains("Unsupported metric type"));
    }

    [Fact]
    public async Task CompleteSession_Invokes_AI_Before_Modifying_Session_Or_Persisting_State()
    {
        // Arrange
        var (parentId, profileId) = await CreateParentAsync("parent_tx@test.com", "Parent Tx");
        var childId = await CreateChildAsync(parentId, profileId, "Tx Child");

        SetCurrentUser(parentId, "parent_tx@test.com", "Parent Tx", UserRole.Parent, profileId);
        var startHandler = _serviceProvider.GetRequiredService<StartSessionHandler>();
        var session = await startHandler.HandleAsync(new StartSessionRequest(childId, _activityId));

        bool aiExecutedBeforeDbCommit = false;

        // Custom inspection inside AI invocation: verify session is still Started and uncommitted in DB
        _trackingAiService.OnAnalyze = () =>
        {
            var currentSessionInDb = _dbContext.Sessions.AsNoTracking().FirstOrDefault(s => s.Id == session.Id);
            var hasAnalysisResultInDb = _dbContext.SessionAnalysisResults.AsNoTracking().Any(r => r.SessionId == session.Id);

            // AI MUST execute while session is still in Started status and no analysis result is yet in DB
            if (currentSessionInDb != null && currentSessionInDb.Status == SessionStatus.Started && !hasAnalysisResultInDb)
            {
                aiExecutedBeforeDbCommit = true;
            }
        };

        var completeHandler = _serviceProvider.GetRequiredService<CompleteSessionHandler>();

        // Act
        var result = await completeHandler.HandleAsync(session.Id, new CompleteSessionRequest(90));

        // Assert
        Assert.True(aiExecutedBeforeDbCommit, "AI evaluation must occur prior to database state mutations/commit.");
        Assert.Equal("Completed", result.Status);
    }

    private class TrackingAiAnalysisService : IAiAnalysisService
    {
        public int CallCount { get; private set; }
        public Action? OnAnalyze { get; set; }

        public Task<AiSessionAnalysisResult> AnalyzeSessionPerformanceAsync(
            AiSessionAnalysisRequest request,
            CancellationToken cancellationToken = default)
        {
            CallCount++;
            OnAnalyze?.Invoke();

            var result = new AiSessionAnalysisResult(
                85.00m,
                85.00m,
                "Supportive performance analysis observation.",
                false,
                DifficultyAdjustment.Increase,
                "{\"targetPacingSeconds\":3}",
                false);
            return Task.FromResult(result);
        }
    }
}
