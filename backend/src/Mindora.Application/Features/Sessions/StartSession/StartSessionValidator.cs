using FluentValidation;

namespace Mindora.Application.Features.Sessions.StartSession;

public class StartSessionValidator : AbstractValidator<StartSessionRequest>
{
    public StartSessionValidator()
    {
        RuleFor(x => x.ChildId)
            .NotEmpty().WithMessage("ChildId is required.");

        RuleFor(x => x.ActivityId)
            .NotEmpty().WithMessage("ActivityId is required.");
    }
}
