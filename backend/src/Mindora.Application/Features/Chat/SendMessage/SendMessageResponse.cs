namespace Mindora.Application.Features.Chat.SendMessage;

public record SendMessageResponse(
    string Reply,
    string Role,
    string Model,
    DateTime CreatedAtUtc,
    bool IsFallback);
