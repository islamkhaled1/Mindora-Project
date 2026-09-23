using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Mindora.Application.Features.Activities.GetChildActivityPerformance;
using Mindora.Application.Features.Activities.Models;
using Mindora.Application.Features.Assessments.GetChildBaselineAssessment;
using Mindora.Application.Features.Assessments.GetHomePracticeRecommendation;
using Mindora.Application.Features.Assessments.Models;
using Mindora.Application.Features.Assessments.RecordBaselineAssessment;
using Mindora.Application.Features.Children.AssignDoctor;
using Mindora.Application.Features.Children.CreateChild;
using Mindora.Application.Features.Children.GenerateLinkingCode;
using Mindora.Application.Features.Children.GetChildDetails;
using Mindora.Application.Features.Children.GetParentChildren;
using Mindora.Application.Features.Children.LinkDoctor;
using Mindora.Application.Features.Children.Models;
using Mindora.Application.Features.Children.SoftDeleteChild;

namespace Mindora.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/children")]
public class ChildrenController : ControllerBase
{
    [HttpPost]
    [ProducesResponseType(typeof(ChildDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> CreateChild(
        [FromBody] CreateChildRequest request,
        [FromServices] CreateChildHandler handler,
        CancellationToken cancellationToken)
    {
        var response = await handler.HandleAsync(request, cancellationToken);
        return CreatedAtAction(nameof(GetChildById), new { childId = response.Id }, response);
    }

    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<ChildSummaryDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> GetParentChildren(
        [FromServices] GetParentChildrenHandler handler,
        CancellationToken cancellationToken)
    {
        var response = await handler.HandleAsync(cancellationToken);
        return Ok(response);
    }

    [HttpGet("{childId:guid}")]
    [ProducesResponseType(typeof(ChildDetailsDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetChildById(
        [FromRoute] Guid childId,
        [FromServices] GetChildDetailsHandler handler,
        CancellationToken cancellationToken)
    {
        var response = await handler.HandleAsync(childId, cancellationToken);
        return Ok(response);
    }

    [HttpGet("{childId:guid}/activities/performance")]
    [ProducesResponseType(typeof(IReadOnlyList<ActivityPerformanceDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetActivityPerformance(
        [FromRoute] Guid childId,
        [FromServices] GetChildActivityPerformanceHandler handler,
        CancellationToken cancellationToken)
    {
        var response = await handler.HandleAsync(childId, cancellationToken);
        return Ok(response);
    }

    [HttpPost("{childId:guid}/assign-doctor")]
    [ProducesResponseType(typeof(DoctorAssignmentDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> AssignDoctor(
        [FromRoute] Guid childId,
        [FromBody] AssignDoctorRequest request,
        [FromServices] AssignDoctorHandler handler,
        CancellationToken cancellationToken)
    {
        var response = await handler.HandleAsync(childId, request, cancellationToken);
        return Ok(response);
    }

    [HttpPost("{childId:guid}/link-doctor")]
    [ProducesResponseType(typeof(DoctorLinkRequestDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> LinkDoctor(
        [FromRoute] Guid childId,
        [FromBody] LinkDoctorByCodeRequest request,
        [FromServices] LinkDoctorByCodeHandler handler,
        CancellationToken cancellationToken)
    {
        var response = await handler.HandleAsync(childId, request, cancellationToken);
        return Ok(response);
    }

    [HttpPost("{childId:guid}/linking-code")]
    [ProducesResponseType(typeof(ChildLinkingCodeDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GenerateLinkingCode(
        [FromRoute] Guid childId,
        [FromServices] GenerateLinkingCodeHandler handler,
        CancellationToken cancellationToken)
    {
        var response = await handler.HandleAsync(childId, cancellationToken);
        return Ok(response);
    }

    [HttpPost("{childId:guid}/baseline-assessment")]
    [ProducesResponseType(typeof(BaselineAssessmentDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> RecordBaselineAssessment(
        [FromRoute] Guid childId,
        [FromBody] RecordBaselineAssessmentRequest request,
        [FromServices] RecordBaselineAssessmentHandler handler,
        CancellationToken cancellationToken)
    {
        var response = await handler.HandleAsync(childId, request, cancellationToken);
        return CreatedAtAction(nameof(GetBaselineAssessment), new { childId }, response);
    }

    [HttpGet("{childId:guid}/baseline-assessment")]
    [ProducesResponseType(typeof(BaselineAssessmentDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetBaselineAssessment(
        [FromRoute] Guid childId,
        [FromServices] GetChildBaselineAssessmentHandler handler,
        CancellationToken cancellationToken)
    {
        var response = await handler.HandleAsync(childId, cancellationToken);
        return Ok(response);
    }

    [HttpGet("{childId:guid}/home-practice-recommendation")]
    [ProducesResponseType(typeof(HomePracticeRecommendationDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetHomePracticeRecommendation(
        [FromRoute] Guid childId,
        [FromServices] HomePracticeRecommendationHandler handler,
        CancellationToken cancellationToken)
    {
        var response = await handler.HandleAsync(childId, cancellationToken);
        return Ok(response);
    }

    [HttpDelete("{childId:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteChild(
        [FromRoute] Guid childId,
        [FromServices] SoftDeleteChildHandler handler,
        CancellationToken cancellationToken)
    {
        await handler.HandleAsync(childId, cancellationToken);
        return NoContent();
    }
}
