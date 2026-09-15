using FluentValidation;
using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;

namespace Mindora.Application.Features.Chat.SendMessage;

public class SendMessageHandler
{
    private readonly ICurrentUserService _currentUserService;
    private readonly IChatAiClient _chatAiClient;
    private readonly IValidator<SendMessageRequest> _validator;

    public SendMessageHandler(
        ICurrentUserService currentUserService,
        IChatAiClient chatAiClient,
        IValidator<SendMessageRequest> validator)
    {
        _currentUserService = currentUserService;
        _chatAiClient = chatAiClient;
        _validator = validator;
    }

    public async Task<SendMessageResponse> HandleAsync(
        SendMessageRequest request,
        CancellationToken cancellationToken = default)
    {
        if (!_currentUserService.IsAuthenticated || _currentUserService.UserId == null)
        {
            throw new UnauthorizedException("User is not authenticated.");
        }

        var validationResult = await _validator.ValidateAsync(request, cancellationToken);
        if (!validationResult.IsValid)
        {
            var failures = validationResult.Errors
                .Select(e => new FluentValidation.Results.ValidationFailure(e.PropertyName, e.ErrorMessage));
            throw new Mindora.Application.Common.Exceptions.ValidationException(failures);
        }

        // Build conversational context from prior turns + current user message
        var messages = new List<ChatAiMessage>();

        if (request.Conversation != null)
        {
            foreach (var turn in request.Conversation)
            {
                if (!string.IsNullOrWhiteSpace(turn.Content) && !string.IsNullOrWhiteSpace(turn.Role))
                {
                    messages.Add(new ChatAiMessage(turn.Role.Trim(), turn.Content.Trim()));
                }
            }
        }

        // Append active user message
        messages.Add(new ChatAiMessage("user", request.Message.Trim()));

        var prompt = new ChatAiPrompt(messages);
        var result = await _chatAiClient.SendChatCompletionAsync(prompt, cancellationToken);

        return new SendMessageResponse(
            Reply: result.Reply,
            Role: "assistant",
            Model: result.Model,
            CreatedAtUtc: DateTime.UtcNow,
            IsFallback: result.IsFallback);
    }
}
