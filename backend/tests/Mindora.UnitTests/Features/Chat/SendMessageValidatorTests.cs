using FluentValidation.TestHelper;
using Mindora.Application.Features.Chat.SendMessage;
using Xunit;

namespace Mindora.UnitTests.Features.Chat;

public class SendMessageValidatorTests
{
    private readonly SendMessageValidator _validator = new();

    [Fact]
    public void Validator_Should_Fail_When_Message_Is_Empty()
    {
        var request = new SendMessageRequest("", null);
        var result = _validator.TestValidate(request);
        result.ShouldHaveValidationErrorFor(x => x.Message);
    }

    [Fact]
    public void Validator_Should_Fail_When_Message_Exceeds_MaxLength()
    {
        var longMessage = new string('a', 2001);
        var request = new SendMessageRequest(longMessage, null);
        var result = _validator.TestValidate(request);
        result.ShouldHaveValidationErrorFor(x => x.Message);
    }

    [Fact]
    public void Validator_Should_Pass_When_Message_Is_Valid()
    {
        var request = new SendMessageRequest("كيف أساعد طفلي على التركيز؟", null);
        var result = _validator.TestValidate(request);
        result.ShouldNotHaveAnyValidationErrors();
    }

    [Fact]
    public void Validator_Should_Fail_When_Conversation_Role_Is_Invalid()
    {
        var conversation = new List<ChatMessageDto>
        {
            new("invalid_role", "مرحبا")
        };
        var request = new SendMessageRequest("سؤال", conversation);
        var result = _validator.TestValidate(request);
        Assert.False(result.IsValid);
    }

    [Fact]
    public void Validator_Should_Pass_When_Conversation_Contains_Valid_Roles()
    {
        var conversation = new List<ChatMessageDto>
        {
            new("user", "مرحبا"),
            new("assistant", "أهلاً بك، كيف أساعدك اليوم؟")
        };
        var request = new SendMessageRequest("عندي سؤال بخصوص التمارين", conversation);
        var result = _validator.TestValidate(request);
        result.ShouldNotHaveAnyValidationErrors();
    }

    [Fact]
    public void Validator_Should_Fail_When_Conversation_Exceeds_50_Items()
    {
        var conversation = Enumerable.Range(1, 51)
            .Select(i => new ChatMessageDto(i % 2 == 0 ? "assistant" : "user", $"رسالة رقم {i}"))
            .ToList();

        var request = new SendMessageRequest("رسالة جديدة", conversation);
        var result = _validator.TestValidate(request);
        result.ShouldHaveValidationErrorFor(x => x.Conversation);
    }
}
