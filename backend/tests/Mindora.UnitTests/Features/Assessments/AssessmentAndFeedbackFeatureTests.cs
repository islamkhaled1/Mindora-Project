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
using Mindora.Application.Features.Assessments.GetChildBaselineAssessment;
using Mindora.Application.Features.Assessments.RecordBaselineAssessment;
using Mindora.Application.Features.Auth.RegisterDoctor;
using Mindora.Application.Features.Auth.RegisterParent;
using Mindora.Application.Features.Children.AssignDoctor;
using Mindora.Application.Features.Children.CreateChild;
using Mindora.Application.Features.Sessions.CompleteSession;
using Mindora.Application.Features.Sessions.RecordFeedback;
using Mindora.Application.Features.Sessions.StartSession;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;
using Mindora.Infrastructure.Identity;
using Mindora.Infrastructure.Persistence;
using Mindora.Infrastructure.Services;
using Xunit;

namespace Mindora.UnitTests.Features.Assessments;

public class AssessmentAndFeedbackFeatureTests : IDisposable
{
    private readonly ServiceProvider _serviceProvider;
    private readonly ApplicationDbContext _dbContext;
    private readonly IHttpContextAccessor _httpContextAccessor;

    public AssessmentAndFeedbackFeatureTests()
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

        // Register fake AI service for session completion
        services.AddScoped<IAiAnalysisService, FakeAiAnalysisService>();

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
        var principal = new ClaimsPrincipal(identity);

        _httpContextAccessor.HttpContext = new DefaultHttpContext
        {
            User = principal
        };
    }

    private async Task<(Guid UserId, Guid ProfileId)> CreateParentAsync(string email, string fullName)
    {
        var handler = _serviceProvider.GetRequiredService<RegisterParentHandler>();
        var result = await handler.HandleAsync(new RegisterParentRequest(email, "StrongPass123!", fullName, null));
        return (result.User.Id, result.User.ProfileId);
    }

    private async Task<(Guid UserId, Guid ProfileId)> CreateDoctorAsync(string email, string fullName, string specialization, string clinic)
    {
        var handler = _serviceProvider.GetRequiredService<RegisterDoctorHandler>();
        var result = await handler.HandleAsync(new RegisterDoctorRequest(email, "StrongPass123!", fullName, specialization, clinic, "LIC-12345"));
        return (result.User.Id, result.User.ProfileId);
    }

    [Fact]
    public async Task Parent_Can_Record_And_Retrieve_BaselineAssessment()
    {
        // Arrange
        var (parentId, profileId) = await CreateParentAsync("parent_assess@test.com", "Parent Assess");
        SetCurrentUser(parentId, "parent_assess@test.com", "Parent Assess", UserRole.Parent, profileId);

        var childHandler = _serviceProvider.GetRequiredService<CreateChildHandler>();
        var child = await childHandler.HandleAsync(new CreateChildRequest("Tariq", new DateOnly(2020, 3, 15), null, DifficultyLevel.Beginner, DifficultyLevel.Beginner, DifficultyLevel.Beginner));

        var recordHandler = _serviceProvider.GetRequiredService<RecordBaselineAssessmentHandler>();
        var request = new RecordBaselineAssessmentRequest(
            OverallScore: 84.5m,
            CognitiveScore: 80.0m,
            CommunicationScore: 82.5m,
            MotorScore: 90.0m,
            EmotionalScore: 85.5m);

        // Act: Record baseline assessment
        var assessmentDto = await recordHandler.HandleAsync(child.Id, request);

        // Assert
        Assert.NotNull(assessmentDto);
        Assert.Equal(child.Id, assessmentDto.ChildId);
        Assert.Equal(84.5m, assessmentDto.OverallScore);
        Assert.Equal(80.0m, assessmentDto.CognitiveScore);
        Assert.Equal(82.5m, assessmentDto.CommunicationScore);
        Assert.Equal(90.0m, assessmentDto.MotorScore);
        Assert.Equal(85.5m, assessmentDto.EmotionalScore);

        // Act: Get baseline assessment
        var getHandler = _serviceProvider.GetRequiredService<GetChildBaselineAssessmentHandler>();
        var retrieved = await getHandler.HandleAsync(child.Id);

        // Assert
        Assert.Equal(assessmentDto.Id, retrieved.Id);
        Assert.Equal(84.5m, retrieved.OverallScore);
    }

    [Fact]
    public async Task Assigned_Doctor_Can_Retrieve_BaselineAssessment()
    {
        // Arrange
        var (parentId, parentProfileId) = await CreateParentAsync("parent_doc_assess@test.com", "Parent Doc Assess");
        var (doctorId, doctorProfileId) = await CreateDoctorAsync("doc_assess@test.com", "Dr. Mona", "Child Neurologist", "Sunrise Clinic");

        SetCurrentUser(parentId, "parent_doc_assess@test.com", "Parent Doc Assess", UserRole.Parent, parentProfileId);
        var childHandler = _serviceProvider.GetRequiredService<CreateChildHandler>();
        var child = await childHandler.HandleAsync(new CreateChildRequest("Lina", new DateOnly(2019, 8, 20), null, DifficultyLevel.Beginner, DifficultyLevel.Beginner, DifficultyLevel.Beginner));

        var recordHandler = _serviceProvider.GetRequiredService<RecordBaselineAssessmentHandler>();
        await recordHandler.HandleAsync(child.Id, new RecordBaselineAssessmentRequest(75m, 70m, 75m, 80m, 75m));

        // Assign doctor
        var assignHandler = _serviceProvider.GetRequiredService<AssignDoctorHandler>();
        await assignHandler.HandleAsync(child.Id, new AssignDoctorRequest(doctorProfileId));

        // Act: Doctor retrieves baseline assessment
        SetCurrentUser(doctorId, "doc_assess@test.com", "Dr. Mona", UserRole.Doctor, doctorProfileId);
        var getHandler = _serviceProvider.GetRequiredService<GetChildBaselineAssessmentHandler>();
        var result = await getHandler.HandleAsync(child.Id);

        // Assert
        Assert.NotNull(result);
        Assert.Equal(75m, result.OverallScore);
    }

    [Fact]
    public async Task Parent_Can_Record_Session_Feedback()
    {
        // Arrange
        var (parentId, profileId) = await CreateParentAsync("parent_feedback@test.com", "Parent Feedback");
        SetCurrentUser(parentId, "parent_feedback@test.com", "Parent Feedback", UserRole.Parent, profileId);

        var childHandler = _serviceProvider.GetRequiredService<CreateChildHandler>();
        var child = await childHandler.HandleAsync(new CreateChildRequest("Kareem", new DateOnly(2018, 4, 10), null, DifficultyLevel.Beginner, DifficultyLevel.Beginner, DifficultyLevel.Beginner));

        var activity = Activity.Create("Movement Tap", "Tap exercises", ActivityDomain.Movement, DifficultyLevel.Beginner);
        _dbContext.Activities.Add(activity);
        await _dbContext.SaveChangesAsync();

        var startHandler = _serviceProvider.GetRequiredService<StartSessionHandler>();
        var startedSession = await startHandler.HandleAsync(new StartSessionRequest(child.Id, activity.Id));

        var completeHandler = _serviceProvider.GetRequiredService<CompleteSessionHandler>();
        await completeHandler.HandleAsync(startedSession.Id, new CompleteSessionRequest(300));

        // Act: Parent submits feedback post-session
        var feedbackHandler = _serviceProvider.GetRequiredService<RecordFeedbackHandler>();
        var feedbackResult = await feedbackHandler.HandleAsync(
            startedSession.Id,
            new RecordFeedbackRequest(ParentSentimentRating.Easy, "Completed with enthusiasm!"));

        // Assert
        Assert.NotNull(feedbackResult);
        Assert.Equal("Easy", feedbackResult.ParentRating);
        Assert.Equal("Completed with enthusiasm!", feedbackResult.ParentNotes);
    }

    [Fact]
    public async Task CompleteSession_With_ParentFeedback_Records_Feedback_Atomically()
    {
        // Arrange
        var (parentId, profileId) = await CreateParentAsync("parent_atomic_fb@test.com", "Parent Atomic");
        SetCurrentUser(parentId, "parent_atomic_fb@test.com", "Parent Atomic", UserRole.Parent, profileId);

        var childHandler = _serviceProvider.GetRequiredService<CreateChildHandler>();
        var child = await childHandler.HandleAsync(new CreateChildRequest("Adam", new DateOnly(2019, 1, 10), null, DifficultyLevel.Beginner, DifficultyLevel.Beginner, DifficultyLevel.Beginner));

        var activity = Activity.Create("Balance Walk", "Balance exercise", ActivityDomain.Movement, DifficultyLevel.Beginner);
        _dbContext.Activities.Add(activity);
        await _dbContext.SaveChangesAsync();

        var startHandler = _serviceProvider.GetRequiredService<StartSessionHandler>();
        var startedSession = await startHandler.HandleAsync(new StartSessionRequest(child.Id, activity.Id));

        // Act: Complete session providing parent feedback in same request
        var completeHandler = _serviceProvider.GetRequiredService<CompleteSessionHandler>();
        var result = await completeHandler.HandleAsync(
            startedSession.Id,
            new CompleteSessionRequest(
                ActualDurationSeconds: 420,
                Metrics: null,
                ParentRating: ParentSentimentRating.Medium,
                ParentNotes: "Needed a little guidance at the start."));

        // Assert
        Assert.NotNull(result);
        Assert.Equal("Medium", result.ParentRating);
        Assert.Equal("Needed a little guidance at the start.", result.ParentNotes);
    }

    private class FakeAiAnalysisService : IAiAnalysisService
    {
        public Task<AiSessionAnalysisResult> AnalyzeSessionPerformanceAsync(
            AiSessionAnalysisRequest request,
            CancellationToken cancellationToken = default)
        {
            return Task.FromResult(new AiSessionAnalysisResult(
                overallPerformanceScore: 85.00m,
                domainScore: 88.00m,
                supportiveObservations: "Stable performance.",
                fatigueObserved: false,
                recommendedDifficultyAdjustment: DifficultyAdjustment.Maintain,
                adaptiveParameters: null,
                isFallbackResult: false));
        }
    }
}
