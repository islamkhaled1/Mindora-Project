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

        RuleFor(x => x.SupportNotes)
            .MaximumLength(2000).WithMessage("Support notes must not exceed 2000 characters.");

        RuleFor(x => x.Gender)
            .IsInEnum().When(x => x.Gender.HasValue)
            .WithMessage("Invalid gender value.");

        RuleFor(x => x.Diagnosis)
            .MaximumLength(200).WithMessage("Diagnosis must not exceed 200 characters.");

        RuleFor(x => x.AvatarUrl)
            .MaximumLength(500).WithMessage("Avatar URL must not exceed 500 characters.");

        RuleFor(x => x.SupportLevel)
            .IsInEnum().When(x => x.SupportLevel.HasValue)
            .WithMessage("Invalid support level value.");

        RuleFor(x => x.HearingStatus)
            .IsInEnum().When(x => x.HearingStatus.HasValue)
            .WithMessage("Invalid hearing status value.");

        RuleFor(x => x.VisionStatus)
            .IsInEnum().When(x => x.VisionStatus.HasValue)
            .WithMessage("Invalid vision status value.");

        RuleFor(x => x.FocusDurationMinutes)
            .InclusiveBetween(1, 240).When(x => x.FocusDurationMinutes.HasValue)
            .WithMessage("Focus duration must be between 1 and 240 minutes.");

        RuleFor(x => x.PreferredPracticeTime)
            .MaximumLength(100).WithMessage("Preferred practice time must not exceed 100 characters.");

        RuleFor(x => x.PreferredActivityType)
            .IsInEnum().When(x => x.PreferredActivityType.HasValue)
            .WithMessage("Invalid preferred activity type value.");
    }
}
