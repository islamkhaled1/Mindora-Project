using FluentValidation;

namespace Mindora.Application.Features.Doctor.LinkChild;

public class LinkChildValidator : AbstractValidator<LinkChildRequest>
{
    public LinkChildValidator()
    {
        RuleFor(x => x.LinkingCode)
            .NotEmpty()
            .WithMessage("Linking code is required.")
            .Length(3, 30)
            .WithMessage("Linking code length is invalid.");
    }
}
