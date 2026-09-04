using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Mindora.Application.Features.Activities.GetActivities;
using Mindora.Application.Features.Activities.GetActivityById;
using Mindora.Application.Features.Activities.Models;

namespace Mindora.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/activities")]
public class ActivitiesController : ControllerBase
{
    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<ActivityDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetActivities(
        [FromQuery] GetActivitiesRequest request,
        [FromServices] GetActivitiesHandler handler,
        CancellationToken cancellationToken)
    {
        var response = await handler.HandleAsync(request, cancellationToken);
        return Ok(response);
    }

    [HttpGet("{activityId:guid}")]
    [ProducesResponseType(typeof(ActivityDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetActivityById(
        [FromRoute] Guid activityId,
        [FromServices] GetActivityByIdHandler handler,
        CancellationToken cancellationToken)
    {
        var response = await handler.HandleAsync(activityId, cancellationToken);
        return Ok(response);
    }
}
