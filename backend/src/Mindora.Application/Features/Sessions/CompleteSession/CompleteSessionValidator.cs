using FluentValidation;
using Mindora.Application.Features.Sessions.RecordMetrics;

namespace Mindora.Application.Features.Sessions.CompleteSession;

public class CompleteSessionValidator : AbstractValidator<CompleteSessionRequest>
{
    public CompleteSessionValidator()
    {
        RuleFor(x => x.ActualDurationSeconds)
            .GreaterThanOrEqualTo(0)
            .WithMessage("ActualDurationSeconds cannot be negative.");

        When(x => x.Metrics != null && x.Metrics.Count > 0, () =>
        {
            RuleForEach(x => x.Metrics!)
                .SetValidator(new RecordMetricsValidator.MetricItemValidator());
        });

        RuleFor(x => x.ParentRating)
            .IsInEnum().When(x => x.ParentRating.HasValue)
            .WithMessage("Invalid parent rating value.");

        RuleFor(x => x.ParentNotes)
            .MaximumLength(1000).WithMessage("Parent notes must not exceed 1000 characters.");
    }
}
