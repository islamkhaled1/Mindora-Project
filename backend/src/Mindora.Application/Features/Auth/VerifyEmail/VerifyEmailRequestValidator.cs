using FluentValidation;

namespace Mindora.Application.Features.Auth.VerifyEmail;

public class VerifyEmailRequestValidator : AbstractValidator<VerifyEmailRequest>
{
    public VerifyEmailRequestValidator()
    {
        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("البريد الإلكتروني مطلوب.")
            .EmailAddress().WithMessage("صيغة البريد الإلكتروني غير صحيحة.");

        RuleFor(x => x.Otp)
            .NotEmpty().WithMessage("رمز التحقق مطلوب.")
            .Length(6).WithMessage("رمز التحقق يجب أن يتكون من 6 أرقام.")
            .Matches("^[0-9]{6}$").WithMessage("رمز التحقق يجب أن يحتوي على أرقام فقط.");
    }
}
