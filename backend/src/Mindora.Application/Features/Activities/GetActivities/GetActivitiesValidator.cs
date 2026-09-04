using FluentValidation;
using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Activities.GetActivities;

public class GetActivitiesValidator : AbstractValidator<GetActivitiesRequest>
{
    public GetActivitiesValidator()
    {
        RuleFor(x => x.Domain)
            .Must(d => string.IsNullOrWhiteSpace(d) || Enum.TryParse<ActivityDomain>(d, ignoreCase: true, out _))
            .WithMessage("Invalid domain filter. Supported domains are Movement, Speech, Attention.");

        RuleFor(x => x.Difficulty)
            .Must(diff => string.IsNullOrWhiteSpace(diff) || Enum.TryParse<DifficultyLevel>(diff, ignoreCase: true, out _))
            .WithMessage("Invalid difficulty filter. Supported difficulties are Beginner, Intermediate, Advanced.");
    }
}
