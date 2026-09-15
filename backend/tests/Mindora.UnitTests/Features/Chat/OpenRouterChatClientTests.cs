using System.Net;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using Mindora.Application.Common.Interfaces;
using Mindora.Infrastructure.Ai;
using Xunit;

namespace Mindora.UnitTests.Features.Chat;

public class OpenRouterChatClientTests
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

    [Fact]
    public async Task Client_Returns_Fallback_When_ApiKey_Is_Missing()
    {
        var prevEnv = Environment.GetEnvironmentVariable("OPENROUTER_API_KEY");
        try
        {
            Environment.SetEnvironmentVariable("OPENROUTER_API_KEY", null);

            var options = Options.Create(new ChatOptions { ApiKey = null });
            var client = new OpenRouterChatClient(
                new HttpClient(),
                options,
                NullLogger<OpenRouterChatClient>.Instance);

            var prompt = new ChatAiPrompt(new List<ChatAiMessage> { new("user", "مرحبا") });
            var result = await client.SendChatCompletionAsync(prompt);

            Assert.True(result.IsFallback);
            Assert.Equal("fallback", result.Model);
            Assert.Contains("[نمط احتياطي]", result.Reply);
        }
        finally
        {
            Environment.SetEnvironmentVariable("OPENROUTER_API_KEY", prevEnv);
        }
    }

    [Fact]
    public async Task Client_Parses_Successful_Response_From_OpenRouter()
    {
        var jsonResponse = JsonSerializer.Serialize(new
        {
            id = "gen-123",
            model = "meta-llama/llama-3.1-8b-instruct",
            choices = new[]
            {
                new
                {
                    message = new
                    {
                        role = "assistant",
                        content = "التدريب اليومي المستمر مفيد جداً للطفل."
                    }
                }
            }
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
            Model = "meta-llama/llama-3.1-8b-instruct"
        });

        var client = new OpenRouterChatClient(
            httpClient,
            options,
            NullLogger<OpenRouterChatClient>.Instance);

        var prompt = new ChatAiPrompt(new List<ChatAiMessage> { new("user", "كيف أساعد طفلي؟") });
        var result = await client.SendChatCompletionAsync(prompt);

        Assert.False(result.IsFallback);
        Assert.Equal("meta-llama/llama-3.1-8b-instruct", result.Model);
        Assert.Equal("التدريب اليومي المستمر مفيد جداً للطفل.", result.Reply);
    }

    [Fact]
    public async Task Client_Handles_Http_Error_Gracefully_With_Fallback()
    {
        var messageHandler = new FakeHttpMessageHandler((req, ct) =>
        {
            var res = new HttpResponseMessage(HttpStatusCode.ServiceUnavailable)
            {
                Content = new StringContent("Service Down", Encoding.UTF8, "text/plain")
            };
            return Task.FromResult(res);
        });

        var httpClient = new HttpClient(messageHandler);
        var options = Options.Create(new ChatOptions
        {
            ApiKey = "test-key",
            Model = "meta-llama/llama-3.1-8b-instruct"
        });

        var client = new OpenRouterChatClient(
            httpClient,
            options,
            NullLogger<OpenRouterChatClient>.Instance);

        var prompt = new ChatAiPrompt(new List<ChatAiMessage> { new("user", "مرحبا") });
        var result = await client.SendChatCompletionAsync(prompt);

        Assert.True(result.IsFallback);
        Assert.Equal("fallback", result.Model);
        Assert.Contains("[نمط احتياطي]", result.Reply);
    }
}
