using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Mindora.Application.Features.Chat.SendMessage;

namespace Mindora.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/chat")]
[Route("api/ai/chat")]
public class ChatController : ControllerBase
{
    /// <summary>
    /// Sends a user question and conversation history to the specialized AI assistant (Google Gemini).
    /// </summary>
    [HttpPost]
    [ProducesResponseType(typeof(SendMessageResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> SendMessage(
        [FromBody] SendMessageRequest request,
        [FromServices] SendMessageHandler handler,
        CancellationToken cancellationToken)
    {
        var response = await handler.HandleAsync(request, cancellationToken);
        return Ok(response);
    }
}
