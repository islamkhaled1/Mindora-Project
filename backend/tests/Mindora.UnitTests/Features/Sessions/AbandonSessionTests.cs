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
using Mindora.Application.Features.Sessions.AbandonSession;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;
using Mindora.Infrastructure.Identity;
using Mindora.Infrastructure.Persistence;
using Mindora.Infrastructure.Services;
using Xunit;

namespace Mindora.UnitTests.Features.Sessions;

public class AbandonSessionTests : IDisposable
{
    private readonly ServiceProvider _serviceProvider;
    private readonly ApplicationDbContext _dbContext;
    private readonly IHttpContextAccessor _httpContextAccessor;

    public AbandonSessionTests()
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

    private async Task<Child> CreateChildAsync(Guid parentUserId, Guid parentProfileId, string childName = "Ben")
    {
        SetCurrentUser(parentUserId, "parent@test.com", "Parent Test", UserRole.Parent, parentProfileId);
        var handler = _serviceProvider.GetRequiredService<CreateChildHandler>();
        var res = await handler.HandleAsync(new CreateChildRequest(childName, new DateOnly(2019, 1, 1), null, DifficultyLevel.Beginner, DifficultyLevel.Beginner, DifficultyLevel.Beginner));
        return await _dbContext.Children.FirstAsync(c => c.Id == res.Id);
    }

    private Activity CreateActivity(string title)
    {
        var activity = Activity.Create(title, "Description", ActivityDomain.Movement, DifficultyLevel.Beginner, "{}");
        _dbContext.Activities.Add(activity);
        _dbContext.SaveChanges();
        return activity;
    }

    [Fact]
    public async Task Started_Session_Can_Be_Abandoned_By_Parent()
    {
        // Arrange
        var (parentUser, parentProfile) = await CreateParentAsync("parent_ab@test.com", "Parent Ab");
        var child = await CreateChildAsync(parentUser, parentProfile);
        var activity = CreateActivity("Balance");

        var session = Session.Start(child.Id, activity.Id, activity.Domain);
        _dbContext.Sessions.Add(session);
        await _dbContext.SaveChangesAsync();

        SetCurrentUser(parentUser, "parent_ab@test.com", "Parent Ab", UserRole.Parent, parentProfile);
        var handler = _serviceProvider.GetRequiredService<AbandonSessionHandler>();

        // Act
        var result = await handler.HandleAsync(session.Id);

        // Assert
        Assert.NotNull(result);
        Assert.Equal(session.Id, result.Id);
        Assert.Equal(SessionStatus.Abandoned.ToString(), result.Status);

        var updatedSession = await _dbContext.Sessions.FindAsync(session.Id);
        Assert.Equal(SessionStatus.Abandoned, updatedSession!.Status);
        Assert.NotNull(updatedSession.EndTimeUtc);
    }

    [Fact]
    public async Task Started_Session_Can_Be_Abandoned_By_Assigned_Doctor()
    {
        // Arrange
        var (parentUser, parentProfile) = await CreateParentAsync("parent_docab@test.com", "Parent DocAb");
        var child = await CreateChildAsync(parentUser, parentProfile);
        var activity = CreateActivity("Balance");

        var (docUser, docProfile) = await CreateDoctorAsync("doc_ab@test.com", "Dr. Ab");
        _dbContext.DoctorChildAssignments.Add(DoctorChildAssignment.Create(docProfile, child.Id));

        var session = Session.Start(child.Id, activity.Id, activity.Domain);
        _dbContext.Sessions.Add(session);
        await _dbContext.SaveChangesAsync();

        SetCurrentUser(docUser, "doc_ab@test.com", "Dr. Ab", UserRole.Doctor, docProfile);
        var handler = _serviceProvider.GetRequiredService<AbandonSessionHandler>();

        // Act
        var result = await handler.HandleAsync(session.Id);

        // Assert
        Assert.NotNull(result);
        Assert.Equal(SessionStatus.Abandoned.ToString(), result.Status);
    }

    [Fact]
    public async Task Completed_Session_Cannot_Be_Abandoned_ThrowsConflictException()
    {
        // Arrange
        var (parentUser, parentProfile) = await CreateParentAsync("parent_comp@test.com", "Parent Comp");
        var child = await CreateChildAsync(parentUser, parentProfile);
        var activity = CreateActivity("Balance");

        var session = Session.Start(child.Id, activity.Id, activity.Domain);
        session.Complete(DateTime.UtcNow, 100);
        _dbContext.Sessions.Add(session);
        await _dbContext.SaveChangesAsync();

        SetCurrentUser(parentUser, "parent_comp@test.com", "Parent Comp", UserRole.Parent, parentProfile);
        var handler = _serviceProvider.GetRequiredService<AbandonSessionHandler>();

        // Act & Assert
        await Assert.ThrowsAsync<ConflictException>(() => handler.HandleAsync(session.Id));
    }

    [Fact]
    public async Task Repeated_Abandon_Call_Is_Idempotent()
    {
        // Arrange
        var (parentUser, parentProfile) = await CreateParentAsync("parent_idem@test.com", "Parent Idem");
        var child = await CreateChildAsync(parentUser, parentProfile);
        var activity = CreateActivity("Balance");

        var session = Session.Start(child.Id, activity.Id, activity.Domain);
        _dbContext.Sessions.Add(session);
        await _dbContext.SaveChangesAsync();

        SetCurrentUser(parentUser, "parent_idem@test.com", "Parent Idem", UserRole.Parent, parentProfile);
        var handler = _serviceProvider.GetRequiredService<AbandonSessionHandler>();

        // Act 1
        var result1 = await handler.HandleAsync(session.Id);
        // Act 2 (repeated)
        var result2 = await handler.HandleAsync(session.Id);

        // Assert
        Assert.Equal(SessionStatus.Abandoned.ToString(), result1.Status);
        Assert.Equal(SessionStatus.Abandoned.ToString(), result2.Status);
    }

    [Fact]
    public async Task Unrelated_Parent_Or_Doctor_Cannot_Abandon_Session()
    {
        // Arrange
        var (parent1User, parent1Profile) = await CreateParentAsync("p1_ab@test.com", "P1");
        var (parent2User, parent2Profile) = await CreateParentAsync("p2_ab@test.com", "P2");
        var (docUser, docProfile) = await CreateDoctorAsync("doc_unab@test.com", "Dr. Unab");

        var child = await CreateChildAsync(parent1User, parent1Profile);
        var activity = CreateActivity("Balance");

        var session = Session.Start(child.Id, activity.Id, activity.Domain);
        _dbContext.Sessions.Add(session);
        await _dbContext.SaveChangesAsync();

        var handler = _serviceProvider.GetRequiredService<AbandonSessionHandler>();

        // Unrelated Parent
        SetCurrentUser(parent2User, "p2_ab@test.com", "P2", UserRole.Parent, parent2Profile);
        await Assert.ThrowsAsync<NotFoundException>(() => handler.HandleAsync(session.Id));

        // Unassigned Doctor
        SetCurrentUser(docUser, "doc_unab@test.com", "Dr. Unab", UserRole.Doctor, docProfile);
        await Assert.ThrowsAsync<NotFoundException>(() => handler.HandleAsync(session.Id));
    }
}
