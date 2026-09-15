using System.Net;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using Mindora.Application.Common.Interfaces;
using Mindora.Infrastructure.Ai;
using Xunit;

namespace Mindora.UnitTests.Features.Chat;

public class GeminiChatClientTests
{
    private class FakeHttpMessageHandler : HttpMessageHandler
    {
        private readonly Func<HttpRequestMessage, CancellationToken, Task<HttpResponseMessage>> _handler;

        public FakeHttpMessageHandler(Func<HttpRequestMessage, CancellationToken, Task<HttpResponseMessage>> handler)
        {
            _handler = handler;
        }

        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            return _handler(request, cancellationToken);
        }
    }

    private class TestLogger<T> : ILogger<T>
    {
        public List<string> LoggedMessages { get; } = new();

        public IDisposable? BeginScope<TState>(TState state) where TState : notnull => null;

        public bool IsEnabled(LogLevel logLevel) => true;

        public void Log<TState>(LogLevel logLevel, EventId eventId, TState state, Exception? exception, Func<TState, Exception?, string> formatter)
        {
            LoggedMessages.Add(formatter(state, exception));
        }
    }

    [Fact]
    public async Task Client_Returns_Fallback_When_ApiKey_Is_Missing()
    {
        var prevEnv = Environment.GetEnvironmentVariable("GEMINI_API_KEY");
        try
        {
            Environment.SetEnvironmentVariable("GEMINI_API_KEY", null);

            var options = Options.Create(new ChatOptions { ApiKey = null });
            var client = new GeminiChatClient(
                new HttpClient(),
                options,
                NullLogger<GeminiChatClient>.Instance);

            var prompt = new ChatAiPrompt(new List<ChatAiMessage> { new("user", "مرحبا") });
            var result = await client.SendChatCompletionAsync(prompt);

            Assert.True(result.IsFallback);
            Assert.Equal("fallback", result.Model);
            Assert.Contains("[نمط احتياطي]", result.Reply);
            Assert.Equal("Server-side API key is missing.", result.ErrorDetail);
        }
        finally
        {
            Environment.SetEnvironmentVariable("GEMINI_API_KEY", prevEnv);
        }
    }

    [Fact]
    public async Task Client_Loads_ApiKey_From_Environment_Variable()
    {
        var prevEnv = Environment.GetEnvironmentVariable("GEMINI_API_KEY");
        try
        {
            const string testEnvKey = "env-secret-test-key-xyz";
            Environment.SetEnvironmentVariable("GEMINI_API_KEY", testEnvKey);

            HttpRequestMessage? capturedRequest = null;
            var messageHandler = new FakeHttpMessageHandler((req, ct) =>
            {
                capturedRequest = req;
                var json = JsonSerializer.Serialize(new
                {
                    candidates = new[]
                    {
                        new
                        {
                            content = new { parts = new[] { new { text = "أهلاً بك" } }, role = "model" },
                            finishReason = "STOP"
                        }
                    },
                    modelVersion = "gemini-3.6-flash"
                });

                return Task.FromResult(new HttpResponseMessage(HttpStatusCode.OK)
                {
                    Content = new StringContent(json, Encoding.UTF8, "application/json")
                });
            });

            var httpClient = new HttpClient(messageHandler);
            var options = Options.Create(new ChatOptions { ApiKey = null }); // No key in options
            var client = new GeminiChatClient(httpClient, options, NullLogger<GeminiChatClient>.Instance);

            var prompt = new ChatAiPrompt(new List<ChatAiMessage> { new("user", "مرحبا") });
            var result = await client.SendChatCompletionAsync(prompt);

            Assert.False(result.IsFallback);
            Assert.NotNull(capturedRequest);
            Assert.True(capturedRequest.Headers.Contains("x-goog-api-key"));
            Assert.Equal(testEnvKey, capturedRequest.Headers.GetValues("x-goog-api-key").First());
        }
        finally
        {
            Environment.SetEnvironmentVariable("GEMINI_API_KEY", prevEnv);
        }
    }

    [Fact]
    public async Task Client_Constructs_Correct_Request_Url_And_Header()
    {
        HttpRequestMessage? capturedRequest = null;
        var messageHandler = new FakeHttpMessageHandler((req, ct) =>
        {
            capturedRequest = req;
            var json = JsonSerializer.Serialize(new
            {
                candidates = new[]
                {
                    new
                    {
                        content = new { parts = new[] { new { text = "رد سليم" } }, role = "model" },
                        finishReason = "STOP"
                    }
                },
                modelVersion = "gemini-3.6-flash"
            });

            return Task.FromResult(new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent(json, Encoding.UTF8, "application/json")
            });
        });

        var httpClient = new HttpClient(messageHandler);
        var options = Options.Create(new ChatOptions
        {
            ApiKey = "test-header-key",
            BaseUrl = "https://generativelanguage.googleapis.com/v1beta",
            Model = "gemini-3.6-flash"
        });

        var client = new GeminiChatClient(httpClient, options, NullLogger<GeminiChatClient>.Instance);
        var prompt = new ChatAiPrompt(new List<ChatAiMessage> { new("user", "سؤال") });
        await client.SendChatCompletionAsync(prompt);

        Assert.NotNull(capturedRequest);
        Assert.Equal("https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent", capturedRequest.RequestUri?.ToString());
        Assert.False(capturedRequest.RequestUri?.Query.Contains("key="));
        Assert.True(capturedRequest.Headers.Contains("x-goog-api-key"));
        Assert.Equal("test-header-key", capturedRequest.Headers.GetValues("x-goog-api-key").First());
    }

    [Fact]
    public async Task Client_Applies_System_Instruction_And_Maps_History_Correctly()
    {
        string? capturedBody = null;
        var messageHandler = new FakeHttpMessageHandler(async (req, ct) =>
        {
            capturedBody = await req.Content!.ReadAsStringAsync(ct);
            var json = JsonSerializer.Serialize(new
            {
                candidates = new[]
                {
                    new
                    {
                        content = new { parts = new[] { new { text = "الرد التدريبي" } }, role = "model" },
                        finishReason = "STOP"
                    }
                },
                modelVersion = "gemini-3.6-flash"
            });

            return new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent(json, Encoding.UTF8, "application/json")
            };
        });

        var httpClient = new HttpClient(messageHandler);
        var options = Options.Create(new ChatOptions
        {
            ApiKey = "test-key",
            SystemPrompt = "تعليمات النظام الطبية الإرشادية",
            Temperature = 0.7,
            MaxOutputTokens = 1024
        });

        var client = new GeminiChatClient(httpClient, options, NullLogger<GeminiChatClient>.Instance);
        var prompt = new ChatAiPrompt(new List<ChatAiMessage>
        {
            new("user", "كيف أبدأ التمارين؟"),
            new("assistant", "ابدأ بتمارين التوازن الخفيفة."),
            new("user", "وماذا عن وقت التمرين؟")
        });

        var result = await client.SendChatCompletionAsync(prompt);

        Assert.False(result.IsFallback);
        Assert.Equal("الرد التدريبي", result.Reply);
        Assert.Equal("gemini-3.6-flash", result.Model);

        Assert.NotNull(capturedBody);
        using var doc = JsonDocument.Parse(capturedBody);
        var root = doc.RootElement;

        // Verify system_instruction
        Assert.True(root.TryGetProperty("system_instruction", out var sysInstruction));
        var sysText = sysInstruction.GetProperty("parts")[0].GetProperty("text").GetString();
        Assert.Equal("تعليمات النظام الطبية الإرشادية", sysText);

        // Verify contents and role mapping: user -> user, assistant -> model
        Assert.True(root.TryGetProperty("contents", out var contents));
        Assert.Equal(3, contents.GetArrayLength());

        Assert.Equal("user", contents[0].GetProperty("role").GetString());
        Assert.Equal("كيف أبدأ التمارين؟", contents[0].GetProperty("parts")[0].GetProperty("text").GetString());

        Assert.Equal("model", contents[1].GetProperty("role").GetString());
        Assert.Equal("ابدأ بتمارين التوازن الخفيفة.", contents[1].GetProperty("parts")[0].GetProperty("text").GetString());

        Assert.Equal("user", contents[2].GetProperty("role").GetString());
        Assert.Equal("وماذا عن وقت التمرين؟", contents[2].GetProperty("parts")[0].GetProperty("text").GetString());

        // Verify generationConfig
        Assert.True(root.TryGetProperty("generationConfig", out var genConfig));
        Assert.Equal(0.7, genConfig.GetProperty("temperature").GetDouble());
        Assert.Equal(1024, genConfig.GetProperty("maxOutputTokens").GetInt32());
    }

    [Theory]
    [InlineData(HttpStatusCode.BadRequest)]
    [InlineData(HttpStatusCode.Unauthorized)]
    [InlineData(HttpStatusCode.Forbidden)]
    [InlineData((HttpStatusCode)429)] // Too Many Requests
    [InlineData(HttpStatusCode.InternalServerError)]
    [InlineData(HttpStatusCode.ServiceUnavailable)]
    public async Task Client_Handles_Http_Errors_Gracefully_With_Fallback(HttpStatusCode statusCode)
    {
        var messageHandler = new FakeHttpMessageHandler((req, ct) =>
        {
            var res = new HttpResponseMessage(statusCode)
            {
                Content = new StringContent("{\"error\":{\"message\":\"Rate limit exceeded or error\"}}", Encoding.UTF8, "application/json")
            };
            return Task.FromResult(res);
        });

        var httpClient = new HttpClient(messageHandler);
        var options = Options.Create(new ChatOptions { ApiKey = "test-key" });
        var client = new GeminiChatClient(httpClient, options, NullLogger<GeminiChatClient>.Instance);

        var prompt = new ChatAiPrompt(new List<ChatAiMessage> { new("user", "مرحبا") });
        var result = await client.SendChatCompletionAsync(prompt);

        Assert.True(result.IsFallback);
        Assert.Equal("fallback", result.Model);
        Assert.Contains("[نمط احتياطي]", result.Reply);
        Assert.Contains($"HTTP {(int)statusCode}", result.ErrorDetail);
    }

    [Fact]
    public async Task Client_Handles_Timeout_Gracefully_With_Fallback()
    {
        var messageHandler = new FakeHttpMessageHandler(async (req, ct) =>
        {
            // Simulate delay longer than timeout
            await Task.Delay(100, ct);
            return new HttpResponseMessage(HttpStatusCode.OK);
        });

        var httpClient = new HttpClient(messageHandler);
        var options = Options.Create(new ChatOptions
        {
            ApiKey = "test-key",
            TimeoutSeconds = 0 // Will default to 30 or we test with cancellation token
        });

        using var cts = new CancellationTokenSource();
        var client = new GeminiChatClient(httpClient, options, NullLogger<GeminiChatClient>.Instance);

        // Cancel after 1ms to trigger timeout
        cts.CancelAfter(TimeSpan.FromMilliseconds(5));

        var prompt = new ChatAiPrompt(new List<ChatAiMessage> { new("user", "مرحبا") });
        var result = await client.SendChatCompletionAsync(prompt, cts.Token);

        Assert.True(result.IsFallback);
        Assert.Equal("fallback", result.Model);
        Assert.Contains("[نمط احتياطي]", result.Reply);
    }

    [Fact]
    public async Task Client_Handles_Malformed_Or_Empty_Response_Safely()
    {
        var messageHandler = new FakeHttpMessageHandler((req, ct) =>
        {
            var res = new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent("{}", Encoding.UTF8, "application/json")
            };
            return Task.FromResult(res);
        });

        var httpClient = new HttpClient(messageHandler);
        var options = Options.Create(new ChatOptions { ApiKey = "test-key" });
        var client = new GeminiChatClient(httpClient, options, NullLogger<GeminiChatClient>.Instance);

        var prompt = new ChatAiPrompt(new List<ChatAiMessage> { new("user", "مرحبا") });
        var result = await client.SendChatCompletionAsync(prompt);

        Assert.True(result.IsFallback);
        Assert.Equal("fallback", result.Model);
        Assert.Contains("رد فارغ", result.Reply);
    }

    [Fact]
    public async Task Client_Never_Logs_Api_Key_Even_On_Failure()
    {
        const string secretKey = "super-confidential-gemini-key-12345";
        var logger = new TestLogger<GeminiChatClient>();

        var messageHandler = new FakeHttpMessageHandler((req, ct) =>
        {
            var res = new HttpResponseMessage(HttpStatusCode.InternalServerError)
            {
                Content = new StringContent("Server Error with details", Encoding.UTF8, "text/plain")
            };
            return Task.FromResult(res);
        });

        var httpClient = new HttpClient(messageHandler);
        var options = Options.Create(new ChatOptions { ApiKey = secretKey });
        var client = new GeminiChatClient(httpClient, options, logger);

        var prompt = new ChatAiPrompt(new List<ChatAiMessage> { new("user", "مرحبا") });
        await client.SendChatCompletionAsync(prompt);

        foreach (var logMessage in logger.LoggedMessages)
        {
            Assert.DoesNotContain(secretKey, logMessage);
        }
    }

    [Fact]
    public async Task SendMessageHandler_With_GeminiChatClient_Preserves_Contract_And_Response()
    {
        var jsonResponse = JsonSerializer.Serialize(new
        {
            candidates = new[]
            {
                new
                {
                    content = new { parts = new[] { new { text = "نصيحة تفاعلية من جيميني" } }, role = "model" },
                    finishReason = "STOP"
                }
            },
            modelVersion = "gemini-3.6-flash"
        });

        var messageHandler = new FakeHttpMessageHandler((req, ct) =>
        {
            var res = new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent(jsonResponse, Encoding.UTF8, "application/json")
            };
            return Task.FromResult(res);
        });

        var httpClient = new HttpClient(messageHandler);
        var options = Options.Create(new ChatOptions
        {
            ApiKey = "test-key",
            Model = "gemini-3.6-flash",
            SystemPrompt = "أنت مساعد ميندورا الذكي"
        });

        var client = new GeminiChatClient(httpClient, options, NullLogger<GeminiChatClient>.Instance);

        var currentUser = new TestCurrentUserService { IsAuthenticated = true, UserId = Guid.NewGuid() };
        var validator = new Mindora.Application.Features.Chat.SendMessage.SendMessageValidator();
        var handler = new Mindora.Application.Features.Chat.SendMessage.SendMessageHandler(currentUser, client, validator);

        var conversation = new List<Mindora.Application.Features.Chat.SendMessage.ChatMessageDto>
        {
            new("user", "مرحبا"),
            new("assistant", "أهلاً بك يا بطل")
        };
        var request = new Mindora.Application.Features.Chat.SendMessage.SendMessageRequest("كيف أدرب طفلي؟", conversation);

        var response = await handler.HandleAsync(request);

        Assert.NotNull(response);
        Assert.Equal("نصيحة تفاعلية من جيميني", response.Reply);
        Assert.Equal("assistant", response.Role);
        Assert.Equal("gemini-3.6-flash", response.Model);
        Assert.False(response.IsFallback);
        Assert.True(response.CreatedAtUtc <= DateTime.UtcNow);
    }

    [Fact]
    public async Task SendMessageHandler_With_GeminiChatClient_Propagates_IsFallback_True_On_Error()
    {
        var messageHandler = new FakeHttpMessageHandler((req, ct) =>
        {
            var res = new HttpResponseMessage(HttpStatusCode.InternalServerError)
            {
                Content = new StringContent("Internal Server Error", Encoding.UTF8, "text/plain")
            };
            return Task.FromResult(res);
        });

        var httpClient = new HttpClient(messageHandler);
        var options = Options.Create(new ChatOptions { ApiKey = "test-key" });
        var client = new GeminiChatClient(httpClient, options, NullLogger<GeminiChatClient>.Instance);

        var currentUser = new TestCurrentUserService { IsAuthenticated = true, UserId = Guid.NewGuid() };
        var validator = new Mindora.Application.Features.Chat.SendMessage.SendMessageValidator();
        var handler = new Mindora.Application.Features.Chat.SendMessage.SendMessageHandler(currentUser, client, validator);

        var request = new Mindora.Application.Features.Chat.SendMessage.SendMessageRequest("كيف أدرب طفلي؟", null);
        var response = await handler.HandleAsync(request);

        Assert.NotNull(response);
        Assert.True(response.IsFallback);
        Assert.Equal("fallback", response.Model);
        Assert.Contains("[نمط احتياطي]", response.Reply);
    }

    private class TestCurrentUserService : ICurrentUserService
    {
        public Guid? UserId { get; set; } = Guid.NewGuid();
        public Mindora.Domain.Enums.UserRole? Role { get; set; } = Mindora.Domain.Enums.UserRole.Parent;
        public string? Email { get; set; } = "parent@mindora.com";
        public bool IsAuthenticated { get; set; } = true;
    }
}
