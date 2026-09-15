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
using Mindora.Application.Features.Children.AssignDoctor;
using Mindora.Application.Features.Children.CreateChild;
using Mindora.Application.Features.Children.GetChildDetails;
using Mindora.Application.Features.Children.GetParentChildren;
using Mindora.Application.Features.Children.LinkDoctor;
using Mindora.Application.Features.Children.SoftDeleteChild;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;
using Mindora.Infrastructure.Identity;
using Mindora.Infrastructure.Persistence;
using Mindora.Infrastructure.Services;
using Xunit;

namespace Mindora.UnitTests.Features.Children;

public class ChildrenFeatureTests : IDisposable
{
    private readonly ServiceProvider _serviceProvider;
    private readonly ApplicationDbContext _dbContext;
    private readonly IHttpContextAccessor _httpContextAccessor;

    public ChildrenFeatureTests()
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

    [Fact]
    public async Task Parent_Can_Create_Own_Child_And_Is_Linked_To_Authenticated_Parent()
    {
        // Arrange
        var (parentId, profileId) = await CreateParentAsync("parent_create@test.com", "Parent Create");
        SetCurrentUser(parentId, "parent_create@test.com", "Parent Create", UserRole.Parent, profileId);

        var handler = _serviceProvider.GetRequiredService<CreateChildHandler>();
        var request = new CreateChildRequest(
            "Leo Miller",
            new DateOnly(2018, 5, 20),
            "Sensory sensitivity",
            DifficultyLevel.Beginner,
            DifficultyLevel.Beginner,
            DifficultyLevel.Intermediate);

        // Act
        var childDto = await handler.HandleAsync(request);

        // Assert
        Assert.NotNull(childDto);
        Assert.Equal("Leo Miller", childDto.FullName);
        Assert.Equal(profileId, childDto.ParentId);
        Assert.Equal("Beginner", childDto.CurrentMovementLevel);
        Assert.Equal("Beginner", childDto.CurrentSpeechLevel);
        Assert.Equal("Intermediate", childDto.CurrentAttentionLevel);

        var savedChild = _dbContext.Children.FirstOrDefault(c => c.Id == childDto.Id);
        Assert.NotNull(savedChild);
        Assert.Equal(profileId, savedChild.ParentId);
    }

    [Fact]
    public async Task Doctor_Cannot_Create_Child()
    {
        // Arrange
        var (doctorId, profileId) = await CreateDoctorAsync("doc_create@test.com", "Doctor Create");
        SetCurrentUser(doctorId, "doc_create@test.com", "Doctor Create", UserRole.Doctor, profileId);

        var handler = _serviceProvider.GetRequiredService<CreateChildHandler>();
        var request = new CreateChildRequest(
            "Test Child",
            new DateOnly(2019, 1, 1),
            null,
            DifficultyLevel.Beginner,
            DifficultyLevel.Beginner,
            DifficultyLevel.Beginner);

        // Act & Assert
        await Assert.ThrowsAsync<ForbiddenException>(() => handler.HandleAsync(request));
    }

    [Fact]
    public async Task Parent_Can_List_Own_Children_Only()
    {
        // Arrange
        var (parentAId, profileAId) = await CreateParentAsync("parent_a@test.com", "Parent A");
        var (parentBId, profileBId) = await CreateParentAsync("parent_b@test.com", "Parent B");

        // Parent A creates child A
        SetCurrentUser(parentAId, "parent_a@test.com", "Parent A", UserRole.Parent, profileAId);
        var createHandler = _serviceProvider.GetRequiredService<CreateChildHandler>();
        await createHandler.HandleAsync(new CreateChildRequest("Child A", new DateOnly(2018, 1, 1), null, DifficultyLevel.Beginner, DifficultyLevel.Beginner, DifficultyLevel.Beginner));

        // Parent B creates child B
        SetCurrentUser(parentBId, "parent_b@test.com", "Parent B", UserRole.Parent, profileBId);
        await createHandler.HandleAsync(new CreateChildRequest("Child B", new DateOnly(2019, 2, 2), null, DifficultyLevel.Beginner, DifficultyLevel.Beginner, DifficultyLevel.Beginner));

        // Act as Parent A
        SetCurrentUser(parentAId, "parent_a@test.com", "Parent A", UserRole.Parent, profileAId);
        var getChildrenHandler = _serviceProvider.GetRequiredService<GetParentChildrenHandler>();
        var listA = await getChildrenHandler.HandleAsync();

        // Assert
        Assert.Single(listA);
        Assert.Equal("Child A", listA[0].FullName);
    }

    [Fact]
    public async Task Parent_Can_View_Own_Child_Details()
    {
        // Arrange
        var (parentId, profileId) = await CreateParentAsync("parent_view@test.com", "Parent View");
        SetCurrentUser(parentId, "parent_view@test.com", "Parent View", UserRole.Parent, profileId);

        var createHandler = _serviceProvider.GetRequiredService<CreateChildHandler>();
        var childDto = await createHandler.HandleAsync(new CreateChildRequest(
            "Child View", new DateOnly(2017, 3, 15), "Notes", DifficultyLevel.Beginner, DifficultyLevel.Intermediate, DifficultyLevel.Advanced));

        var getDetailsHandler = _serviceProvider.GetRequiredService<GetChildDetailsHandler>();

        // Act
        var details = await getDetailsHandler.HandleAsync(childDto.Id);

        // Assert
        Assert.NotNull(details);
        Assert.Equal(childDto.Id, details.Id);
        Assert.Equal("Child View", details.FullName);
        Assert.Equal(profileId, details.ParentId);
    }

    [Fact]
    public async Task Parent_Cannot_View_Another_Parents_Child_Fails_Safely()
    {
        // Arrange
        var (parentAId, profileAId) = await CreateParentAsync("parent_view_a@test.com", "Parent A");
        var (parentBId, profileBId) = await CreateParentAsync("parent_view_b@test.com", "Parent B");

        // Parent B creates child
        SetCurrentUser(parentBId, "parent_view_b@test.com", "Parent B", UserRole.Parent, profileBId);
        var createHandler = _serviceProvider.GetRequiredService<CreateChildHandler>();
        var childB = await createHandler.HandleAsync(new CreateChildRequest("Child B Secret", new DateOnly(2018, 1, 1), null, DifficultyLevel.Beginner, DifficultyLevel.Beginner, DifficultyLevel.Beginner));

        // Parent A attempts to view Child B
        SetCurrentUser(parentAId, "parent_view_a@test.com", "Parent A", UserRole.Parent, profileAId);
        var getDetailsHandler = _serviceProvider.GetRequiredService<GetChildDetailsHandler>();

        // Act & Assert (Must throw NotFoundException to prevent IDOR disclosure)
        await Assert.ThrowsAsync<NotFoundException>(() => getDetailsHandler.HandleAsync(childB.Id));
    }

    [Fact]
    public async Task Assigned_Doctor_Can_View_Child_Details()
    {
        // Arrange
        var (parentId, parentProfileId) = await CreateParentAsync("parent_assign@test.com", "Parent Assign");
        var (doctorId, doctorProfileId) = await CreateDoctorAsync("doc_assigned@test.com", "Dr. Assigned");

        // Parent creates child
        SetCurrentUser(parentId, "parent_assign@test.com", "Parent Assign", UserRole.Parent, parentProfileId);
        var createHandler = _serviceProvider.GetRequiredService<CreateChildHandler>();
        var child = await createHandler.HandleAsync(new CreateChildRequest("Child Clinical", new DateOnly(2018, 4, 1), null, DifficultyLevel.Beginner, DifficultyLevel.Beginner, DifficultyLevel.Beginner));

        // Parent assigns doctor
        var assignHandler = _serviceProvider.GetRequiredService<AssignDoctorHandler>();
        await assignHandler.HandleAsync(child.Id, new AssignDoctorRequest(doctorProfileId));

        // Act as Doctor
        SetCurrentUser(doctorId, "doc_assigned@test.com", "Dr. Assigned", UserRole.Doctor, doctorProfileId);
        var getDetailsHandler = _serviceProvider.GetRequiredService<GetChildDetailsHandler>();
        var details = await getDetailsHandler.HandleAsync(child.Id);

        // Assert
        Assert.NotNull(details);
        Assert.Equal(child.Id, details.Id);
        Assert.Single(details.AssignedDoctors);
        Assert.Equal(doctorProfileId, details.AssignedDoctors[0].DoctorId);
    }

    [Fact]
    public async Task Unassigned_Doctor_Cannot_View_Child_Fails_Safely()
    {
        // Arrange
        var (parentId, parentProfileId) = await CreateParentAsync("parent_unassign@test.com", "Parent Unassign");
        var (doctorId, doctorProfileId) = await CreateDoctorAsync("doc_unassigned@test.com", "Dr. Unassigned");

        // Parent creates child
        SetCurrentUser(parentId, "parent_unassign@test.com", "Parent Unassign", UserRole.Parent, parentProfileId);
        var createHandler = _serviceProvider.GetRequiredService<CreateChildHandler>();
        var child = await createHandler.HandleAsync(new CreateChildRequest("Child Private", new DateOnly(2018, 4, 1), null, DifficultyLevel.Beginner, DifficultyLevel.Beginner, DifficultyLevel.Beginner));

        // Act as unassigned Doctor
        SetCurrentUser(doctorId, "doc_unassigned@test.com", "Dr. Unassigned", UserRole.Doctor, doctorProfileId);
        var getDetailsHandler = _serviceProvider.GetRequiredService<GetChildDetailsHandler>();

        // Act & Assert (Must throw NotFoundException to prevent IDOR disclosure)
        await Assert.ThrowsAsync<NotFoundException>(() => getDetailsHandler.HandleAsync(child.Id));
    }

    [Fact]
    public async Task SoftDelete_Hides_Child_From_Parent_And_Doctor_Queries()
    {
        // Arrange
        var (parentId, parentProfileId) = await CreateParentAsync("parent_delete@test.com", "Parent Delete");
        var (doctorId, doctorProfileId) = await CreateDoctorAsync("doc_delete@test.com", "Dr. Delete");

        SetCurrentUser(parentId, "parent_delete@test.com", "Parent Delete", UserRole.Parent, parentProfileId);
        var createHandler = _serviceProvider.GetRequiredService<CreateChildHandler>();
        var child = await createHandler.HandleAsync(new CreateChildRequest("Child To Delete", new DateOnly(2018, 4, 1), null, DifficultyLevel.Beginner, DifficultyLevel.Beginner, DifficultyLevel.Beginner));

        var assignHandler = _serviceProvider.GetRequiredService<AssignDoctorHandler>();
        await assignHandler.HandleAsync(child.Id, new AssignDoctorRequest(doctorProfileId));

        // Soft delete child as Parent
        var deleteHandler = _serviceProvider.GetRequiredService<SoftDeleteChildHandler>();
        await deleteHandler.HandleAsync(child.Id);

        // Assert 1: Parent cannot list soft-deleted child
        var getChildrenHandler = _serviceProvider.GetRequiredService<GetParentChildrenHandler>();
        var list = await getChildrenHandler.HandleAsync();
        Assert.DoesNotContain(list, c => c.Id == child.Id);

        // Assert 2: Parent cannot view soft-deleted child
        var getDetailsHandler = _serviceProvider.GetRequiredService<GetChildDetailsHandler>();
        await Assert.ThrowsAsync<NotFoundException>(() => getDetailsHandler.HandleAsync(child.Id));

        // Assert 3: Doctor cannot view soft-deleted child
        SetCurrentUser(doctorId, "doc_delete@test.com", "Dr. Delete", UserRole.Doctor, doctorProfileId);
        await Assert.ThrowsAsync<NotFoundException>(() => getDetailsHandler.HandleAsync(child.Id));

        // Assert 4: Physical record still exists in database with IsDeleted = true
        var rawChild = _dbContext.Children.IgnoreQueryFilters().FirstOrDefault(c => c.Id == child.Id);
        Assert.NotNull(rawChild);
        Assert.True(rawChild.IsDeleted);

        // Assert 5: DoctorChildAssignment history is preserved
        var assignment = _dbContext.DoctorChildAssignments.FirstOrDefault(a => a.ChildId == child.Id);
        Assert.NotNull(assignment);
        Assert.True(assignment.IsActive);
    }

    [Fact]
    public async Task Duplicate_Active_Doctor_Assignment_Is_Prevented()
    {
        // Arrange
        var (parentId, parentProfileId) = await CreateParentAsync("parent_dup_assign@test.com", "Parent Dup");
        var (_, doctorProfileId) = await CreateDoctorAsync("doc_dup@test.com", "Dr. Dup");

        SetCurrentUser(parentId, "parent_dup_assign@test.com", "Parent Dup", UserRole.Parent, parentProfileId);
        var createHandler = _serviceProvider.GetRequiredService<CreateChildHandler>();
        var child = await createHandler.HandleAsync(new CreateChildRequest("Child Dup Assign", new DateOnly(2018, 4, 1), null, DifficultyLevel.Beginner, DifficultyLevel.Beginner, DifficultyLevel.Beginner));

        var assignHandler = _serviceProvider.GetRequiredService<AssignDoctorHandler>();
        await assignHandler.HandleAsync(child.Id, new AssignDoctorRequest(doctorProfileId));

        // Act & Assert: Duplicate active assignment must throw ConflictException
        await Assert.ThrowsAsync<ConflictException>(() =>
            assignHandler.HandleAsync(child.Id, new AssignDoctorRequest(doctorProfileId)));
    }

    [Fact]
    public async Task Invalid_Child_Input_Fails_Validation()
    {
        // Arrange
        var validator = _serviceProvider.GetRequiredService<IValidator<CreateChildRequest>>();
        var futureDate = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(10));
        var request = new CreateChildRequest("", futureDate, null, (DifficultyLevel)999, DifficultyLevel.Beginner, DifficultyLevel.Beginner);

        // Act
        var result = await validator.ValidateAsync(request);

        // Assert
        Assert.False(result.IsValid);
        Assert.Contains(result.Errors, e => e.PropertyName == "FullName");
        Assert.Contains(result.Errors, e => e.PropertyName == "DateOfBirth");
        Assert.Contains(result.Errors, e => e.PropertyName == "BaselineMovementLevel");
    }

    [Fact]
    public async Task Parent_Cannot_Delete_Another_Parents_Child()
    {
        // Arrange
        var (parentAId, profileAId) = await CreateParentAsync("parent_del_a@test.com", "Parent A");
        var (parentBId, profileBId) = await CreateParentAsync("parent_del_b@test.com", "Parent B");

        // Parent B creates child
        SetCurrentUser(parentBId, "parent_del_b@test.com", "Parent B", UserRole.Parent, profileBId);
        var createHandler = _serviceProvider.GetRequiredService<CreateChildHandler>();
        var childB = await createHandler.HandleAsync(new CreateChildRequest("Child B Protected", new DateOnly(2018, 1, 1), null, DifficultyLevel.Beginner, DifficultyLevel.Beginner, DifficultyLevel.Beginner));

        // Parent A attempts to delete Child B
        SetCurrentUser(parentAId, "parent_del_a@test.com", "Parent A", UserRole.Parent, profileAId);
        var deleteHandler = _serviceProvider.GetRequiredService<SoftDeleteChildHandler>();

        // Act & Assert (Must throw NotFoundException to prevent IDOR disclosure)
        await Assert.ThrowsAsync<NotFoundException>(() => deleteHandler.HandleAsync(childB.Id));
    }

    [Fact]
    public async Task CreateChild_With_Extended_Profile_Fields_Succeeds_And_Returns_All_Fields()
    {
        // Arrange
        var (parentId, profileId) = await CreateParentAsync("parent_extended@test.com", "Parent Extended");
        SetCurrentUser(parentId, "parent_extended@test.com", "Parent Extended", UserRole.Parent, profileId);

        var handler = _serviceProvider.GetRequiredService<CreateChildHandler>();
        var request = new CreateChildRequest(
            FullName: "Sami Zaki",
            DateOfBirth: new DateOnly(2019, 5, 12),
            SupportNotes: "Responds to rhythmic visual prompts.",
            BaselineMovementLevel: DifficultyLevel.Intermediate,
            BaselineSpeechLevel: DifficultyLevel.Beginner,
            BaselineAttentionLevel: DifficultyLevel.Intermediate,
            Gender: Gender.Boy,
            Diagnosis: "Sensory Processing Sensitivity",
            AvatarUrl: "https://mindora.app/avatars/sami.png",
            SupportLevel: SupportLevel.Moderate,
            HearingStatus: SensoryStatus.Normal,
            VisionStatus: SensoryStatus.Normal,
            FocusDurationMinutes: 12,
            PreferredPracticeTime: "10:00 - 11:00 AM",
            PreferredActivityType: ActivityTypePreference.Games);

        // Act
        var result = await handler.HandleAsync(request);

        // Assert
        Assert.NotNull(result);
        Assert.Equal("Sami Zaki", result.FullName);
        Assert.Equal("Boy", result.Gender);
        Assert.Equal("Sensory Processing Sensitivity", result.Diagnosis);
        Assert.Equal("https://mindora.app/avatars/sami.png", result.AvatarUrl);
        Assert.Equal("Moderate", result.SupportLevel);
        Assert.Equal("Normal", result.HearingStatus);
        Assert.Equal("Normal", result.VisionStatus);
        Assert.Equal(12, result.FocusDurationMinutes);
        Assert.Equal("10:00 - 11:00 AM", result.PreferredPracticeTime);
        Assert.Equal("Games", result.PreferredActivityType);
    }

    [Fact]
    public async Task LinkDoctor_By_ReferralCode_Creates_Pending_Request_For_Owning_Parent()
    {
        // Arrange
        var (parentId, profileId) = await CreateParentAsync("parent_link_code@test.com", "Parent Linker");
        var (doctorId, doctorProfileId) = await CreateDoctorAsync("doc_specialist@test.com", "Dr. Zaki");

        // Doctor referral code lookup
        var doctorProfile = await _dbContext.DoctorProfiles.FirstAsync(d => d.Id == doctorProfileId);
        var referralCode = doctorProfile.ReferralCode;

        // Create child for parent
        SetCurrentUser(parentId, "parent_link_code@test.com", "Parent Linker", UserRole.Parent, profileId);
        var createChildHandler = _serviceProvider.GetRequiredService<CreateChildHandler>();
        var child = await createChildHandler.HandleAsync(new CreateChildRequest("Amir", new DateOnly(2020, 1, 1), null, DifficultyLevel.Beginner, DifficultyLevel.Beginner, DifficultyLevel.Beginner));

        // Act: Parent submits doctor code -> creates Pending request
        var linkHandler = _serviceProvider.GetRequiredService<LinkDoctorByCodeHandler>();
        var requestDto = await linkHandler.HandleAsync(child.Id, new LinkDoctorByCodeRequest(referralCode));

        // Assert: Pending request created, no immediate assignment
        Assert.NotNull(requestDto);
        Assert.Equal(doctorProfileId, requestDto.DoctorId);
        Assert.Equal(child.Id, requestDto.ChildId);
        Assert.Equal("Pending", requestDto.Status);
        Assert.Equal("Pediatrics", requestDto.Specialization);
        Assert.Equal("Mindora Clinic", requestDto.ClinicName);

        // Verify no active assignment was created before approval
        var assignments = await _dbContext.DoctorChildAssignments
            .Where(a => a.DoctorId == doctorProfileId && a.ChildId == child.Id)
            .ToListAsync();
        Assert.Empty(assignments);
    }

    [Fact]
    public async Task LinkDoctor_By_ReferralCode_With_Invalid_Code_Throws_NotFoundException()
    {
        // Arrange
        var (parentId, profileId) = await CreateParentAsync("parent_bad_code@test.com", "Parent BadCode");
        SetCurrentUser(parentId, "parent_bad_code@test.com", "Parent BadCode", UserRole.Parent, profileId);

        var createChildHandler = _serviceProvider.GetRequiredService<CreateChildHandler>();
        var child = await createChildHandler.HandleAsync(new CreateChildRequest("Yara", new DateOnly(2021, 2, 2), null, DifficultyLevel.Beginner, DifficultyLevel.Beginner, DifficultyLevel.Beginner));

        var linkHandler = _serviceProvider.GetRequiredService<LinkDoctorByCodeHandler>();

        // Act & Assert
        await Assert.ThrowsAsync<NotFoundException>(() =>
            linkHandler.HandleAsync(child.Id, new LinkDoctorByCodeRequest("DR-NONEXISTENT")));
    }
}
