using FluentValidation;

namespace Mindora.Application.Features.Assessments.RecordBaselineAssessment;

public class RecordBaselineAssessmentValidator : AbstractValidator<RecordBaselineAssessmentRequest>
{
    public RecordBaselineAssessmentValidator()
    {
        RuleFor(x => x.OverallScore)
            .InclusiveBetween(0m, 100m)
            .WithMessage("OverallScore must be between 0 and 100.");

        RuleFor(x => x.CognitiveScore)
            .InclusiveBetween(0m, 100m)
            .WithMessage("CognitiveScore must be between 0 and 100.");

        RuleFor(x => x.CommunicationScore)
            .InclusiveBetween(0m, 100m)
            .WithMessage("CommunicationScore must be between 0 and 100.");

        RuleFor(x => x.MotorScore)
            .InclusiveBetween(0m, 100m)
            .WithMessage("MotorScore must be between 0 and 100.");

        RuleFor(x => x.EmotionalScore)
            .InclusiveBetween(0m, 100m)
            .WithMessage("EmotionalScore must be between 0 and 100.");
    }
}
