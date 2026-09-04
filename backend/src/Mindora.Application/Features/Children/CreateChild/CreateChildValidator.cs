using FluentValidation;

namespace Mindora.Application.Features.Children.CreateChild;

public class CreateChildValidator : AbstractValidator<CreateChildRequest>
{
    public CreateChildValidator()
    {
        RuleFor(x => x.FullName)
            .NotEmpty().WithMessage("Child full name is required.")
            .MaximumLength(150).WithMessage("Child full name must not exceed 150 characters.");

        RuleFor(x => x.DateOfBirth)
            .NotEmpty().WithMessage("Date of birth is required.")
            .Must(dob => dob < DateOnly.FromDateTime(DateTime.UtcNow))
            .WithMessage("Date of birth must be a valid past date.");

        RuleFor(x => x.BaselineMovementLevel)
            .IsInEnum().WithMessage("Invalid baseline movement level.");

        RuleFor(x => x.BaselineSpeechLevel)
            .IsInEnum().WithMessage("Invalid baseline speech level.");

        RuleFor(x => x.BaselineAttentionLevel)
            .IsInEnum().WithMessage("Invalid baseline attention level.");
    }
}
