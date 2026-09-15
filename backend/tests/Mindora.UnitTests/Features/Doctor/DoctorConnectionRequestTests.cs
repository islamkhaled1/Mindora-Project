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
using Mindora.Application.Features.Children.LinkDoctor;
using Mindora.Application.Features.Doctor.ConnectionRequests;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;
using Mindora.Infrastructure.Identity;
using Mindora.Infrastructure.Persistence;
using Mindora.Infrastructure.Services;
using Xunit;

namespace Mindora.UnitTests.Features.Doctor;

public class DoctorConnectionRequestTests : IDisposable
{
    private readonly ServiceProvider _serviceProvider;
    private readonly ApplicationDbContext _dbContext;
    private readonly IHttpContextAccessor _httpContextAccessor;

    public DoctorConnectionRequestTests()
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
        var principal = new ClaimsPrincipal(identity);
        _httpContextAccessor.HttpContext = new DefaultHttpContext { User = principal };
    }

    private async Task<(Guid UserId, Guid ProfileId)> CreateParentAsync(string email, string fullName)
    {
        var registerHandler = _serviceProvider.GetRequiredService<RegisterParentHandler>();
        var result = await registerHandler.HandleAsync(new RegisterParentRequest(email, "Password123!", fullName, null));
        return (result.User.Id, result.User.ProfileId);
    }

    private async Task<(Guid UserId, Guid ProfileId)> CreateDoctorAsync(string email, string fullName)
    {
        var registerHandler = _serviceProvider.GetRequiredService<RegisterDoctorHandler>();
        var result = await registerHandler.HandleAsync(new RegisterDoctorRequest(
            email, "Password123!", fullName, "Pediatrics", "Mindora Clinic", "LIC-CONN-01", "Female"));
        return (result.User.Id, result.User.ProfileId);
    }

    [Fact]
    public async Task Parent_Submit_DoctorCode_Creates_Pending_Request_Without_Direct_Assignment()
    {
        // Arrange
        var (parentId, parentProfileId) = await CreateParentAsync("parent_req@test.com", "Parent Test");
        var (doctorId, doctorProfileId) = await CreateDoctorAsync("doc_req@test.com", "Dr. Hoda");

        var doctorProfile = await _dbContext.DoctorProfiles.FirstAsync(d => d.Id == doctorProfileId);
        var referralCode = doctorProfile.ReferralCode;

        SetCurrentUser(parentId, "parent_req@test.com", "Parent Test", UserRole.Parent, parentProfileId);
        var createChildHandler = _serviceProvider.GetRequiredService<CreateChildHandler>();
        var child = await createChildHandler.HandleAsync(new CreateChildRequest("Ziad", new DateOnly(2019, 5, 12), null, DifficultyLevel.Beginner, DifficultyLevel.Beginner, DifficultyLevel.Beginner));

        // Act
        var linkHandler = _serviceProvider.GetRequiredService<LinkDoctorByCodeHandler>();
        var linkRequestDto = await linkHandler.HandleAsync(child.Id, new LinkDoctorByCodeRequest(referralCode));

        // Assert
        Assert.NotNull(linkRequestDto);
        Assert.Equal("Pending", linkRequestDto.Status);
        Assert.Equal(doctorProfileId, linkRequestDto.DoctorId);
        Assert.Equal(child.Id, linkRequestDto.ChildId);
        Assert.Equal(parentProfileId, linkRequestDto.ParentId);

        // Verify NO assignment was created
        var assignments = await _dbContext.DoctorChildAssignments
            .Where(a => a.DoctorId == doctorProfileId && a.ChildId == child.Id)
            .ToListAsync();
        Assert.Empty(assignments);
    }

    [Fact]
    public async Task Parent_Submit_Duplicate_Pending_Request_Throws_ConflictException()
    {
        // Arrange
        var (parentId, parentProfileId) = await CreateParentAsync("parent_dup@test.com", "Parent Dup");
        var (doctorId, doctorProfileId) = await CreateDoctorAsync("doc_dup@test.com", "Dr. Dup");

        var doctorProfile = await _dbContext.DoctorProfiles.FirstAsync(d => d.Id == doctorProfileId);
        var referralCode = doctorProfile.ReferralCode;

        SetCurrentUser(parentId, "parent_dup@test.com", "Parent Dup", UserRole.Parent, parentProfileId);
        var createChildHandler = _serviceProvider.GetRequiredService<CreateChildHandler>();
        var child = await createChildHandler.HandleAsync(new CreateChildRequest("Maya", new DateOnly(2020, 1, 1), null, DifficultyLevel.Beginner, DifficultyLevel.Beginner, DifficultyLevel.Beginner));

        var linkHandler = _serviceProvider.GetRequiredService<LinkDoctorByCodeHandler>();
        await linkHandler.HandleAsync(child.Id, new LinkDoctorByCodeRequest(referralCode));

        // Act & Assert
        var ex = await Assert.ThrowsAsync<ConflictException>(() =>
            linkHandler.HandleAsync(child.Id, new LinkDoctorByCodeRequest(referralCode)));
        Assert.Contains("pending connection request already exists", ex.Message);
    }

    [Fact]
    public async Task Parent_Submit_When_Already_Actively_Assigned_Throws_ConflictException()
    {
        // Arrange
        var (parentId, parentProfileId) = await CreateParentAsync("parent_linked@test.com", "Parent Linked");
        var (doctorId, doctorProfileId) = await CreateDoctorAsync("doc_linked@test.com", "Dr. Linked");

        var doctorProfile = await _dbContext.DoctorProfiles.FirstAsync(d => d.Id == doctorProfileId);
        var referralCode = doctorProfile.ReferralCode;

        SetCurrentUser(parentId, "parent_linked@test.com", "Parent Linked", UserRole.Parent, parentProfileId);
        var createChildHandler = _serviceProvider.GetRequiredService<CreateChildHandler>();
        var child = await createChildHandler.HandleAsync(new CreateChildRequest("Omar", new DateOnly(2018, 3, 10), null, DifficultyLevel.Beginner, DifficultyLevel.Beginner, DifficultyLevel.Beginner));

        // Manually seed an active assignment
        _dbContext.Add(DoctorChildAssignment.Create(doctorProfileId, child.Id));
        await _dbContext.SaveChangesAsync();

        var linkHandler = _serviceProvider.GetRequiredService<LinkDoctorByCodeHandler>();

        // Act & Assert
        var ex = await Assert.ThrowsAsync<ConflictException>(() =>
            linkHandler.HandleAsync(child.Id, new LinkDoctorByCodeRequest(referralCode)));
        Assert.Contains("already actively assigned", ex.Message);
    }

    [Fact]
    public async Task Doctor_Approve_Atomically_Sets_Approved_And_Creates_Assignment()
    {
        // Arrange
        var (parentId, parentProfileId) = await CreateParentAsync("parent_approve@test.com", "Parent Approve");
        var (doctorId, doctorProfileId) = await CreateDoctorAsync("doc_approve@test.com", "Dr. Approver");

        var doctorProfile = await _dbContext.DoctorProfiles.FirstAsync(d => d.Id == doctorProfileId);
        var referralCode = doctorProfile.ReferralCode;

        SetCurrentUser(parentId, "parent_approve@test.com", "Parent Approve", UserRole.Parent, parentProfileId);
        var createChildHandler = _serviceProvider.GetRequiredService<CreateChildHandler>();
        var child = await createChildHandler.HandleAsync(new CreateChildRequest("Farah", new DateOnly(2021, 6, 1), null, DifficultyLevel.Beginner, DifficultyLevel.Beginner, DifficultyLevel.Beginner));

        var linkHandler = _serviceProvider.GetRequiredService<LinkDoctorByCodeHandler>();
        var req = await linkHandler.HandleAsync(child.Id, new LinkDoctorByCodeRequest(referralCode));

        // Act: Doctor approves the request
        SetCurrentUser(doctorId, "doc_approve@test.com", "Dr. Approver", UserRole.Doctor, doctorProfileId);
        var approveHandler = _serviceProvider.GetRequiredService<ApproveDoctorLinkRequestHandler>();
        await approveHandler.HandleAsync(req.Id);

        // Assert: Request status is Approved
        var updatedReq = await _dbContext.DoctorLinkRequests.FirstAsync(r => r.Id == req.Id);
        Assert.Equal(DoctorLinkRequestStatus.Approved, updatedReq.Status);
        Assert.NotNull(updatedReq.RespondedAtUtc);

        // Assert: DoctorChildAssignment now exists and is active
        var assignment = await _dbContext.DoctorChildAssignments
            .FirstOrDefaultAsync(a => a.DoctorId == doctorProfileId && a.ChildId == child.Id);
        Assert.NotNull(assignment);
        Assert.True(assignment.IsActive);
    }

    [Fact]
    public async Task Doctor_Reject_Marks_Rejected_And_Creates_No_Assignment()
    {
        // Arrange
        var (parentId, parentProfileId) = await CreateParentAsync("parent_reject@test.com", "Parent Reject");
        var (doctorId, doctorProfileId) = await CreateDoctorAsync("doc_reject@test.com", "Dr. Rejector");

        var doctorProfile = await _dbContext.DoctorProfiles.FirstAsync(d => d.Id == doctorProfileId);
        var referralCode = doctorProfile.ReferralCode;

        SetCurrentUser(parentId, "parent_reject@test.com", "Parent Reject", UserRole.Parent, parentProfileId);
        var createChildHandler = _serviceProvider.GetRequiredService<CreateChildHandler>();
        var child = await createChildHandler.HandleAsync(new CreateChildRequest("Adam", new DateOnly(2020, 9, 15), null, DifficultyLevel.Beginner, DifficultyLevel.Beginner, DifficultyLevel.Beginner));

        var linkHandler = _serviceProvider.GetRequiredService<LinkDoctorByCodeHandler>();
        var req = await linkHandler.HandleAsync(child.Id, new LinkDoctorByCodeRequest(referralCode));

        // Act: Doctor rejects
        SetCurrentUser(doctorId, "doc_reject@test.com", "Dr. Rejector", UserRole.Doctor, doctorProfileId);
        var rejectHandler = _serviceProvider.GetRequiredService<RejectDoctorLinkRequestHandler>();
        await rejectHandler.HandleAsync(req.Id);

        // Assert: Request is Rejected
        var updatedReq = await _dbContext.DoctorLinkRequests.FirstAsync(r => r.Id == req.Id);
        Assert.Equal(DoctorLinkRequestStatus.Rejected, updatedReq.Status);
        Assert.NotNull(updatedReq.RespondedAtUtc);

        // Assert: NO DoctorChildAssignment exists
        var assignment = await _dbContext.DoctorChildAssignments
            .FirstOrDefaultAsync(a => a.DoctorId == doctorProfileId && a.ChildId == child.Id);
        Assert.Null(assignment);
    }

    [Fact]
    public async Task Unauthorized_Doctor_Cannot_Approve_Another_Doctors_Request()
    {
        // Arrange: 2 Doctors
        var (parentId, parentProfileId) = await CreateParentAsync("parent_sec@test.com", "Parent Sec");
        var (doctor1Id, doctor1ProfileId) = await CreateDoctorAsync("doc1@test.com", "Dr. Target");
        var (doctor2Id, doctor2ProfileId) = await CreateDoctorAsync("doc2@test.com", "Dr. Intruder");

        var doctor1 = await _dbContext.DoctorProfiles.FirstAsync(d => d.Id == doctor1ProfileId);

        SetCurrentUser(parentId, "parent_sec@test.com", "Parent Sec", UserRole.Parent, parentProfileId);
        var createChildHandler = _serviceProvider.GetRequiredService<CreateChildHandler>();
        var child = await createChildHandler.HandleAsync(new CreateChildRequest("Salma", new DateOnly(2020, 2, 2), null, DifficultyLevel.Beginner, DifficultyLevel.Beginner, DifficultyLevel.Beginner));

        var linkHandler = _serviceProvider.GetRequiredService<LinkDoctorByCodeHandler>();
        var req = await linkHandler.HandleAsync(child.Id, new LinkDoctorByCodeRequest(doctor1.ReferralCode));

        // Act & Assert: Doctor 2 tries to approve Doctor 1's request
        SetCurrentUser(doctor2Id, "doc2@test.com", "Dr. Intruder", UserRole.Doctor, doctor2ProfileId);
        var approveHandler = _serviceProvider.GetRequiredService<ApproveDoctorLinkRequestHandler>();

        await Assert.ThrowsAsync<ForbiddenException>(() => approveHandler.HandleAsync(req.Id));
    }

    [Fact]
    public async Task Parent_Cannot_Approve_Or_Reject_Request()
    {
        // Arrange
        var (parentId, parentProfileId) = await CreateParentAsync("parent_noperm@test.com", "Parent NoPerm");
        var (doctorId, doctorProfileId) = await CreateDoctorAsync("doc_perm@test.com", "Dr. Perm");

        var doctorProfile = await _dbContext.DoctorProfiles.FirstAsync(d => d.Id == doctorProfileId);

        SetCurrentUser(parentId, "parent_noperm@test.com", "Parent NoPerm", UserRole.Parent, parentProfileId);
        var createChildHandler = _serviceProvider.GetRequiredService<CreateChildHandler>();
        var child = await createChildHandler.HandleAsync(new CreateChildRequest("Nour", new DateOnly(2019, 11, 1), null, DifficultyLevel.Beginner, DifficultyLevel.Beginner, DifficultyLevel.Beginner));

        var linkHandler = _serviceProvider.GetRequiredService<LinkDoctorByCodeHandler>();
        var req = await linkHandler.HandleAsync(child.Id, new LinkDoctorByCodeRequest(doctorProfile.ReferralCode));

        // Act & Assert: Parent tries to approve
        var approveHandler = _serviceProvider.GetRequiredService<ApproveDoctorLinkRequestHandler>();
        await Assert.ThrowsAsync<ForbiddenException>(() => approveHandler.HandleAsync(req.Id));

        var rejectHandler = _serviceProvider.GetRequiredService<RejectDoctorLinkRequestHandler>();
        await Assert.ThrowsAsync<ForbiddenException>(() => rejectHandler.HandleAsync(req.Id));
    }

    [Fact]
    public async Task Doctor_GetLinkRequests_Returns_Pending_Requests_With_Child_And_Parent_Info()
    {
        // Arrange
        var (parentId, parentProfileId) = await CreateParentAsync("parent_queue@test.com", "Ahmed El-Sayed");
        var (doctorId, doctorProfileId) = await CreateDoctorAsync("doc_queue@test.com", "Dr. Mona");

        var doctorProfile = await _dbContext.DoctorProfiles.FirstAsync(d => d.Id == doctorProfileId);

        SetCurrentUser(parentId, "parent_queue@test.com", "Ahmed El-Sayed", UserRole.Parent, parentProfileId);
        var createChildHandler = _serviceProvider.GetRequiredService<CreateChildHandler>();
        var child = await createChildHandler.HandleAsync(new CreateChildRequest("Youssef", new DateOnly(2019, 4, 1), null, DifficultyLevel.Beginner, DifficultyLevel.Beginner, DifficultyLevel.Beginner));

        var linkHandler = _serviceProvider.GetRequiredService<LinkDoctorByCodeHandler>();
        await linkHandler.HandleAsync(child.Id, new LinkDoctorByCodeRequest(doctorProfile.ReferralCode));

        // Act: Doctor retrieves pending requests
        SetCurrentUser(doctorId, "doc_queue@test.com", "Dr. Mona", UserRole.Doctor, doctorProfileId);
        var getRequestsHandler = _serviceProvider.GetRequiredService<GetDoctorLinkRequestsHandler>();
        var requests = await getRequestsHandler.HandleAsync(DoctorLinkRequestStatus.Pending);

        // Assert
        Assert.Single(requests);
        var item = requests[0];
        Assert.Equal(child.Id, item.ChildId);
        Assert.Equal("Youssef", item.ChildName);
        Assert.Equal("Ahmed El-Sayed", item.ParentName);
        Assert.Equal("Pending", item.Status);
    }

    [Theory]
    [InlineData("Male", true)]
    [InlineData("Female", true)]
    [InlineData("male", true)]
    [InlineData("female", true)]
    [InlineData("Other", false)]
    [InlineData("other", false)]
    [InlineData("Random", false)]
    public void Doctor_Registration_Validator_Accepts_Only_Male_And_Female(string genderInput, bool shouldBeValid)
    {
        var validator = new RegisterDoctorValidator();
        var request = new RegisterDoctorRequest(
            "doc_val@test.com", "Password123!", "Dr. Test", "Pediatrics", "Clinic", "LIC-123", genderInput);

        var result = validator.Validate(request);
        Assert.Equal(shouldBeValid, result.IsValid);
    }
}
