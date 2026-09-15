using FluentValidation;

namespace Mindora.Application.Features.Chat.SendMessage;

public class SendMessageValidator : AbstractValidator<SendMessageRequest>
{
    private static readonly HashSet<string> AllowedRoles = new(StringComparer.OrdinalIgnoreCase)
    {
        "user",
        "assistant",
        "system"
    };

    public SendMessageValidator()
    {
        RuleFor(x => x.Message)
            .Cascade(CascadeMode.Stop)
            .NotEmpty().WithMessage("نص الرسالة مطلوب ولا يمكن أن يكون فارغاً.")
            .MaximumLength(2000).WithMessage("لا يمكن أن يتجاوز طول الرسالة 2000 حرف.");

        When(x => x.Conversation != null, () =>
        {
            RuleFor(x => x.Conversation!)
                .Must(c => c.Count <= 50)
                .WithMessage("تجاوزت المحادثة الحد الأقصى المسموح به لعدد الرسائل (50 رسالة).");

            RuleForEach(x => x.Conversation!).ChildRules(item =>
            {
                item.RuleFor(m => m.Role)
                    .NotEmpty().WithMessage("دور الرسالة مطلوب.")
                    .Must(role => AllowedRoles.Contains(role.Trim()))
                    .WithMessage("دور الرسالة غير صالح (يجب أن يكون user أو assistant).");

                item.RuleFor(m => m.Content)
                    .NotEmpty().WithMessage("محتوى الرسالة في سجل المحادثة لا يمكن أن يكون فارغاً.")
                    .MaximumLength(4000).WithMessage("لا يمكن أن يتجاوز طول الرسالة في السجل 4000 حرف.");
            });
        });
    }
}
