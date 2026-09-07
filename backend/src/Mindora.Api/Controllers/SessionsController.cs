using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Mindora.Application.Features.Sessions.AbandonSession;
using Mindora.Application.Features.Sessions.CompleteSession;
using Mindora.Application.Features.Sessions.GetSessionDetails;
using Mindora.Application.Features.Sessions.Models;
using Mindora.Application.Features.Sessions.RecordMetrics;
using Mindora.Application.Features.Sessions.StartSession;

namespace Mindora.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/sessions")]
public class SessionsController : ControllerBase
{
    [HttpPost]
    [ProducesResponseType(typeof(SessionDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> StartSession(
        [FromBody] StartSessionRequest request,
        [FromServices] StartSessionHandler handler,
        CancellationToken cancellationToken)
    {
        var response = await handler.HandleAsync(request, cancellationToken);
        return CreatedAtAction(nameof(GetSessionById), new { sessionId = response.Id }, response);
    }

    [HttpPost("{sessionId:guid}/metrics")]
    [ProducesResponseType(typeof(IReadOnlyList<PerformanceMetricDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> RecordMetrics(
        [FromRoute] Guid sessionId,
        [FromBody] RecordMetricsRequest request,
        [FromServices] RecordMetricsHandler handler,
        CancellationToken cancellationToken)
    {
        var response = await handler.HandleAsync(sessionId, request, cancellationToken);
        return Ok(response);
    }

    [HttpPost("{sessionId:guid}/complete")]
    [ProducesResponseType(typeof(CompletedSessionDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> CompleteSession(
        [FromRoute] Guid sessionId,
        [FromBody] CompleteSessionRequest request,
        [FromServices] CompleteSessionHandler handler,
        CancellationToken cancellationToken)
    {
        var response = await handler.HandleAsync(sessionId, request, cancellationToken);
        return Ok(response);
    }

    [HttpPost("{sessionId:guid}/abandon")]
    [ProducesResponseType(typeof(SessionDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> AbandonSession(
        [FromRoute] Guid sessionId,
        [FromServices] AbandonSessionHandler handler,
        CancellationToken cancellationToken)
    {
        var response = await handler.HandleAsync(sessionId, cancellationToken);
        return Ok(response);
    }

    [HttpGet("{sessionId:guid}")]
    [ProducesResponseType(typeof(SessionDetailsDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetSessionById(
        [FromRoute] Guid sessionId,
        [FromServices] GetSessionDetailsHandler handler,
        CancellationToken cancellationToken)
    {
        var response = await handler.HandleAsync(sessionId, cancellationToken);
        return Ok(response);
    }
}
