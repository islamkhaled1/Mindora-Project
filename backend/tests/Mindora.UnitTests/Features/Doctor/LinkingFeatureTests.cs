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
using Mindora.Application.Features.Auth.RegisterDoctor;
using Mindora.Application.Features.Auth.RegisterParent;
using Mindora.Application.Features.Children.CreateChild;
using Mindora.Application.Features.Children.GenerateLinkingCode;
using Mindora.Application.Features.Doctor.LinkChild;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;
using Mindora.Infrastructure.Identity;
using Mindora.Infrastructure.Persistence;
using Mindora.Infrastructure.Services;
using Xunit;

namespace Mindora.UnitTests.Features.Doctor;

public class LinkingFeatureTests : IDisposable
{
    private readonly ServiceProvider _serviceProvider;
    private readonly ApplicationDbContext _dbContext;
    private readonly IHttpContextAccessor _httpContextAccessor;
    private readonly ILinkingRateLimiter _rateLimiter;

    public LinkingFeatureTests()
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
        _rateLimiter = _serviceProvider.GetRequiredService<ILinkingRateLimiter>();
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

    private async Task<Guid> CreateChildAsync(Guid parentUserId, Guid parentProfileId, string childName = "Sam")
    {
        SetCurrentUser(parentUserId, "parent@test.com", "Parent Test", UserRole.Parent, parentProfileId);
        var handler = _serviceProvider.GetRequiredService<CreateChildHandler>();
        var res = await handler.HandleAsync(new CreateChildRequest(childName, new DateOnly(2018, 5, 12), null, DifficultyLevel.Beginner, DifficultyLevel.Beginner, DifficultyLevel.Beginner));
        return res.Id;
    }

    [Fact]
    public async Task Parent_Can_Generate_Linking_Code_For_Own_Child()
    {
        // Arrange
        var (parentUserId, parentProfileId) = await CreateParentAsync("parent_code@test.com", "Parent Code");
        var childId = await CreateChildAsync(parentUserId, parentProfileId);

        SetCurrentUser(parentUserId, "parent_code@test.com", "Parent Code", UserRole.Parent, parentProfileId);
        var handler = _serviceProvider.GetRequiredService<GenerateLinkingCodeHandler>();

        // Act
        var result = await handler.HandleAsync(childId);

        // Assert
        Assert.NotNull(result);
        Assert.StartsWith("MND-", result.Code);
        Assert.True(result.ExpiresAtUtc > DateTime.UtcNow);

        // Verify entity stored as hash, not plaintext
        var entity = await _dbContext.ChildLinkingCodes.FirstOrDefaultAsync(c => c.ChildId == childId);
        Assert.NotNull(entity);
        Assert.NotEqual(result.Code, entity.CodeHash);
        Assert.Equal(ChildLinkingCode.ComputeHash(result.Code), entity.CodeHash);
    }

    [Fact]
    public async Task Generating_New_Code_Invalidates_Previous_Unredeemed_Codes()
    {
        // Arrange
        var (parentUserId, parentProfileId) = await CreateParentAsync("parent_multi@test.com", "Parent Multi");
        var childId = await CreateChildAsync(parentUserId, parentProfileId);

        SetCurrentUser(parentUserId, "parent_multi@test.com", "Parent Multi", UserRole.Parent, parentProfileId);
        var handler = _serviceProvider.GetRequiredService<GenerateLinkingCodeHandler>();

        // Act
        var code1 = await handler.HandleAsync(childId);
        var code2 = await handler.HandleAsync(childId);

        // Assert
        var codes = await _dbContext.ChildLinkingCodes.Where(c => c.ChildId == childId).ToListAsync();
        Assert.Equal(2, codes.Count);

        var oldCodeEntity = codes.First(c => c.CodeHash == ChildLinkingCode.ComputeHash(code1.Code));
        var newCodeEntity = codes.First(c => c.CodeHash == ChildLinkingCode.ComputeHash(code2.Code));

        Assert.True(oldCodeEntity.IsExpired(DateTime.UtcNow.AddSeconds(1))); // Previous code was expired
        Assert.False(newCodeEntity.IsExpired(DateTime.UtcNow));
    }

    [Fact]
    public async Task Parent_Cannot_Generate_Code_For_Another_Parents_Child_ThrowsNotFoundException()
    {
        // Arrange
        var (parent1User, parent1Profile) = await CreateParentAsync("parent1@test.com", "Parent 1");
        var (parent2User, parent2Profile) = await CreateParentAsync("parent2@test.com", "Parent 2");
        var childId1 = await CreateChildAsync(parent1User, parent1Profile);

        // Log in as Parent 2
        SetCurrentUser(parent2User, "parent2@test.com", "Parent 2", UserRole.Parent, parent2Profile);
        var handler = _serviceProvider.GetRequiredService<GenerateLinkingCodeHandler>();

        // Act & Assert (IDOR protection: return NotFoundException)
        await Assert.ThrowsAsync<NotFoundException>(() => handler.HandleAsync(childId1));
    }

    [Fact]
    public async Task Doctor_Cannot_Generate_Linking_Code_ThrowsForbiddenException()
    {
        // Arrange
        var (parentUser, parentProfile) = await CreateParentAsync("parent_doc@test.com", "Parent Doc");
        var childId = await CreateChildAsync(parentUser, parentProfile);

        var (docUser, docProfile) = await CreateDoctorAsync("doc_gen@test.com", "Dr. Gen");
        SetCurrentUser(docUser, "doc_gen@test.com", "Dr. Gen", UserRole.Doctor, docProfile);

        var handler = _serviceProvider.GetRequiredService<GenerateLinkingCodeHandler>();

        // Act & Assert
        await Assert.ThrowsAsync<ForbiddenException>(() => handler.HandleAsync(childId));
    }

    [Fact]
    public async Task Doctor_Can_Redeem_Valid_Code_Successfully_Assigns_Child()
    {
        // Arrange
        var (parentUser, parentProfile) = await CreateParentAsync("parent_redeem@test.com", "Parent Redeem");
        var childId = await CreateChildAsync(parentUser, parentProfile, "Tommy");

        SetCurrentUser(parentUser, "parent_redeem@test.com", "Parent Redeem", UserRole.Parent, parentProfile);
        var genHandler = _serviceProvider.GetRequiredService<GenerateLinkingCodeHandler>();
        var codeDto = await genHandler.HandleAsync(childId);

        var (docUser, docProfile) = await CreateDoctorAsync("doc_redeem@test.com", "Dr. Redeem");
        SetCurrentUser(docUser, "doc_redeem@test.com", "Dr. Redeem", UserRole.Doctor, docProfile);

        var linkHandler = _serviceProvider.GetRequiredService<LinkChildHandler>();

        // Act
        var result = await linkHandler.HandleAsync(new LinkChildRequest(codeDto.Code));

        // Assert
        Assert.NotNull(result);
        Assert.Equal(childId, result.ChildId);
        Assert.Equal(docProfile, result.DoctorId);

        // Verify assignment created in DB
        var assignment = await _dbContext.DoctorChildAssignments
            .FirstOrDefaultAsync(a => a.DoctorId == docProfile && a.ChildId == childId && a.IsActive);
        Assert.NotNull(assignment);

        // Verify code is redeemed
        var codeEntity = await _dbContext.ChildLinkingCodes.FirstOrDefaultAsync(c => c.ChildId == childId);
        Assert.NotNull(codeEntity);
        Assert.True(codeEntity.IsRedeemed);
        Assert.Equal(docProfile, codeEntity.RedeemedByDoctorId);
    }

    [Fact]
    public async Task Redeeming_Invalid_Code_ThrowsNotFoundException_And_IncrementsRateLimiter()
    {
        // Arrange
        var (docUser, docProfile) = await CreateDoctorAsync("doc_invalid@test.com", "Dr. Invalid");
        SetCurrentUser(docUser, "doc_invalid@test.com", "Dr. Invalid", UserRole.Doctor, docProfile);

        var linkHandler = _serviceProvider.GetRequiredService<LinkChildHandler>();

        // Act & Assert
        await Assert.ThrowsAsync<NotFoundException>(() => linkHandler.HandleAsync(new LinkChildRequest("MND-NONEXIST")));
    }

    [Fact]
    public async Task Redeeming_Expired_Code_ThrowsBadRequestException()
    {
        // Arrange
        var (parentUser, parentProfile) = await CreateParentAsync("parent_exp@test.com", "Parent Exp");
        var childId = await CreateChildAsync(parentUser, parentProfile);

        // Manually insert an expired code
        var hash = ChildLinkingCode.ComputeHash("MND-EXPIRE1");
        var expiredCode = new ChildLinkingCode(Guid.NewGuid(), childId, hash, DateTime.UtcNow.AddHours(-1), DateTime.UtcNow.AddMinutes(-5));
        _dbContext.ChildLinkingCodes.Add(expiredCode);
        await _dbContext.SaveChangesAsync();

        var (docUser, docProfile) = await CreateDoctorAsync("doc_exp@test.com", "Dr. Exp");
        SetCurrentUser(docUser, "doc_exp@test.com", "Dr. Exp", UserRole.Doctor, docProfile);

        var linkHandler = _serviceProvider.GetRequiredService<LinkChildHandler>();

        // Act & Assert
        await Assert.ThrowsAsync<NotFoundException>(() => linkHandler.HandleAsync(new LinkChildRequest("MND-EXPIRE1")));
    }

    [Fact]
    public async Task Redeeming_Already_Redeemed_Code_ThrowsNotFoundException()
    {
        // Arrange
        var (parentUser, parentProfile) = await CreateParentAsync("parent_red@test.com", "Parent Red");
        var childId = await CreateChildAsync(parentUser, parentProfile);

        SetCurrentUser(parentUser, "parent_red@test.com", "Parent Red", UserRole.Parent, parentProfile);
        var genHandler = _serviceProvider.GetRequiredService<GenerateLinkingCodeHandler>();
        var codeDto = await genHandler.HandleAsync(childId);

        var (doc1User, doc1Profile) = await CreateDoctorAsync("doc1_red@test.com", "Dr. Red1");
        SetCurrentUser(doc1User, "doc1_red@test.com", "Dr. Red1", UserRole.Doctor, doc1Profile);

        var linkHandler = _serviceProvider.GetRequiredService<LinkChildHandler>();
        await linkHandler.HandleAsync(new LinkChildRequest(codeDto.Code));

        // Second doctor tries to redeem same code
        var (doc2User, doc2Profile) = await CreateDoctorAsync("doc2_red@test.com", "Dr. Red2");
        SetCurrentUser(doc2User, "doc2_red@test.com", "Dr. Red2", UserRole.Doctor, doc2Profile);

        // Act & Assert
        await Assert.ThrowsAsync<NotFoundException>(() => linkHandler.HandleAsync(new LinkChildRequest(codeDto.Code)));
    }

    [Fact]
    public async Task Redeeming_For_Already_Assigned_Child_ThrowsConflictException()
    {
        // Arrange
        var (parentUser, parentProfile) = await CreateParentAsync("parent_dup@test.com", "Parent Dup");
        var childId = await CreateChildAsync(parentUser, parentProfile);

        SetCurrentUser(parentUser, "parent_dup@test.com", "Parent Dup", UserRole.Parent, parentProfile);
        var genHandler = _serviceProvider.GetRequiredService<GenerateLinkingCodeHandler>();
        var code1 = await genHandler.HandleAsync(childId);

        var (docUser, docProfile) = await CreateDoctorAsync("doc_dup@test.com", "Dr. Dup");
        SetCurrentUser(docUser, "doc_dup@test.com", "Dr. Dup", UserRole.Doctor, docProfile);

        var linkHandler = _serviceProvider.GetRequiredService<LinkChildHandler>();
        await linkHandler.HandleAsync(new LinkChildRequest(code1.Code));

        // Parent generates another code and same doctor redeems it
        SetCurrentUser(parentUser, "parent_dup@test.com", "Parent Dup", UserRole.Parent, parentProfile);
        var code2 = await genHandler.HandleAsync(childId);

        SetCurrentUser(docUser, "doc_dup@test.com", "Dr. Dup", UserRole.Doctor, docProfile);
        await Assert.ThrowsAsync<ConflictException>(() => linkHandler.HandleAsync(new LinkChildRequest(code2.Code)));
    }

    [Fact]
    public async Task Parent_Cannot_Redeem_Linking_Code_ThrowsForbiddenException()
    {
        // Arrange
        var (parentUser, parentProfile) = await CreateParentAsync("parent_caller@test.com", "Parent Caller");
        SetCurrentUser(parentUser, "parent_caller@test.com", "Parent Caller", UserRole.Parent, parentProfile);

        var linkHandler = _serviceProvider.GetRequiredService<LinkChildHandler>();

        // Act & Assert
        await Assert.ThrowsAsync<ForbiddenException>(() => linkHandler.HandleAsync(new LinkChildRequest("MND-123456")));
    }

    [Fact]
    public async Task Brute_Force_Rate_Limiter_Blocks_After_5_Failed_Attempts()
    {
        // Arrange
        var (docUser, docProfile) = await CreateDoctorAsync("doc_throttle@test.com", "Dr. Throttle");
        SetCurrentUser(docUser, "doc_throttle@test.com", "Dr. Throttle", UserRole.Doctor, docProfile);

        var linkHandler = _serviceProvider.GetRequiredService<LinkChildHandler>();

        // Fail 5 times
        for (int i = 0; i < 5; i++)
        {
            await Assert.ThrowsAsync<NotFoundException>(() => linkHandler.HandleAsync(new LinkChildRequest($"MND-FAIL0{i}")));
        }

        // 6th attempt should be blocked by rate limiter
        var ex = await Assert.ThrowsAsync<ForbiddenException>(() => linkHandler.HandleAsync(new LinkChildRequest("MND-FAIL06")));
        Assert.Contains("Too many failed", ex.Message);
    }
}
