using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Mindora.Application.Features.Activities.Models;
using Mindora.Application.Features.Auth.GetCurrentUser;
using Mindora.Application.Features.Auth.Login;
using Mindora.Application.Features.Auth.Models;
using Mindora.Application.Features.Auth.RegisterDoctor;
using Mindora.Application.Features.Auth.RegisterParent;
using Mindora.Application.Features.Children.AssignDoctor;
using Mindora.Application.Features.Children.CreateChild;
using Mindora.Application.Features.Children.Models;
using Mindora.Domain.Enums;
using Mindora.IntegrationTests.Infrastructure;
using Xunit;

namespace Mindora.IntegrationTests;

public class EndToEndFlowTests : IClassFixture<MindoraApiFactory>
{
    private readonly MindoraApiFactory _factory;

    public EndToEndFlowTests(MindoraApiFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task EndToEnd_ParentFlow_Register_Login_CreateChild_GetChild_ListChildren()
    {
        var client = _factory.CreateClient();

        // 1. Register Parent
        var registerRequest = new RegisterParentRequest(
            "e2e_parent@mindora.com",
            "SecurePass123!",
            "E2E Parent User",
            "+15551234567");

        var regResponse = await client.PostAsJsonAsync("/api/auth/register-parent", registerRequest);
        Assert.Equal(HttpStatusCode.Created, regResponse.StatusCode);
        var regResult = await regResponse.Content.ReadFromJsonAsync<AuthResponseDto>();
        Assert.NotNull(regResult);
        Assert.True(regResult.RequiresEmailVerification);
        Assert.Equal("e2e_parent@mindora.com", regResult.User!.Email);
        Assert.Equal("Parent", regResult.User.Role);

        // 2. Attempt login before email confirmation -> MUST BE REJECTED with 403 Forbidden
        var loginRequest = new LoginRequest("e2e_parent@mindora.com", "SecurePass123!");
        var unverifiedLogin = await client.PostAsJsonAsync("/api/auth/login", loginRequest);
        Assert.Equal(HttpStatusCode.Forbidden, unverifiedLogin.StatusCode);

        // Confirm email
        await _factory.ConfirmUserEmailAsync("e2e_parent@mindora.com");

        // 3. Login succeeds after email confirmation
        var loginResponse = await client.PostAsJsonAsync("/api/auth/login", loginRequest);
        Assert.Equal(HttpStatusCode.OK, loginResponse.StatusCode);
        var loginResult = await loginResponse.Content.ReadFromJsonAsync<AuthResponseDto>();
        Assert.NotNull(loginResult);
        Assert.NotNull(loginResult.Token);

        // Set Bearer Token for subsequent authenticated requests
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", loginResult.Token);

        // 4. Get Current User (/api/auth/me)
        var meResponse = await client.GetAsync("/api/auth/me");
        Assert.Equal(HttpStatusCode.OK, meResponse.StatusCode);
        var meResult = await meResponse.Content.ReadFromJsonAsync<CurrentUserDto>();
        Assert.NotNull(meResult);
        Assert.Equal("e2e_parent@mindora.com", meResult.Email);
        Assert.Equal("Parent", meResult.Role);

        // 5. Create Child
        var createChildRequest = new CreateChildRequest(
            "E2E Child",
            new DateOnly(2018, 6, 15),
            "E2E Testing notes",
            DifficultyLevel.Beginner,
            DifficultyLevel.Intermediate,
            DifficultyLevel.Beginner);

        var createResponse = await client.PostAsJsonAsync("/api/children", createChildRequest);
        Assert.Equal(HttpStatusCode.Created, createResponse.StatusCode);
        var createdChild = await createResponse.Content.ReadFromJsonAsync<ChildDto>();
        Assert.NotNull(createdChild);
        Assert.Equal("E2E Child", createdChild.FullName);
        Assert.NotEqual(Guid.Empty, createdChild.Id);

        // 6. Get Child Details (/api/children/{childId})
        var getChildResponse = await client.GetAsync($"/api/children/{createdChild.Id}");
        Assert.Equal(HttpStatusCode.OK, getChildResponse.StatusCode);
        var childDetails = await getChildResponse.Content.ReadFromJsonAsync<ChildDetailsDto>();
        Assert.NotNull(childDetails);
        Assert.Equal(createdChild.Id, childDetails.Id);
        Assert.Equal("E2E Child", childDetails.FullName);

        // 7. List Parent's Children (/api/children)
        var listResponse = await client.GetAsync("/api/children");
        Assert.Equal(HttpStatusCode.OK, listResponse.StatusCode);
        var childrenList = await listResponse.Content.ReadFromJsonAsync<List<ChildSummaryDto>>();
        Assert.NotNull(childrenList);
        Assert.Contains(childrenList, c => c.Id == createdChild.Id);

        // 8. Get Activities (/api/activities)
        var activitiesResponse = await client.GetAsync("/api/activities?domain=Movement");
        Assert.Equal(HttpStatusCode.OK, activitiesResponse.StatusCode);
        var activities = await activitiesResponse.Content.ReadFromJsonAsync<List<ActivityDto>>();
        Assert.NotNull(activities);
        Assert.All(activities, a => Assert.Equal("Movement", a.Domain));
    }

    [Fact]
    public async Task EndToEnd_IDOR_Security_ParentA_Cannot_Access_ParentB_Child()
    {
        var clientA = _factory.CreateClient();
        var clientB = _factory.CreateClient();

        // Register Parent A
        var regA = await clientA.PostAsJsonAsync("/api/auth/register-parent",
            new RegisterParentRequest("idor_parent_a@test.com", "Password123!", "Parent A", null));
        Assert.Equal(HttpStatusCode.Created, regA.StatusCode);
        var tokenA = await _factory.ConfirmAndLoginAsync("idor_parent_a@test.com");
        clientA.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", tokenA);

        // Register Parent B
        var regB = await clientB.PostAsJsonAsync("/api/auth/register-parent",
            new RegisterParentRequest("idor_parent_b@test.com", "Password123!", "Parent B", null));
        Assert.Equal(HttpStatusCode.Created, regB.StatusCode);
        var tokenB = await _factory.ConfirmAndLoginAsync("idor_parent_b@test.com");
        clientB.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", tokenB);

        // Parent B creates a child
        var childBResponse = await clientB.PostAsJsonAsync("/api/children",
            new CreateChildRequest("Secret Child B", new DateOnly(2019, 3, 10), null, DifficultyLevel.Beginner, DifficultyLevel.Beginner, DifficultyLevel.Beginner));
        Assert.Equal(HttpStatusCode.Created, childBResponse.StatusCode);
        var childB = await childBResponse.Content.ReadFromJsonAsync<ChildDto>();
        Assert.NotNull(childB);

        // Parent A attempts to view Parent B's child -> MUST BE DENIED SAFELY (404 Not Found to prevent information disclosure)
        var attackGet = await clientA.GetAsync($"/api/children/{childB.Id}");
        Assert.Equal(HttpStatusCode.NotFound, attackGet.StatusCode);

        // Parent A attempts to delete Parent B's child -> MUST BE DENIED SAFELY (404 Not Found)
        var attackDelete = await clientA.DeleteAsync($"/api/children/{childB.Id}");
        Assert.Equal(HttpStatusCode.NotFound, attackDelete.StatusCode);
    }

    [Fact]
    public async Task EndToEnd_Doctor_Assigned_Child_Access_And_Unassigned_Doctor_Denied()
    {
        var parentClient = _factory.CreateClient();
        var doc1Client = _factory.CreateClient();
        var doc2Client = _factory.CreateClient();

        // Register Parent
        var regParent = await parentClient.PostAsJsonAsync("/api/auth/register-parent",
            new RegisterParentRequest("doc_test_parent@test.com", "Password123!", "Doc Test Parent", null));
        var parentToken = await _factory.ConfirmAndLoginAsync("doc_test_parent@test.com");
        parentClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", parentToken);

        // Parent creates Child
        var childRes = await parentClient.PostAsJsonAsync("/api/children",
            new CreateChildRequest("Clinical Patient", new DateOnly(2017, 8, 20), null, DifficultyLevel.Beginner, DifficultyLevel.Beginner, DifficultyLevel.Beginner));
        var child = (await childRes.Content.ReadFromJsonAsync<ChildDto>())!;

        // Register Doctor 1
        var regDoc1 = await doc1Client.PostAsJsonAsync("/api/auth/register-doctor",
            new RegisterDoctorRequest("assigned_doc@test.com", "Password123!", "Dr. One", "Pediatric Neurology", "City Hospital", "LIC-111"));
        var doc1Auth = await regDoc1.Content.ReadFromJsonAsync<AuthResponseDto>();
        var doc1Token = await _factory.ConfirmAndLoginAsync("assigned_doc@test.com");
        doc1Client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", doc1Token);

        // Register Doctor 2
        var regDoc2 = await doc2Client.PostAsJsonAsync("/api/auth/register-doctor",
            new RegisterDoctorRequest("unassigned_doc@test.com", "Password123!", "Dr. Two", "Pediatric Therapy", "City Hospital", "LIC-222"));
        var doc2Auth = await regDoc2.Content.ReadFromJsonAsync<AuthResponseDto>();
        var doc2Token = await _factory.ConfirmAndLoginAsync("unassigned_doc@test.com");
        doc2Client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", doc2Token);

        // Parent assigns Doctor 1 to the Child
        var assignRes = await parentClient.PostAsJsonAsync($"/api/children/{child.Id}/assign-doctor",
            new AssignDoctorRequest(doc1Auth.User.ProfileId));
        Assert.Equal(HttpStatusCode.OK, assignRes.StatusCode);

        // Doctor 1 (assigned) views Child -> MUST SUCCEED (200 OK)
        var doc1Get = await doc1Client.GetAsync($"/api/children/{child.Id}");
        Assert.Equal(HttpStatusCode.OK, doc1Get.StatusCode);
        var doc1Details = await doc1Get.Content.ReadFromJsonAsync<ChildDetailsDto>();
        Assert.NotNull(doc1Details);
        Assert.Equal(child.Id, doc1Details.Id);

        // Doctor 2 (unassigned) attempts to view Child -> MUST BE DENIED SAFELY (404 Not Found to prevent information disclosure)
        var doc2Get = await doc2Client.GetAsync($"/api/children/{child.Id}");
        Assert.Equal(HttpStatusCode.NotFound, doc2Get.StatusCode);
    }
}
