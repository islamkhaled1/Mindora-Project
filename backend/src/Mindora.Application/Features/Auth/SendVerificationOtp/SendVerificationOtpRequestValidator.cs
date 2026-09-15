using FluentValidation;

namespace Mindora.Application.Features.Auth.SendVerificationOtp;

public class SendVerificationOtpRequestValidator : AbstractValidator<SendVerificationOtpRequest>
{
    public SendVerificationOtpRequestValidator()
    {
        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("البريد الإلكتروني مطلوب.")
            .EmailAddress().WithMessage("صيغة البريد الإلكتروني غير صحيحة.")
            .MaximumLength(256).WithMessage("البريد الإلكتروني طويل جداً.");
    }
}
