using FluentValidation;

namespace Mindora.Application.Features.Children.LinkDoctor;

public class LinkDoctorByCodeValidator : AbstractValidator<LinkDoctorByCodeRequest>
{
    public LinkDoctorByCodeValidator()
    {
        RuleFor(x => x.DoctorCode)
            .NotEmpty().WithMessage("Doctor code is required.")
            .MaximumLength(50).WithMessage("Doctor code must not exceed 50 characters.");
    }
}
