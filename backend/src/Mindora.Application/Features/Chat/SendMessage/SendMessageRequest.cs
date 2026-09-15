namespace Mindora.Application.Features.Chat.SendMessage;

public record SendMessageRequest(
    string Message,
    IReadOnlyList<ChatMessageDto>? Conversation);
