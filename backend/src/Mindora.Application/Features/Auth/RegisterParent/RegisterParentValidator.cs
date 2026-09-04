using FluentValidation;

namespace Mindora.Application.Features.Auth.RegisterParent;

public class RegisterParentValidator : AbstractValidator<RegisterParentRequest>
{
    public RegisterParentValidator()
    {
        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email is required.")
            .EmailAddress().WithMessage("A valid email address is required.")
            .MaximumLength(256);

        RuleFor(x => x.Password)
            .NotEmpty().WithMessage("Password is required.")
            .MinimumLength(8).WithMessage("Password must be at least 8 characters.");

        RuleFor(x => x.FullName)
            .NotEmpty().WithMessage("FullName is required.")
            .MaximumLength(200);

        RuleFor(x => x.PhoneNumber)
            .MaximumLength(30);
    }
}
