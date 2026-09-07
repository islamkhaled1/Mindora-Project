using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Mindora.Application.Features.Activities.Models;
using Mindora.Application.Features.Auth.Models;
using Mindora.Application.Features.Auth.RegisterDoctor;
using Mindora.Application.Features.Auth.RegisterParent;
using Mindora.Application.Features.Children.CreateChild;
using Mindora.Application.Features.Children.Models;
using Mindora.Application.Features.Doctor.LinkChild;
using Mindora.Application.Features.Doctor.Models;
using Mindora.Application.Features.Progress.Models;
using Mindora.Application.Features.Sessions.CompleteSession;
using Mindora.Application.Features.Sessions.Models;
using Mindora.Application.Features.Sessions.RecordMetrics;
using Mindora.Application.Features.Sessions.StartSession;
using Mindora.Domain.Enums;
using Mindora.IntegrationTests.Infrastructure;
using Xunit;

namespace Mindora.IntegrationTests;

public class DoctorAndDashboardFlowTests : IClassFixture<MindoraApiFactory>
{
    private readonly MindoraApiFactory _factory;

    public DoctorAndDashboardFlowTests(MindoraApiFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task EndToEnd_DoctorLinking_Dashboard_ActivityPerformance_And_Abandonment()
    {
        var client = _factory.CreateClient();

        // 1. Register Doctor
        var docRegRes = await client.PostAsJsonAsync("/api/auth/register-doctor",
            new RegisterDoctorRequest("flow_doctor@test.com", "Password123!", "Dr. Strange", "Neurology", "General Hospital", "LIC-777"));
        Assert.Equal(HttpStatusCode.Created, docRegRes.StatusCode);
        var docAuth = await docRegRes.Content.ReadFromJsonAsync<AuthResponseDto>();
        Assert.NotNull(docAuth);

        // 2. Register Parent
        var parentRegRes = await client.PostAsJsonAsync("/api/auth/register-parent",
            new RegisterParentRequest("flow_parent2@test.com", "Password123!", "Martha Kent", null));
        Assert.Equal(HttpStatusCode.Created, parentRegRes.StatusCode);
        var parentAuth = await parentRegRes.Content.ReadFromJsonAsync<AuthResponseDto>();
        Assert.NotNull(parentAuth);

        // 3. Parent creates Child
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", parentAuth.Token);
        var createChildRes = await client.PostAsJsonAsync("/api/children",
            new CreateChildRequest("Clark Kent", new DateOnly(2018, 2, 28), "Movement evaluation", DifficultyLevel.Beginner, DifficultyLevel.Beginner, DifficultyLevel.Beginner));
        Assert.Equal(HttpStatusCode.Created, createChildRes.StatusCode);
        var child = await createChildRes.Content.ReadFromJsonAsync<ChildDto>();
        Assert.NotNull(child);

        // 4. Parent generates single-use Linking Code
        var genCodeRes = await client.PostAsync($"/api/children/{child.Id}/linking-code", null);
        Assert.Equal(HttpStatusCode.OK, genCodeRes.StatusCode);
        var codeDto = await genCodeRes.Content.ReadFromJsonAsync<ChildLinkingCodeDto>();
        Assert.NotNull(codeDto);
        Assert.StartsWith("MND-", codeDto.Code);

        // 5. Doctor redeems Linking Code
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", docAuth.Token);
        var linkRes = await client.PostAsJsonAsync("/api/doctor/link-child", new LinkChildRequest(codeDto.Code));
        Assert.Equal(HttpStatusCode.OK, linkRes.StatusCode);
        var linkDto = await linkRes.Content.ReadFromJsonAsync<DoctorAssignmentDto>();
        Assert.NotNull(linkDto);
        Assert.Equal(child.Id, linkDto.ChildId);

        // 6. Doctor inspects assigned children roster
        var rosterRes = await client.GetAsync("/api/doctor/children");
        Assert.Equal(HttpStatusCode.OK, rosterRes.StatusCode);
        var roster = await rosterRes.Content.ReadFromJsonAsync<List<DoctorChildCardDto>>();
        Assert.NotNull(roster);
        Assert.Single(roster);
        Assert.Equal(child.Id, roster[0].ChildId);

        // 7. Doctor inspects Dashboard (initially 0 sessions)
        var dashRes = await client.GetAsync("/api/doctor/dashboard");
        Assert.Equal(HttpStatusCode.OK, dashRes.StatusCode);
        var dash = await dashRes.Content.ReadFromJsonAsync<DoctorDashboardDto>();
        Assert.NotNull(dash);
        Assert.Equal(1, dash.TotalAssignedChildren);
        Assert.Equal(0, dash.WeeklyCompletedSessions);

        // 8. Get Activities
        var actRes = await client.GetAsync("/api/activities?domain=Movement");
        Assert.Equal(HttpStatusCode.OK, actRes.StatusCode);
        var activities = await actRes.Content.ReadFromJsonAsync<List<ActivityDto>>();
        Assert.NotNull(activities);
        Assert.NotEmpty(activities);
        var activity = activities[0];

        // 9. Parent starts a session and then abandons it
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", parentAuth.Token);
        var startRes1 = await client.PostAsJsonAsync("/api/sessions", new StartSessionRequest(child.Id, activity.Id));
        Assert.Equal(HttpStatusCode.Created, startRes1.StatusCode);
        var session1 = await startRes1.Content.ReadFromJsonAsync<SessionDto>();
        Assert.NotNull(session1);

        var abandonRes = await client.PostAsync($"/api/sessions/{session1.Id}/abandon", null);
        Assert.Equal(HttpStatusCode.OK, abandonRes.StatusCode);
        var abandonedSession = await abandonRes.Content.ReadFromJsonAsync<SessionDto>();
        Assert.NotNull(abandonedSession);
        Assert.Equal(SessionStatus.Abandoned.ToString(), abandonedSession.Status);

        // 10. Parent starts a second session, records metrics, and completes it
        var startRes2 = await client.PostAsJsonAsync("/api/sessions", new StartSessionRequest(child.Id, activity.Id));
        Assert.Equal(HttpStatusCode.Created, startRes2.StatusCode);
        var session2 = await startRes2.Content.ReadFromJsonAsync<SessionDto>();
        Assert.NotNull(session2);

        var metricsRes = await client.PostAsJsonAsync($"/api/sessions/{session2.Id}/metrics",
            new RecordMetricsRequest(new List<MetricInputDto>
            {
                new("AccuracyPercentage", 88.0m),
                new("RepetitionCount", 14.0m),
                new("ReactionTimeMs", 350.0m)
            }));
        Assert.Equal(HttpStatusCode.OK, metricsRes.StatusCode);

        var completeRes = await client.PostAsJsonAsync($"/api/sessions/{session2.Id}/complete",
            new CompleteSessionRequest(180, null));
        Assert.Equal(HttpStatusCode.OK, completeRes.StatusCode);
        var completed = await completeRes.Content.ReadFromJsonAsync<CompletedSessionDto>();
        Assert.NotNull(completed);
        Assert.NotNull(completed.AnalysisResult);

        // 11. Doctor inspects child Activity Performance
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", docAuth.Token);
        var perfRes = await client.GetAsync($"/api/children/{child.Id}/activities/performance");
        Assert.Equal(HttpStatusCode.OK, perfRes.StatusCode);
        var perfList = await perfRes.Content.ReadFromJsonAsync<List<ActivityPerformanceDto>>();
        Assert.NotNull(perfList);
        Assert.Single(perfList);
        Assert.Equal(1, perfList[0].TimesPlayed); // Only completed session, abandoned excluded!
        Assert.Equal(3, perfList[0].TotalPracticeMinutes); // 180s = 3 min
        Assert.Equal(88.0m, perfList[0].AverageAccuracyPercentage);
        Assert.Equal(14.0m, perfList[0].AverageRepetitions);
        Assert.Equal(350.0m, perfList[0].AverageReactionTimeMs);

        // 12. Doctor inspects paginated progress history
        var histRes = await client.GetAsync($"/api/children/{child.Id}/progress/history?page=1&pageSize=5");
        Assert.Equal(HttpStatusCode.OK, histRes.StatusCode);
        var history = await histRes.Content.ReadFromJsonAsync<List<SessionHistoryPointDto>>();
        Assert.NotNull(history);
        Assert.Single(history);
        Assert.Equal(session2.Id, history[0].SessionId);

        // 13. Doctor inspects updated Dashboard
        var updatedDashRes = await client.GetAsync("/api/doctor/dashboard");
        Assert.Equal(HttpStatusCode.OK, updatedDashRes.StatusCode);
        var updatedDash = await updatedDashRes.Content.ReadFromJsonAsync<DoctorDashboardDto>();
        Assert.NotNull(updatedDash);
        Assert.Equal(1, updatedDash.TotalAssignedChildren);
        Assert.Equal(1, updatedDash.WeeklyCompletedSessions);
        Assert.Equal(1, updatedDash.ActiveChildrenCount);
        Assert.Single(updatedDash.RecentCompletedSessions);
    }
}
