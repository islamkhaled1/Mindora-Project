namespace Mindora.Application.Features.Sessions.StartSession;

public record StartSessionRequest(
    Guid ChildId,
    Guid ActivityId);
