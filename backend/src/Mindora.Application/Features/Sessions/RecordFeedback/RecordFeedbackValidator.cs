using FluentValidation;

namespace Mindora.Application.Features.Sessions.RecordFeedback;

public class RecordFeedbackValidator : AbstractValidator<RecordFeedbackRequest>
{
    public RecordFeedbackValidator()
    {
        RuleFor(x => x.Rating)
            .IsInEnum()
            .WithMessage("A valid parent sentiment rating (Easy, Medium, Difficult) is required.");

        RuleFor(x => x.Notes)
            .MaximumLength(1000)
            .WithMessage("Parent notes cannot exceed 1000 characters.");
    }
}
