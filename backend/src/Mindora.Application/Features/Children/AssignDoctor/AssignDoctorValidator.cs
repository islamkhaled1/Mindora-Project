using FluentValidation;

namespace Mindora.Application.Features.Children.AssignDoctor;

public class AssignDoctorValidator : AbstractValidator<AssignDoctorRequest>
{
    public AssignDoctorValidator()
    {
        RuleFor(x => x.DoctorId)
            .NotEmpty().WithMessage("DoctorId is required.");
    }
}
