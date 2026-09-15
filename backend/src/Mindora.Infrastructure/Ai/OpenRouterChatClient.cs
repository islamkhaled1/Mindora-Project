using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Mindora.Application.Common.Interfaces;

namespace Mindora.Infrastructure.Ai;

/// <summary>
/// Legacy client connecting to OpenRouter API (Llama 3.1 8B Instruct).
/// Retained for archival/fallback reference; production chatbot uses GeminiChatClient.
/// </summary>
public class OpenRouterChatClient : IChatAiClient
{
    private readonly HttpClient _httpClient;
    private readonly ChatOptions _options;
    private readonly ILogger<OpenRouterChatClient> _logger;

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull
    };

    public OpenRouterChatClient(
        HttpClient httpClient,
        IOptions<ChatOptions> options,
        ILogger<OpenRouterChatClient> logger)
    {
        _httpClient = httpClient;
        _options = options.Value;
        _logger = logger;
    }

    public async Task<ChatAiResult> SendChatCompletionAsync(
        ChatAiPrompt prompt,
        CancellationToken cancellationToken = default)
    {
        var apiKey = !string.IsNullOrWhiteSpace(_options.ApiKey)
            ? _options.ApiKey.Trim()
            : Environment.GetEnvironmentVariable("OPENROUTER_API_KEY")?.Trim();

        if (string.IsNullOrWhiteSpace(apiKey))
        {
            _logger.LogWarning("OpenRouter API key is not configured on the server. Falling back to explicit fallback mode.");
            return new ChatAiResult(
                "[نمط احتياطي] تعذر الاتصال بمزود الذكاء الاصطناعي: مفتاح API غير متوفر على الخادم. يرجى ضبط الإعدادات.",
                "fallback",
                IsFallback: true,
                ErrorDetail: "Server-side API key is missing.");
        }

        var timeoutSeconds = _options.TimeoutSeconds > 0 ? _options.TimeoutSeconds : 30;
        using var cts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        cts.CancelAfter(TimeSpan.FromSeconds(timeoutSeconds));

        try
        {
            // Assemble messages including the specialized system instruction prompt
            var messages = new List<OpenRouterMessagePayload>();

            if (!string.IsNullOrWhiteSpace(_options.SystemPrompt))
            {
                messages.Add(new OpenRouterMessagePayload("system", _options.SystemPrompt.Trim()));
            }

            foreach (var msg in prompt.Messages)
            {
                if (!string.IsNullOrWhiteSpace(msg.Content))
                {
                    messages.Add(new OpenRouterMessagePayload(msg.Role.ToLowerInvariant(), msg.Content.Trim()));
                }
            }

            var requestPayload = new OpenRouterRequestPayload(
                Model: _options.Model,
                Messages: messages,
                Temperature: _options.Temperature);

            var baseUrl = !string.IsNullOrWhiteSpace(_options.BaseUrl)
                ? _options.BaseUrl.TrimEnd('/')
                : "https://openrouter.ai/api/v1";

            var endpoint = $"{baseUrl}/chat/completions";

            using var request = new HttpRequestMessage(HttpMethod.Post, endpoint)
            {
                Content = JsonContent.Create(requestPayload, options: JsonOptions)
            };

            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);
            request.Headers.Add("HTTP-Referer", "https://mindora.app");
            request.Headers.Add("X-Title", "Mindora");

            _logger.LogInformation("Sending chat completion request to OpenRouter ({Model}). Message count: {Count}",
                _options.Model, messages.Count);

            var response = await _httpClient.SendAsync(request, cts.Token);

            if (!response.IsSuccessStatusCode)
            {
                var errorBody = await response.Content.ReadAsStringAsync(cts.Token);
                _logger.LogError("OpenRouter API returned HTTP {StatusCode}. Body: {Body}",
                    (int)response.StatusCode, errorBody);

                return new ChatAiResult(
                    $"[نمط احتياطي] تعذر استلام رد من نموذج الذكاء الاصطناعي (HTTP {(int)response.StatusCode}). يرجى المحاولة مرة أخرى.",
                    "fallback",
                    IsFallback: true,
                    ErrorDetail: $"HTTP {(int)response.StatusCode}");
            }

            var responsePayload = await response.Content.ReadFromJsonAsync<OpenRouterResponsePayload>(
                options: JsonOptions,
                cancellationToken: cts.Token);

            var reply = responsePayload?.Choices?.FirstOrDefault()?.Message?.Content?.Trim();
            var returnedModel = responsePayload?.Model ?? _options.Model;

            if (string.IsNullOrWhiteSpace(reply))
            {
                _logger.LogWarning("OpenRouter returned an empty message content.");
                return new ChatAiResult(
                    "[نمط احتياطي] وصل رد فارغ من مزود الذكاء الاصطناعي.",
                    "fallback",
                    IsFallback: true,
                    ErrorDetail: "Empty completion choice");
            }

            _logger.LogInformation("Successfully received reply from model: {Model}", returnedModel);

            return new ChatAiResult(
                Reply: reply,
                Model: returnedModel,
                IsFallback: false);
        }
        catch (OperationCanceledException) when (cts.IsCancellationRequested && !cancellationToken.IsCancellationRequested)
        {
            _logger.LogWarning("OpenRouter chat completion timed out after {Timeout}s.", timeoutSeconds);
            return new ChatAiResult(
                "[نمط احتياطي] استغرقت استجابة نموذج الذكاء الاصطناعي وقتاً أطول من المعتاد. يرجى المحاولة لاحقاً.",
                "fallback",
                IsFallback: true,
                ErrorDetail: "Timeout");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Exception encountered while invoking OpenRouter chat API.");
            return new ChatAiResult(
                "[نمط احتياطي] حدث خطأ أثناء الاتصال بمزود الذكاء الاصطناعي. يرجى التحقق من اتصال الإنترنت أو المحاولة لاحقاً.",
                "fallback",
                IsFallback: true,
                ErrorDetail: ex.Message);
        }
    }

    private record OpenRouterRequestPayload(
        string Model,
        List<OpenRouterMessagePayload> Messages,
        double Temperature);

    private record OpenRouterMessagePayload(
        string Role,
        string Content);

    private record OpenRouterResponsePayload(
        string? Id,
        string? Model,
        List<OpenRouterChoicePayload>? Choices);

    private record OpenRouterChoicePayload(
        OpenRouterMessagePayload? Message);
}
