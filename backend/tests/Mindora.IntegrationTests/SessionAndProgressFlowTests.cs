using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Mindora.Application.Features.Activities.Models;
using Mindora.Application.Features.Auth.Models;
using Mindora.Application.Features.Auth.RegisterDoctor;
using Mindora.Application.Features.Auth.RegisterParent;
using Mindora.Application.Features.Children.AssignDoctor;
using Mindora.Application.Features.Children.CreateChild;
using Mindora.Application.Features.Children.Models;
using Mindora.Application.Features.Progress.Models;
using Mindora.Application.Features.Sessions.CompleteSession;
using Mindora.Application.Features.Sessions.Models;
using Mindora.Application.Features.Sessions.RecordMetrics;
using Mindora.Application.Features.Sessions.StartSession;
using Mindora.Domain.Enums;
using Mindora.IntegrationTests.Infrastructure;
using Xunit;

namespace Mindora.IntegrationTests;

public class SessionAndProgressFlowTests : IClassFixture<MindoraApiFactory>
{
    private readonly MindoraApiFactory _factory;

    public SessionAndProgressFlowTests(MindoraApiFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task EndToEnd_CoreBusinessFlow_Session_Metrics_Complete_Ai_Progress()
    {
        var client = _factory.CreateClient();

        // 1. Register Parent
        var regRes = await client.PostAsJsonAsync("/api/auth/register-parent",
            new RegisterParentRequest("core_flow_parent@test.com", "Password123!", "Flow Parent", null));
        Assert.Equal(HttpStatusCode.Created, regRes.StatusCode);
        var auth = await regRes.Content.ReadFromJsonAsync<AuthResponseDto>();
        Assert.NotNull(auth);

        var token = await _factory.ConfirmAndLoginAsync("core_flow_parent@test.com");
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

        // 2. Create Child
        var childRes = await client.PostAsJsonAsync("/api/children",
            new CreateChildRequest("Core Flow Child", new DateOnly(2018, 5, 10), null, DifficultyLevel.Beginner, DifficultyLevel.Beginner, DifficultyLevel.Beginner));
        Assert.Equal(HttpStatusCode.Created, childRes.StatusCode);
        var child = await childRes.Content.ReadFromJsonAsync<ChildDto>();
        Assert.NotNull(child);

        // 3. Get Activities
        var actRes = await client.GetAsync("/api/activities?domain=Movement");
        Assert.Equal(HttpStatusCode.OK, actRes.StatusCode);
        var activities = await actRes.Content.ReadFromJsonAsync<List<ActivityDto>>();
        Assert.NotNull(activities);
        Assert.NotEmpty(activities);
        var activity = activities[0];

        // 4. Start Session
        var startRes = await client.PostAsJsonAsync("/api/sessions",
            new StartSessionRequest(child.Id, activity.Id));
        Assert.Equal(HttpStatusCode.Created, startRes.StatusCode);
        var session = await startRes.Content.ReadFromJsonAsync<SessionDto>();
        Assert.NotNull(session);
        Assert.Equal("Started", session.Status);
        Assert.Equal(activity.Domain, session.Domain);

        // 5. Record Metrics
        var metricRes = await client.PostAsJsonAsync($"/api/sessions/{session.Id}/metrics",
            new RecordMetricsRequest(new List<MetricInputDto>
            {
                new("AccuracyPercentage", 88.00m),
                new("ReactionTimeMs", 1500.00m)
            }));
        Assert.Equal(HttpStatusCode.OK, metricRes.StatusCode);

        // 6. Complete Session
        var completeRes = await client.PostAsJsonAsync($"/api/sessions/{session.Id}/complete",
            new CompleteSessionRequest(120, null));
        Assert.Equal(HttpStatusCode.OK, completeRes.StatusCode);
        var completed = await completeRes.Content.ReadFromJsonAsync<CompletedSessionDto>();
        Assert.NotNull(completed);
        Assert.Equal("Completed", completed.Status);
        Assert.NotNull(completed.AnalysisResult);
        Assert.False(completed.AnalysisResult.IsFallbackResult);

        // 7. Get Child Progress (/api/children/{childId}/progress)
        var progRes = await client.GetAsync($"/api/children/{child.Id}/progress");
        Assert.Equal(HttpStatusCode.OK, progRes.StatusCode);
        var progress = await progRes.Content.ReadFromJsonAsync<ChildProgressSummaryDto>();
        Assert.NotNull(progress);
        Assert.Equal(1, progress.TotalCompletedSessions);
        Assert.True(progress.OverallAverageScore > 0);

        // 8. Get Child Progress History (/api/children/{childId}/progress/history)
        var histRes = await client.GetAsync($"/api/children/{child.Id}/progress/history");
        Assert.Equal(HttpStatusCode.OK, histRes.StatusCode);
        var history = await histRes.Content.ReadFromJsonAsync<List<SessionHistoryPointDto>>();
        Assert.NotNull(history);
        Assert.Single(history);
        Assert.Equal(session.Id, history[0].SessionId);
        Assert.Equal(completed.AnalysisResult.OverallPerformanceScore, history[0].Score);
    }

    [Fact]
    public async Task EndToEnd_IDOR_Security_ParentA_Cannot_Access_ParentB_Sessions_Or_Progress()
    {
        var clientA = _factory.CreateClient();
        var clientB = _factory.CreateClient();

        // Register Parent A
        var regA = await clientA.PostAsJsonAsync("/api/auth/register-parent",
            new RegisterParentRequest("idor_sess_a@test.com", "Password123!", "Parent A", null));
        var authA = await regA.Content.ReadFromJsonAsync<AuthResponseDto>();
        var tokenA = await _factory.ConfirmAndLoginAsync("idor_sess_a@test.com");
        clientA.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", tokenA);

        // Register Parent B
        var regB = await clientB.PostAsJsonAsync("/api/auth/register-parent",
            new RegisterParentRequest("idor_sess_b@test.com", "Password123!", "Parent B", null));
        var authB = await regB.Content.ReadFromJsonAsync<AuthResponseDto>();
        var tokenB = await _factory.ConfirmAndLoginAsync("idor_sess_b@test.com");
        clientB.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", tokenB);

        // Parent B creates Child B
        var childBRes = await clientB.PostAsJsonAsync("/api/children",
            new CreateChildRequest("Child B Private", new DateOnly(2019, 1, 1), null, DifficultyLevel.Beginner, DifficultyLevel.Beginner, DifficultyLevel.Beginner));
        var childB = (await childBRes.Content.ReadFromJsonAsync<ChildDto>())!;

        // Get activity
        var actRes = await clientB.GetAsync("/api/activities");
        var activity = (await actRes.Content.ReadFromJsonAsync<List<ActivityDto>>())![0];

        // Parent B starts session
        var sessBRes = await clientB.PostAsJsonAsync("/api/sessions",
            new StartSessionRequest(childB.Id, activity.Id));
        var sessB = (await sessBRes.Content.ReadFromJsonAsync<SessionDto>())!;

        // Attack 1: Parent A attempts to start session for Parent B's child -> 404
        var attackStart = await clientA.PostAsJsonAsync("/api/sessions",
            new StartSessionRequest(childB.Id, activity.Id));
        Assert.Equal(HttpStatusCode.NotFound, attackStart.StatusCode);

        // Attack 2: Parent A attempts to record metrics on Parent B's session -> 404
        var attackMetric = await clientA.PostAsJsonAsync($"/api/sessions/{sessB.Id}/metrics",
            new RecordMetricsRequest(new List<MetricInputDto> { new("AccuracyPercentage", 90m) }));
        Assert.Equal(HttpStatusCode.NotFound, attackMetric.StatusCode);

        // Attack 3: Parent A attempts to complete Parent B's session -> 404
        var attackComplete = await clientA.PostAsJsonAsync($"/api/sessions/{sessB.Id}/complete",
            new CompleteSessionRequest(60));
        Assert.Equal(HttpStatusCode.NotFound, attackComplete.StatusCode);

        // Attack 4: Parent A attempts to view Parent B's session details -> 404
        var attackDetails = await clientA.GetAsync($"/api/sessions/{sessB.Id}");
        Assert.Equal(HttpStatusCode.NotFound, attackDetails.StatusCode);

        // Attack 5: Parent A attempts to view Parent B's child progress -> 404
        var attackProgress = await clientA.GetAsync($"/api/children/{childB.Id}/progress");
        Assert.Equal(HttpStatusCode.NotFound, attackProgress.StatusCode);

        // Attack 6: Parent A attempts to view Parent B's child progress history -> 404
        var attackHistory = await clientA.GetAsync($"/api/children/{childB.Id}/progress/history");
        Assert.Equal(HttpStatusCode.NotFound, attackHistory.StatusCode);
    }

    [Fact]
    public async Task EndToEnd_Doctor_Assigned_Vs_Unassigned_Session_Access()
    {
        var parentClient = _factory.CreateClient();
        var docAssignedClient = _factory.CreateClient();
        var docUnassignedClient = _factory.CreateClient();

        // Register Parent
        var regP = await parentClient.PostAsJsonAsync("/api/auth/register-parent",
            new RegisterParentRequest("doc_sess_parent@test.com", "Password123!", "Doc Sess Parent", null));
        var authP = (await regP.Content.ReadFromJsonAsync<AuthResponseDto>())!;
        var tokenP = await _factory.ConfirmAndLoginAsync("doc_sess_parent@test.com");
        parentClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", tokenP);

        // Parent creates Child
        var childRes = await parentClient.PostAsJsonAsync("/api/children",
            new CreateChildRequest("Doc Patient", new DateOnly(2018, 4, 1), null, DifficultyLevel.Beginner, DifficultyLevel.Beginner, DifficultyLevel.Beginner));
        var child = (await childRes.Content.ReadFromJsonAsync<ChildDto>())!;

        // Register Doctor 1 (Assigned)
        var regDoc1 = await docAssignedClient.PostAsJsonAsync("/api/auth/register-doctor",
            new RegisterDoctorRequest("doc_assigned_sess@test.com", "Password123!", "Dr. Assigned", "Therapy", "Clinic", "LIC-777"));
        var authDoc1 = (await regDoc1.Content.ReadFromJsonAsync<AuthResponseDto>())!;
        var tokenDoc1 = await _factory.ConfirmAndLoginAsync("doc_assigned_sess@test.com");
        docAssignedClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", tokenDoc1);

        // Register Doctor 2 (Unassigned)
        var regDoc2 = await docUnassignedClient.PostAsJsonAsync("/api/auth/register-doctor",
            new RegisterDoctorRequest("doc_unassigned_sess@test.com", "Password123!", "Dr. Unassigned", "Therapy", "Clinic", "LIC-888"));
        var authDoc2 = (await regDoc2.Content.ReadFromJsonAsync<AuthResponseDto>())!;
        var tokenDoc2 = await _factory.ConfirmAndLoginAsync("doc_unassigned_sess@test.com");
        docUnassignedClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", tokenDoc2);

        // Parent assigns Doctor 1
        await parentClient.PostAsJsonAsync($"/api/children/{child.Id}/assign-doctor",
            new AssignDoctorRequest(authDoc1.User.ProfileId));

        // Get activity
        var actRes = await parentClient.GetAsync("/api/activities");
        var activity = (await actRes.Content.ReadFromJsonAsync<List<ActivityDto>>())![0];

        // Assigned Doctor starts session -> SUCCEEDS (201 Created)
        var startDocRes = await docAssignedClient.PostAsJsonAsync("/api/sessions",
            new StartSessionRequest(child.Id, activity.Id));
        Assert.Equal(HttpStatusCode.Created, startDocRes.StatusCode);
        var session = (await startDocRes.Content.ReadFromJsonAsync<SessionDto>())!;

        // Unassigned Doctor attempts to start session for Child -> FAILS (404)
        var unassignedStart = await docUnassignedClient.PostAsJsonAsync("/api/sessions",
            new StartSessionRequest(child.Id, activity.Id));
        Assert.Equal(HttpStatusCode.NotFound, unassignedStart.StatusCode);

        // Unassigned Doctor attempts to view Session -> FAILS (404)
        var unassignedView = await docUnassignedClient.GetAsync($"/api/sessions/{session.Id}");
        Assert.Equal(HttpStatusCode.NotFound, unassignedView.StatusCode);

        // Unassigned Doctor attempts to view Progress -> FAILS (404)
        var unassignedProgress = await docUnassignedClient.GetAsync($"/api/children/{child.Id}/progress");
        Assert.Equal(HttpStatusCode.NotFound, unassignedProgress.StatusCode);
    }
}
