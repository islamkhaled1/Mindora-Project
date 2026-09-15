using FluentValidation;
using Mindora.Application.Features.Auth.Models;

namespace Mindora.Application.Features.Auth.Login;

public class GoogleLoginValidator : AbstractValidator<GoogleLoginRequest>
{
    public GoogleLoginValidator()
    {
        RuleFor(x => x.IdToken)
            .NotEmpty().WithMessage("Google ID Token is required.");
    }
}
