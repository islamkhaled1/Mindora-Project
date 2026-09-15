using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Features.Chat.SendMessage;
using Mindora.Domain.Enums;
using Xunit;

namespace Mindora.UnitTests.Features.Chat;

public class SendMessageHandlerTests
{
    private class TestCurrentUserService : ICurrentUserService
    {
        public Guid? UserId { get; set; } = Guid.NewGuid();
        public UserRole? Role { get; set; } = UserRole.Parent;
        public string? Email { get; set; } = "parent@mindora.com";
        public bool IsAuthenticated { get; set; } = true;
    }

    private class TestChatAiClient : IChatAiClient
    {
        public ChatAiPrompt? LastPrompt { get; private set; }
        public ChatAiResult ResultToReturn { get; set; } =
            new("نصيحة لتأهيل النطق والتخاطب", "meta-llama/llama-3.1-8b-instruct", false);

        public Task<ChatAiResult> SendChatCompletionAsync(ChatAiPrompt prompt, CancellationToken cancellationToken = default)
        {
            LastPrompt = prompt;
            return Task.FromResult(ResultToReturn);
        }
    }

    [Fact]
    public async Task Handler_Throws_UnauthorizedException_When_User_Not_Authenticated()
    {
        var currentUser = new TestCurrentUserService { IsAuthenticated = false, UserId = null };
        var chatClient = new TestChatAiClient();
        var validator = new SendMessageValidator();
        var handler = new SendMessageHandler(currentUser, chatClient, validator);

        var request = new SendMessageRequest("مرحبا", null);

        await Assert.ThrowsAsync<UnauthorizedException>(() => handler.HandleAsync(request));
    }

    [Fact]
    public async Task Handler_Throws_ValidationException_When_Message_Is_Empty()
    {
        var currentUser = new TestCurrentUserService();
        var chatClient = new TestChatAiClient();
        var validator = new SendMessageValidator();
        var handler = new SendMessageHandler(currentUser, chatClient, validator);

        var request = new SendMessageRequest("", null);

        await Assert.ThrowsAsync<ValidationException>(() => handler.HandleAsync(request));
    }

    [Fact]
    public async Task Handler_Builds_Context_And_Returns_Successful_Response()
    {
        var currentUser = new TestCurrentUserService();
        var chatClient = new TestChatAiClient();
        var validator = new SendMessageValidator();
        var handler = new SendMessageHandler(currentUser, chatClient, validator);

        var conversation = new List<ChatMessageDto>
        {
            new("user", "كيف أساعد طفلي؟"),
            new("assistant", "يمكنك استخدام التكرار البصري والتشجيع المستمر.")
        };
        var request = new SendMessageRequest("وماذا عن النطق؟", conversation);

        var response = await handler.HandleAsync(request);

        Assert.NotNull(response);
        Assert.Equal("نصيحة لتأهيل النطق والتخاطب", response.Reply);
        Assert.Equal("assistant", response.Role);
        Assert.Equal("meta-llama/llama-3.1-8b-instruct", response.Model);
        Assert.False(response.IsFallback);

        // Verify that prior conversation turns plus the new user message were bundled
        Assert.NotNull(chatClient.LastPrompt);
        Assert.Equal(3, chatClient.LastPrompt.Messages.Count);
        Assert.Equal("user", chatClient.LastPrompt.Messages[0].Role);
        Assert.Equal("كيف أساعد طفلي؟", chatClient.LastPrompt.Messages[0].Content);
        Assert.Equal("assistant", chatClient.LastPrompt.Messages[1].Role);
        Assert.Equal("يمكنك استخدام التكرار البصري والتشجيع المستمر.", chatClient.LastPrompt.Messages[1].Content);
        Assert.Equal("user", chatClient.LastPrompt.Messages[2].Role);
        Assert.Equal("وماذا عن النطق؟", chatClient.LastPrompt.Messages[2].Content);
    }
}
