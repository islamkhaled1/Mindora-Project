using FluentValidation;

namespace Mindora.Application.Features.Doctor.Notes;

public class UpdateDoctorNotesValidator : AbstractValidator<UpdateDoctorNotesRequest>
{
    public UpdateDoctorNotesValidator()
    {
        RuleFor(x => x.Notes)
            .MaximumLength(2000)
            .WithMessage("Doctor notes cannot exceed 2000 characters.");
    }
}
