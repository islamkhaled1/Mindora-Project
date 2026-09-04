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
    }
}
