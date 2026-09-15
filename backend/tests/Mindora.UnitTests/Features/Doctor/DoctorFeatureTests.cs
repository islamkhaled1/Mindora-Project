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
using Mindora.Application.Features.Doctor.GetDoctorChildren;
using Mindora.Application.Features.Doctor.GetDoctorDashboard;
using Mindora.Application.Features.Doctor.Notes;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;
using Mindora.Infrastructure.Identity;
using Mindora.Infrastructure.Persistence;
using Mindora.Infrastructure.Services;
using Xunit;

namespace Mindora.UnitTests.Features.Doctor;

public class DoctorFeatureTests : IDisposable
{
    private readonly ServiceProvider _serviceProvider;
    private readonly ApplicationDbContext _dbContext;
    private readonly IHttpContextAccessor _httpContextAccessor;

    public DoctorFeatureTests()
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

    private async Task<Child> CreateChildAsync(Guid parentUserId, Guid parentProfileId, string childName, DifficultyLevel level = DifficultyLevel.Beginner)
    {
        SetCurrentUser(parentUserId, "parent@test.com", "Parent Test", UserRole.Parent, parentProfileId);
        var handler = _serviceProvider.GetRequiredService<CreateChildHandler>();
        var res = await handler.HandleAsync(new CreateChildRequest(childName, new DateOnly(2018, 1, 1), null, level, DifficultyLevel.Beginner, DifficultyLevel.Beginner));
        return await _dbContext.Children.FirstAsync(c => c.Id == res.Id);
    }

    private Activity CreateActivity(string title, ActivityDomain domain = ActivityDomain.Movement)
    {
        var activity = Activity.Create(
            title,
            "Description",
            domain,
            DifficultyLevel.Beginner,
            "{\"pace\":1.0}");
        _dbContext.Activities.Add(activity);
        _dbContext.SaveChanges();
        return activity;
    }

    private Session CreateCompletedSession(Child child, Activity activity, int durationSeconds, double score, PerformanceTrend trend = PerformanceTrend.Steady)
    {
        var session = Session.Start(child.Id, activity.Id, activity.Domain, DateTime.UtcNow.AddHours(-2));
        session.Complete(DateTime.UtcNow.AddHours(-1), durationSeconds);

        var analysis = SessionAnalysisResult.Create(
            session.Id,
            (decimal)score,
            (decimal)score,
            "Good engagement",
            false,
            DifficultyAdjustment.Maintain,
            "{}",
            DateTime.UtcNow.AddHours(-1),
            false);

        session.AttachAnalysisResult(analysis);
        _dbContext.Sessions.Add(session);
        _dbContext.SessionAnalysisResults.Add(analysis);
        _dbContext.SaveChanges();
        return session;
    }

    [Fact]
    public async Task GetDoctorDashboard_WhenNoAssignedChildren_ReturnsEmptyDashboard()
    {
        // Arrange
        var (docUser, docProfile) = await CreateDoctorAsync("doc_empty@test.com", "Dr. Empty");
        SetCurrentUser(docUser, "doc_empty@test.com", "Dr. Empty", UserRole.Doctor, docProfile);

        var handler = _serviceProvider.GetRequiredService<GetDoctorDashboardHandler>();

        // Act
        var result = await handler.HandleAsync();

        // Assert
        Assert.NotNull(result);
        Assert.Equal(0, result.TotalAssignedChildren);
        Assert.Equal(0, result.ActiveChildrenCount);
        Assert.Equal(0, result.WeeklyCompletedSessions);
        Assert.Equal(0.0m, result.AverageMovementScore);
        Assert.Equal(0, result.NeedsSupportCount);
        Assert.Empty(result.NeedsSupportAlerts);
        Assert.Empty(result.RecentCompletedSessions);
    }

    [Fact]
    public async Task GetDoctorDashboard_WithAssignedChildren_CalculatesMetricsAccurately()
    {
        // Arrange
        var (parentUser, parentProfile) = await CreateParentAsync("parent_dash@test.com", "Parent Dash");
        var child1 = await CreateChildAsync(parentUser, parentProfile, "Alice");
        var child2 = await CreateChildAsync(parentUser, parentProfile, "Bob");

        var (docUser, docProfile) = await CreateDoctorAsync("doc_dash@test.com", "Dr. Dash");

        // Assign both children to doctor
        _dbContext.DoctorChildAssignments.Add(DoctorChildAssignment.Create(docProfile, child1.Id));
        _dbContext.DoctorChildAssignments.Add(DoctorChildAssignment.Create(docProfile, child2.Id));
        await _dbContext.SaveChangesAsync();

        var activity = CreateActivity("Hand Eye Coordination", ActivityDomain.Movement);

        // Child 1 completed session with score 85
        CreateCompletedSession(child1, activity, 300, 85.0);

        // Child 2 completed sessions: earlier 75, recent 40 (declining trend => NeedsSupport)
        var sEarly = Session.Start(child2.Id, activity.Id, activity.Domain, DateTime.UtcNow.AddHours(-5));
        sEarly.Complete(DateTime.UtcNow.AddHours(-4), 180);
        var aEarly = SessionAnalysisResult.Create(sEarly.Id, 75.0m, 75.0m, "Prior", false, DifficultyAdjustment.Maintain, "{}", DateTime.UtcNow.AddHours(-4), false);
        sEarly.AttachAnalysisResult(aEarly);

        var sRecent = Session.Start(child2.Id, activity.Id, activity.Domain, DateTime.UtcNow.AddHours(-2));
        sRecent.Complete(DateTime.UtcNow.AddHours(-1), 180);
        var aRecent = SessionAnalysisResult.Create(sRecent.Id, 40.0m, 40.0m, "Recent", false, DifficultyAdjustment.Decrease, "{}", DateTime.UtcNow.AddHours(-1), false);
        sRecent.AttachAnalysisResult(aRecent);

        _dbContext.Sessions.AddRange(sEarly, sRecent);
        _dbContext.SessionAnalysisResults.AddRange(aEarly, aRecent);
        await _dbContext.SaveChangesAsync();

        SetCurrentUser(docUser, "doc_dash@test.com", "Dr. Dash", UserRole.Doctor, docProfile);
        var handler = _serviceProvider.GetRequiredService<GetDoctorDashboardHandler>();

        // Act
        var result = await handler.HandleAsync();

        // Assert
        Assert.NotNull(result);
        Assert.Equal(2, result.TotalAssignedChildren);
        Assert.Equal(2, result.ActiveChildrenCount);
        Assert.Equal(3, result.WeeklyCompletedSessions);
        Assert.Equal(66.67m, result.AverageMovementScore); // (85 + 75 + 40) / 3 = 66.67
        Assert.Equal(1, result.NeedsSupportCount); // Bob has delta = 40 - 75 = -35 (NeedsSupport)
        Assert.Single(result.NeedsSupportAlerts);
        Assert.Equal("Bob", result.NeedsSupportAlerts[0].FullName);
        Assert.Equal(3, result.RecentCompletedSessions.Count);
    }

    [Fact]
    public async Task GetDoctorDashboard_OnlyIncludesAssignedChildren_ExcludesOtherDoctorsChildren()
    {
        // Arrange
        var (parentUser, parentProfile) = await CreateParentAsync("parent_iso@test.com", "Parent Iso");
        var childAssigned = await CreateChildAsync(parentUser, parentProfile, "Child Mine");
        var childOther = await CreateChildAsync(parentUser, parentProfile, "Child Other");

        var (doc1User, doc1Profile) = await CreateDoctorAsync("doc1_iso@test.com", "Dr. One");
        var (doc2User, doc2Profile) = await CreateDoctorAsync("doc2_iso@test.com", "Dr. Two");

        _dbContext.DoctorChildAssignments.Add(DoctorChildAssignment.Create(doc1Profile, childAssigned.Id));
        _dbContext.DoctorChildAssignments.Add(DoctorChildAssignment.Create(doc2Profile, childOther.Id));
        await _dbContext.SaveChangesAsync();

        var activity = CreateActivity("Movement Flow");
        CreateCompletedSession(childAssigned, activity, 200, 90.0);
        CreateCompletedSession(childOther, activity, 500, 30.0);

        SetCurrentUser(doc1User, "doc1_iso@test.com", "Dr. One", UserRole.Doctor, doc1Profile);
        var handler = _serviceProvider.GetRequiredService<GetDoctorDashboardHandler>();

        // Act
        var result = await handler.HandleAsync();

        // Assert
        Assert.Equal(1, result.TotalAssignedChildren);
        Assert.Equal(90.0m, result.AverageMovementScore);
        Assert.Equal(0, result.NeedsSupportCount); // childOther with 30.0 belongs to doc2, not doc1
    }

    [Fact]
    public async Task GetDoctorChildren_ReturnsActiveAssignedChildrenOnly()
    {
        // Arrange
        var (parentUser, parentProfile) = await CreateParentAsync("parent_roster@test.com", "Parent Roster");
        var childActive = await CreateChildAsync(parentUser, parentProfile, "Active Child", DifficultyLevel.Intermediate);
        var childInactive = await CreateChildAsync(parentUser, parentProfile, "Inactive Child", DifficultyLevel.Beginner);
        var childUnassigned = await CreateChildAsync(parentUser, parentProfile, "Unassigned Child");

        var (docUser, docProfile) = await CreateDoctorAsync("doc_roster@test.com", "Dr. Roster");

        var activeAssignment = DoctorChildAssignment.Create(docProfile, childActive.Id);
        var inactiveAssignment = DoctorChildAssignment.Create(docProfile, childInactive.Id);
        inactiveAssignment.Deactivate();

        _dbContext.DoctorChildAssignments.AddRange(activeAssignment, inactiveAssignment);
        await _dbContext.SaveChangesAsync();

        var activity = CreateActivity("Balance Jump");
        CreateCompletedSession(childActive, activity, 300, 80.0);

        SetCurrentUser(docUser, "doc_roster@test.com", "Dr. Roster", UserRole.Doctor, docProfile);
        var handler = _serviceProvider.GetRequiredService<GetDoctorChildrenHandler>();

        // Act
        var result = await handler.HandleAsync();

        // Assert
        Assert.Single(result);
        var card = result[0];
        Assert.Equal(childActive.Id, card.ChildId);
        Assert.Equal("Active Child", card.FullName);
        Assert.Equal("Intermediate", card.CurrentMovementLevel);
        Assert.Equal(1, card.TotalCompletedSessions);
        Assert.Equal(5, card.TotalPracticeMinutes); // 300s = 5 min
        Assert.Equal(80.0m, card.OverallAverageScore);
        Assert.NotNull(card.LastSessionDateUtc);
    }

    [Fact]
    public async Task Parent_Calling_Doctor_Endpoints_ThrowsForbiddenException()
    {
        var (parentUser, parentProfile) = await CreateParentAsync("parent_forbid@test.com", "Parent Forbid");
        SetCurrentUser(parentUser, "parent_forbid@test.com", "Parent Forbid", UserRole.Parent, parentProfile);

        var dashHandler = _serviceProvider.GetRequiredService<GetDoctorDashboardHandler>();
        var childrenHandler = _serviceProvider.GetRequiredService<GetDoctorChildrenHandler>();
        var updateNotesHandler = _serviceProvider.GetRequiredService<UpdateDoctorNotesHandler>();
        var getNotesHandler = _serviceProvider.GetRequiredService<GetDoctorNotesHandler>();

        await Assert.ThrowsAsync<ForbiddenException>(() => dashHandler.HandleAsync());
        await Assert.ThrowsAsync<ForbiddenException>(() => childrenHandler.HandleAsync());
        await Assert.ThrowsAsync<ForbiddenException>(() => updateNotesHandler.HandleAsync(Guid.NewGuid(), new UpdateDoctorNotesRequest("Note")));
        await Assert.ThrowsAsync<ForbiddenException>(() => getNotesHandler.HandleAsync(Guid.NewGuid()));
    }

    [Fact]
    public async Task Doctor_Can_Update_And_Retrieve_Notes_For_Assigned_Child()
    {
        // Arrange
        var (parentUser, parentProfile) = await CreateParentAsync("parent_notes@test.com", "Parent Notes");
        var child = await CreateChildAsync(parentUser, parentProfile, "Notes Child");

        var (docUser, docProfile) = await CreateDoctorAsync("doc_notes@test.com", "Dr. Notes");

        var assignment = DoctorChildAssignment.Create(docProfile, child.Id);
        _dbContext.DoctorChildAssignments.Add(assignment);
        await _dbContext.SaveChangesAsync();

        SetCurrentUser(docUser, "doc_notes@test.com", "Dr. Notes", UserRole.Doctor, docProfile);

        var getNotesHandler = _serviceProvider.GetRequiredService<GetDoctorNotesHandler>();
        var updateNotesHandler = _serviceProvider.GetRequiredService<UpdateDoctorNotesHandler>();

        // Act 1 - Initial get should return null notes
        var initialNotes = await getNotesHandler.HandleAsync(child.Id);
        Assert.Equal(child.Id, initialNotes.ChildId);
        Assert.Null(initialNotes.Notes);
        Assert.Null(initialNotes.UpdatedAtUtc);

        // Act 2 - Update notes
        var updateResult = await updateNotesHandler.HandleAsync(child.Id, new UpdateDoctorNotesRequest("Child demonstrates steady motor improvement."));
        Assert.Equal(child.Id, updateResult.ChildId);
        Assert.Equal("Child demonstrates steady motor improvement.", updateResult.Notes);
        Assert.NotNull(updateResult.UpdatedAtUtc);

        // Act 3 - Retrieve updated notes
        var retrievedNotes = await getNotesHandler.HandleAsync(child.Id);
        Assert.Equal("Child demonstrates steady motor improvement.", retrievedNotes.Notes);
        Assert.Equal(updateResult.UpdatedAtUtc, retrievedNotes.UpdatedAtUtc);
    }

    [Fact]
    public async Task Doctor_Cannot_Update_Or_Get_Notes_For_Unassigned_Child()
    {
        // Arrange
        var (parentUser, parentProfile) = await CreateParentAsync("parent_unassigned@test.com", "Parent Unassigned");
        var child = await CreateChildAsync(parentUser, parentProfile, "Unassigned Child");

        var (docUser, docProfile) = await CreateDoctorAsync("doc_other@test.com", "Dr. Other");
        SetCurrentUser(docUser, "doc_other@test.com", "Dr. Other", UserRole.Doctor, docProfile);

        var getNotesHandler = _serviceProvider.GetRequiredService<GetDoctorNotesHandler>();
        var updateNotesHandler = _serviceProvider.GetRequiredService<UpdateDoctorNotesHandler>();

        // Act & Assert (IDOR protection: returns NotFoundException)
        await Assert.ThrowsAsync<NotFoundException>(() => getNotesHandler.HandleAsync(child.Id));
        await Assert.ThrowsAsync<NotFoundException>(() => updateNotesHandler.HandleAsync(child.Id, new UpdateDoctorNotesRequest("Test")));
    }

    [Fact]
    public async Task DoctorDashboard_Returns_WeeklyProgressTrend_And_TodayCompletedSessions()
    {
        // Arrange
        var (parentUser, parentProfile) = await CreateParentAsync("parent_trend@test.com", "Parent Trend");
        var child = await CreateChildAsync(parentUser, parentProfile, "Trend Child");

        var (docUser, docProfile) = await CreateDoctorAsync("doc_trend@test.com", "Dr. Trend");
        var assignment = DoctorChildAssignment.Create(docProfile, child.Id);
        _dbContext.DoctorChildAssignments.Add(assignment);
        await _dbContext.SaveChangesAsync();

        var activity = CreateActivity("Jumping Dots");

        // Session completed today
        var todaySession = Session.Start(child.Id, activity.Id, ActivityDomain.Movement, DateTime.UtcNow.AddHours(-1));
        todaySession.Complete(DateTime.UtcNow.AddMinutes(-30), 1800);
        var todayAnalysis = SessionAnalysisResult.Create(todaySession.Id, 85.0m, 85.0m, "Great agility", false, DifficultyAdjustment.Increase);
        todaySession.AttachAnalysisResult(todayAnalysis);

        _dbContext.Sessions.Add(todaySession);
        _dbContext.SessionAnalysisResults.Add(todayAnalysis);
        await _dbContext.SaveChangesAsync();

        SetCurrentUser(docUser, "doc_trend@test.com", "Dr. Trend", UserRole.Doctor, docProfile);
        var dashHandler = _serviceProvider.GetRequiredService<GetDoctorDashboardHandler>();

        // Act
        var dash = await dashHandler.HandleAsync();

        // Assert
        Assert.NotNull(dash.WeeklyProgressTrend);
        Assert.Equal(6, dash.WeeklyProgressTrend.Count);
        Assert.Equal(1, dash.WeeklyProgressTrend[0].WeekNumber);
        Assert.Equal("أسبوع 1", dash.WeeklyProgressTrend[0].WeekLabel);
        Assert.Equal(6, dash.WeeklyProgressTrend[5].WeekNumber);
        Assert.Equal("أسبوع 6", dash.WeeklyProgressTrend[5].WeekLabel);
        Assert.Equal(85.0m, dash.WeeklyProgressTrend[5].AverageScore); // today's session is in week 6

        Assert.NotNull(dash.TodayCompletedSessions);
        Assert.Single(dash.TodayCompletedSessions);
        Assert.Equal(todaySession.Id, dash.TodayCompletedSessions[0].SessionId);
        Assert.Equal("Trend Child", dash.TodayCompletedSessions[0].ChildFullName);
        Assert.Equal(85.0m, dash.TodayCompletedSessions[0].OverallScore);
    }
}
