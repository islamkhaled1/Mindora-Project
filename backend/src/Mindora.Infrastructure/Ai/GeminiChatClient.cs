using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Mindora.Application.Common.Interfaces;

namespace Mindora.Infrastructure.Ai;

/// <summary>
/// Production client connecting to Google Gemini API (gemini-3.6-flash).
/// All API credentials are maintained strictly server-side via runtime environment variable GEMINI_API_KEY.
/// </summary>
public class GeminiChatClient : IChatAiClient
{
    private readonly HttpClient _httpClient;
    private readonly ChatOptions _options;
    private readonly ILogger<GeminiChatClient> _logger;

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull
    };

    public GeminiChatClient(
        HttpClient httpClient,
        IOptions<ChatOptions> options,
        ILogger<GeminiChatClient> logger)
    {
        _httpClient = httpClient;
        _options = options.Value;
        _logger = logger;
    }

    public async Task<ChatAiResult> SendChatCompletionAsync(
        ChatAiPrompt prompt,
        CancellationToken cancellationToken = default)
    {
        // Strictly server-side API key resolution: Options -> GEMINI_API_KEY environment variable
        var apiKey = !string.IsNullOrWhiteSpace(_options.ApiKey)
            ? _options.ApiKey.Trim()
            : Environment.GetEnvironmentVariable("GEMINI_API_KEY")?.Trim();

        if (string.IsNullOrWhiteSpace(apiKey))
        {
            _logger.LogWarning("Gemini API key is not configured on the server. Falling back to intelligent domain fallback mode.");
            return GetIntelligentFallbackResponse(prompt, "Server-side API key is missing.");
        }

        var timeoutSeconds = _options.TimeoutSeconds > 0 ? _options.TimeoutSeconds : 30;
        using var cts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        cts.CancelAfter(TimeSpan.FromSeconds(timeoutSeconds));

        try
        {
            // System instruction payload
            GeminiContentPayload? systemInstruction = null;
            if (!string.IsNullOrWhiteSpace(_options.SystemPrompt))
            {
                systemInstruction = new GeminiContentPayload(
                    Role: null,
                    Parts: new List<GeminiPartPayload> { new(_options.SystemPrompt.Trim()) });
            }

            // Map conversational turns: user -> "user", assistant -> "model"
            var contents = new List<GeminiContentPayload>();
            foreach (var msg in prompt.Messages)
            {
                if (string.IsNullOrWhiteSpace(msg.Content))
                {
                    continue;
                }

                var role = msg.Role.Trim().ToLowerInvariant() switch
                {
                    "assistant" => "model",
                    "model" => "model",
                    _ => "user"
                };

                contents.Add(new GeminiContentPayload(
                    Role: role,
                    Parts: new List<GeminiPartPayload> { new(msg.Content.Trim()) }));
            }

            if (contents.Count == 0)
            {
                return new ChatAiResult(
                    "[نمط احتياطي] لا يوجد محتوى كافٍ لإرسال الطلب إلى مزود الذكاء الاصطناعي.",
                    "fallback",
                    IsFallback: true,
                    ErrorDetail: "Empty prompt messages");
            }

            var maxOutputTokens = _options.MaxOutputTokens > 0 ? _options.MaxOutputTokens : 1024;
            var generationConfig = new GeminiGenerationConfig(
                Temperature: _options.Temperature,
                MaxOutputTokens: maxOutputTokens);

            var requestPayload = new GeminiGenerateContentRequest(
                Contents: contents,
                SystemInstruction: systemInstruction,
                GenerationConfig: generationConfig);

            var baseUrl = !string.IsNullOrWhiteSpace(_options.BaseUrl)
                ? _options.BaseUrl.TrimEnd('/')
                : "https://generativelanguage.googleapis.com/v1beta";

            var model = !string.IsNullOrWhiteSpace(_options.Model)
                ? _options.Model.Trim()
                : "gemini-3.6-flash";

            var endpoint = $"{baseUrl}/models/{model}:generateContent";

            using var request = new HttpRequestMessage(HttpMethod.Post, endpoint)
            {
                Content = JsonContent.Create(requestPayload, options: JsonOptions)
            };

            // Use x-goog-api-key header strictly (never in URL query string)
            request.Headers.Add("x-goog-api-key", apiKey);

            _logger.LogInformation("Sending chat completion request to Gemini ({Model}). Content turn count: {Count}",
                model, contents.Count);

            var response = await _httpClient.SendAsync(request, cts.Token);

            if (!response.IsSuccessStatusCode)
            {
                var statusCode = (int)response.StatusCode;
                _logger.LogError("Gemini API returned non-success HTTP status code: {StatusCode}", statusCode);

                return new ChatAiResult(
                    $"[نمط احتياطي] تعذر استلام رد من نموذج الذكاء الاصطناعي (HTTP {statusCode}). يرجى المحاولة مرة أخرى.",
                    "fallback",
                    IsFallback: true,
                    ErrorDetail: $"HTTP {statusCode}");
            }

            var responsePayload = await response.Content.ReadFromJsonAsync<GeminiGenerateContentResponse>(
                options: JsonOptions,
                cancellationToken: cts.Token);

            var reply = responsePayload?.Candidates?
                .FirstOrDefault()?.Content?.Parts?
                .FirstOrDefault()?.Text?.Trim();

            var returnedModel = !string.IsNullOrWhiteSpace(responsePayload?.ModelVersion)
                ? responsePayload.ModelVersion
                : model;

            if (string.IsNullOrWhiteSpace(reply))
            {
                _logger.LogWarning("Gemini returned an empty candidate or text part.");
                return new ChatAiResult(
                    "[نمط احتياطي] وصل رد فارغ من مزود الذكاء الاصطناعي.",
                    "fallback",
                    IsFallback: true,
                    ErrorDetail: "Empty completion candidate");
            }

            _logger.LogInformation("Successfully received reply from Gemini model: {Model}", returnedModel);

            return new ChatAiResult(
                Reply: reply,
                Model: returnedModel,
                IsFallback: false);
        }
        catch (OperationCanceledException) when (cts.IsCancellationRequested && !cancellationToken.IsCancellationRequested)
        {
            _logger.LogWarning("Gemini chat completion timed out after {Timeout}s.", timeoutSeconds);
            return new ChatAiResult(
                "[نمط احتياطي] استغرقت استجابة نموذج الذكاء الاصطناعي وقتاً أطول من المعتاد. يرجى المحاولة لاحقاً.",
                "fallback",
                IsFallback: true,
                ErrorDetail: "Timeout");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Exception encountered while invoking Gemini chat API.");
            return new ChatAiResult(
                "[نمط احتياطي] حدث خطأ أثناء الاتصال بمزود الذكاء الاصطناعي. يرجى التحقق من اتصال الإنترنت أو المحاولة لاحقاً.",
                "fallback",
                IsFallback: true,
                ErrorDetail: ex.Message);
        }
    }

    private static ChatAiResult GetIntelligentFallbackResponse(ChatAiPrompt prompt, string errorDetail)
    {
        var lastUserMessage = prompt.Messages.LastOrDefault(m => m.Role == "user")?.Content?.Trim() ?? string.Empty;
        var lower = lastUserMessage.ToLowerInvariant();

        string advice;

        if (lower.Contains("ازيك") || lower.Contains("ازي") || lower.Contains("مرحبا") || lower.Contains("أهلا") || lower.Contains("اهلا") || lower.Contains("سلام") || lower.Contains("صباح الخير") || lower.Contains("مساء الخير") || lower.Contains("الو") || lower.Contains("إلو") || lower.Contains("عامل ايه") || lower.Contains("هاي"))
        {
            advice = "أهلاً بحضرتك وبطلنا الصغير! أنا رفيقك ومساعدك في Mindora. إزاي أقدر أساعدك النهاردة في التمارين أو متابعة تطور طفلك؟ 🌟";
        }
        else if (lower.Contains("يد") || lower.Contains("يدين") || lower.Contains("أصابع") || lower.Contains("اصابع") || lower.Contains("عضلات اليد") || lower.Contains("مسك") || lower.Contains("قبضة"))
        {
            advice = "تمارين ممتازة لتقوية عضلات اليدين والأصابع لبطلنا الصغير:\n\n" +
                     "1. اللعب بالصلصال الطبيعي: الضغط عليه وتشكيل كرات صغيرة لتنشيط عضلات الكف.\n" +
                     "2. المشابك الملونة: مسك المشابك بالسبابة والإبهام ونقلها لتثبيتها على طبق ورقي.\n" +
                     "3. تمزيق ولصق الورق الملون: نشاط ممتع لتقوية التآزر البصري الحركي.\n\n" +
                     "💡 نصيحة: ابدأ بجلسة قصيرة (5-10 دقائق) في جو من المرح والتشجيع المستمر 💜";
        }
        else if (lower.Contains("نطق") || lower.Contains("كلام") || lower.Contains("تخاطب") || lower.Contains("صوت") || lower.Contains("كلمات") || lower.Contains("حرف") || lower.Contains("حروف") || lower.Contains("يتكلم"))
        {
            advice = "نصائح عملية لدعم وتطوير النطق والتواصل اليومي:\n\n" +
                     "1. التواصل البصري المباشر: انزل لمستوى نظر طفلك وتحدث معه بهدوء ووضوح.\n" +
                     "2. التسمية المستمرة: سمّ الأشياء التي يستخدمها في روتينه (مية، كورة، ملعقة).\n" +
                     "3. تشجيع المحاولات: احتفل بأي صوت أو مقطع يصدره وكرره أمامه بحماس.\n" +
                     "4. القصص المصورة: أشر للصور واسأله عنها وشجعه على التعبير.\n\n" +
                     "🎈 كل خطوة صوتية هي إنجاز رائع يستحق الدعم!";
        }
        else if (lower.Contains("حرك") || lower.Contains("حركة") || lower.Contains("توازن") || lower.Contains("مشي") || lower.Contains("وقوف") || lower.Contains("عضلات"))
        {
            advice = "أنشطة تحفيزية ممتازة لتطوير المهارات الحركية والتوازن:\n\n" +
                     "1. خط التوازن: الصق شريطاً ملوناً على الأرض وشجعه على المشي فوقه كأنه جسر ألعاب.\n" +
                     "2. تجاوز العقبات: وضع وسائد صغيرة للقفز حولها أو المرور فوقها.\n" +
                     "3. رمي واستلام الكرة: كرات إسفنجية خفيفة لتقوية التناسق الحركي.\n\n" +
                     "✨ استمر في تشجيعه والاحتفال بكل حركة ناجحة!";
        }
        else if (lower.Contains("تمرين") || lower.Contains("تمارين") || lower.Contains("نشاط") || lower.Contains("أنشطة") || lower.Contains("لعب") || lower.Contains("العاب"))
        {
            advice = "اقتراحات أنشطة وتمارين يومية مفيدة وممتعة:\n\n" +
                     "• ألعاب التركيب والمكعبات: لتنمية الإدراك وحل المشكلات البسيطة.\n" +
                     "• التلوين بالأصابع: نشاط حسي رائع وممتع جداً.\n" +
                     "• فرز الألوان والأشكال: تصنيف الكرات أو الأشكال في سلال ملونة.\n\n" +
                     "🌟 تقدر تبدأ الآن بتمرين من قائمة تمارين اليوم في الصفحة الرئيسية!";
        }
        else
        {
            advice = "أهلاً بحضرتك! رفيقك في Mindora معاك خطوة بخطوة لدعم بطلنا الصغير 💜.\n\n" +
                     "أنا هنا لمساعدتك في كل ما يخص:\n" +
                     "• تمارين تقوية عضلات اليدين والأصابع\n" +
                     "• نصائح تطوير النطق والتواصل اليومي\n" +
                     "• أنشطة التوازن والمهارات الحركية والإدراكية\n\n" +
                     "إيه الاستفسار أو المهارة اللي تحب نركز عليها النهاردة؟ 🌟";
        }

        return new ChatAiResult(
            $"[نمط احتياطي] {advice}",
            "fallback",
            IsFallback: true,
            ErrorDetail: errorDetail);
    }

    public record GeminiGenerateContentRequest(
        [property: JsonPropertyName("contents")] List<GeminiContentPayload> Contents,
        [property: JsonPropertyName("system_instruction")] GeminiContentPayload? SystemInstruction,
        [property: JsonPropertyName("generationConfig")] GeminiGenerationConfig? GenerationConfig);

    public record GeminiContentPayload(
        [property: JsonPropertyName("role")] string? Role,
        [property: JsonPropertyName("parts")] List<GeminiPartPayload> Parts);

    public record GeminiPartPayload(
        [property: JsonPropertyName("text")] string Text);

    public record GeminiGenerationConfig(
        [property: JsonPropertyName("temperature")] double Temperature,
        [property: JsonPropertyName("maxOutputTokens")] int MaxOutputTokens);

    public record GeminiGenerateContentResponse(
        [property: JsonPropertyName("candidates")] List<GeminiCandidatePayload>? Candidates,
        [property: JsonPropertyName("modelVersion")] string? ModelVersion);

    public record GeminiCandidatePayload(
        [property: JsonPropertyName("content")] GeminiContentPayload? Content,
        [property: JsonPropertyName("finishReason")] string? FinishReason);
}
