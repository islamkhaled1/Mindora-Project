using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Mindora.Application.Features.Progress.GetChildProgress;
using Mindora.Application.Features.Progress.GetChildProgressHistory;
using Mindora.Application.Features.Progress.Models;

namespace Mindora.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/children/{childId:guid}/progress")]
public class ProgressController : ControllerBase
{
    [HttpGet]
    [ProducesResponseType(typeof(ChildProgressSummaryDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetProgress(
        [FromRoute] Guid childId,
        [FromServices] GetChildProgressHandler handler,
        CancellationToken cancellationToken)
    {
        var response = await handler.HandleAsync(childId, cancellationToken);
        return Ok(response);
    }

    [HttpGet("history")]
    [ProducesResponseType(typeof(IReadOnlyList<SessionHistoryPointDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetProgressHistory(
        [FromRoute] Guid childId,
        [FromQuery] GetChildProgressHistoryRequest request,
        [FromServices] GetChildProgressHistoryHandler handler,
        CancellationToken cancellationToken)
    {
        var response = await handler.HandleAsync(childId, request, cancellationToken);
        return Ok(response);
    }
}
