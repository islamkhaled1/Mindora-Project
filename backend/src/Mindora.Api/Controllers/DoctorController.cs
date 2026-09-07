using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Mindora.Application.Features.Children.Models;
using Mindora.Application.Features.Doctor.GetDoctorChildren;
using Mindora.Application.Features.Doctor.GetDoctorDashboard;
using Mindora.Application.Features.Doctor.LinkChild;
using Mindora.Application.Features.Doctor.Models;

namespace Mindora.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/doctor")]
public class DoctorController : ControllerBase
{
    [HttpGet("dashboard")]
    [ProducesResponseType(typeof(DoctorDashboardDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> GetDashboard(
        [FromServices] GetDoctorDashboardHandler handler,
        CancellationToken cancellationToken)
    {
        var response = await handler.HandleAsync(cancellationToken);
        return Ok(response);
    }

    [HttpGet("children")]
    [ProducesResponseType(typeof(IReadOnlyList<DoctorChildCardDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> GetChildren(
        [FromServices] GetDoctorChildrenHandler handler,
        CancellationToken cancellationToken)
    {
        var response = await handler.HandleAsync(cancellationToken);
        return Ok(response);
    }

    [HttpPost("link-child")]
    [ProducesResponseType(typeof(DoctorAssignmentDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> LinkChild(
        [FromBody] LinkChildRequest request,
        [FromServices] LinkChildHandler handler,
        CancellationToken cancellationToken)
    {
        var response = await handler.HandleAsync(request, cancellationToken);
        return Ok(response);
    }
}
