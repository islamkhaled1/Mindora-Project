using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Mindora.Application.Features.Children.Models;
using Mindora.Application.Features.Doctor.GetDoctorChildren;
using Mindora.Application.Features.Doctor.GetDoctorDashboard;
using Mindora.Application.Features.Doctor.LinkChild;
using Mindora.Application.Features.Doctor.Models;

using Mindora.Application.Features.Doctor.Notes;

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

    [HttpPut("children/{childId:guid}/notes")]
    [ProducesResponseType(typeof(DoctorNotesDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateNotes(
        [FromRoute] Guid childId,
        [FromBody] UpdateDoctorNotesRequest request,
        [FromServices] UpdateDoctorNotesHandler handler,
        CancellationToken cancellationToken)
    {
        var response = await handler.HandleAsync(childId, request, cancellationToken);
        return Ok(response);
    }

    [HttpGet("children/{childId:guid}/notes")]
    [ProducesResponseType(typeof(DoctorNotesDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetNotes(
        [FromRoute] Guid childId,
        [FromServices] GetDoctorNotesHandler handler,
        CancellationToken cancellationToken)
    {
        var response = await handler.HandleAsync(childId, cancellationToken);
        return Ok(response);
    }

    [HttpGet("link-requests")]
    [ProducesResponseType(typeof(IReadOnlyList<DoctorLinkRequestSummaryDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> GetLinkRequests(
        [FromQuery] Mindora.Domain.Enums.DoctorLinkRequestStatus? status,
        [FromServices] Mindora.Application.Features.Doctor.ConnectionRequests.GetDoctorLinkRequestsHandler handler,
        CancellationToken cancellationToken)
    {
        var response = await handler.HandleAsync(status, cancellationToken);
        return Ok(response);
    }

    [HttpPost("link-requests/{id:guid}/approve")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> ApproveLinkRequest(
        [FromRoute] Guid id,
        [FromServices] Mindora.Application.Features.Doctor.ConnectionRequests.ApproveDoctorLinkRequestHandler handler,
        CancellationToken cancellationToken)
    {
        await handler.HandleAsync(id, cancellationToken);
        return Ok(new { message = "Connection request approved successfully." });
    }

    [HttpPost("link-requests/{id:guid}/reject")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> RejectLinkRequest(
        [FromRoute] Guid id,
        [FromServices] Mindora.Application.Features.Doctor.ConnectionRequests.RejectDoctorLinkRequestHandler handler,
        CancellationToken cancellationToken)
    {
        await handler.HandleAsync(id, cancellationToken);
        return Ok(new { message = "Connection request rejected." });
    }
}
