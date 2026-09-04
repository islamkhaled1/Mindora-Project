namespace Mindora.Application.Features.Activities.GetActivities;

public record GetActivitiesRequest(
    string? Domain = null,
    string? Difficulty = null);
