using FluentValidation;
using Mindora.Application.Features.Sessions.Models;

namespace Mindora.Application.Features.Sessions.RecordMetrics;

public class RecordMetricsValidator : AbstractValidator<RecordMetricsRequest>
{
    private static readonly HashSet<string> SupportedMetricTypes = new(StringComparer.OrdinalIgnoreCase)
    {
        "RepetitionCount",
        "AccuracyPercentage",
        "ReactionTimeMs",
        "SpeechClarityScore",
        "ResponseLatencyMs",
        "AttentionDurationSeconds"
    };

    public RecordMetricsValidator()
    {
        RuleFor(x => x.Metrics)
            .NotEmpty().WithMessage("At least one performance metric must be provided.");

        RuleForEach(x => x.Metrics)
            .SetValidator(new MetricItemValidator());
    }

    public class MetricItemValidator : AbstractValidator<MetricInputDto>
    {
        public MetricItemValidator()
        {
            RuleFor(m => m.MetricType)
                .NotEmpty().WithMessage("MetricType is required.")
                .Must(type => SupportedMetricTypes.Contains(type))
                .WithMessage(m => $"Unsupported metric type '{m.MetricType}'. Supported types are: {string.Join(", ", SupportedMetricTypes)}.");

            When(m => string.Equals(m.MetricType, "AccuracyPercentage", StringComparison.OrdinalIgnoreCase), () =>
            {
                RuleFor(m => m.Value)
                    .InclusiveBetween(0m, 100m)
                    .WithMessage("AccuracyPercentage must be between 0 and 100.");
            });

            When(m => string.Equals(m.MetricType, "SpeechClarityScore", StringComparison.OrdinalIgnoreCase), () =>
            {
                RuleFor(m => m.Value)
                    .InclusiveBetween(0m, 100m)
                    .WithMessage("SpeechClarityScore must be between 0 and 100.");
            });

            When(m => string.Equals(m.MetricType, "RepetitionCount", StringComparison.OrdinalIgnoreCase), () =>
            {
                RuleFor(m => m.Value)
                    .GreaterThanOrEqualTo(0m)
                    .WithMessage("RepetitionCount cannot be negative.");
            });

            When(m => string.Equals(m.MetricType, "ReactionTimeMs", StringComparison.OrdinalIgnoreCase), () =>
            {
                RuleFor(m => m.Value)
                    .GreaterThanOrEqualTo(0m)
                    .WithMessage("ReactionTimeMs cannot be negative.");
            });

            When(m => string.Equals(m.MetricType, "ResponseLatencyMs", StringComparison.OrdinalIgnoreCase), () =>
            {
                RuleFor(m => m.Value)
                    .GreaterThanOrEqualTo(0m)
                    .WithMessage("ResponseLatencyMs cannot be negative.");
            });

            When(m => string.Equals(m.MetricType, "AttentionDurationSeconds", StringComparison.OrdinalIgnoreCase), () =>
            {
                RuleFor(m => m.Value)
                    .GreaterThanOrEqualTo(0m)
                    .WithMessage("AttentionDurationSeconds cannot be negative.");
            });
        }
    }
}
