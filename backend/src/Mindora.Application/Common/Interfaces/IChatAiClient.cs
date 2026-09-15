namespace Mindora.Application.Common.Interfaces;

/// <summary>
/// Represents a single conversational message turn.
/// </summary>
public record ChatAiMessage(string Role, string Content);

/// <summary>
/// Encapsulates the prompt payload for the chat AI client.
/// </summary>
public record ChatAiPrompt(IReadOnlyList<ChatAiMessage> Messages, double Temperature = 0.7);

/// <summary>
/// Result returned by the chat AI client.
/// </summary>
public record ChatAiResult(
    string Reply,
    string Model,
    bool IsFallback,
    string? ErrorDetail = null);

/// <summary>
/// Abstraction for communicating with the AI chat model (e.g. Google Gemini API).
/// Decouples Application layer from HTTP transport specifics.
/// </summary>
public interface IChatAiClient
{
    Task<ChatAiResult> SendChatCompletionAsync(
        ChatAiPrompt prompt,
        CancellationToken cancellationToken = default);
}
