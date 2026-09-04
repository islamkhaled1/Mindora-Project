using FluentValidation;

namespace Mindora.Application.Features.Auth.RegisterDoctor;

public class RegisterDoctorValidator : AbstractValidator<RegisterDoctorRequest>
{
    public RegisterDoctorValidator()
    {
        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email is required.")
            .EmailAddress().WithMessage("A valid email address is required.")
            .MaximumLength(256);

        RuleFor(x => x.Password)
            .NotEmpty().WithMessage("Password is required.")
            .MinimumLength(8).WithMessage("Password must be at least 8 characters.");

        RuleFor(x => x.FullName)
            .NotEmpty().WithMessage("FullName is required.")
            .MaximumLength(200);

        RuleFor(x => x.Specialization)
            .NotEmpty().WithMessage("Specialization is required.")
            .MaximumLength(150);

        RuleFor(x => x.ClinicName)
            .MaximumLength(200);

        RuleFor(x => x.LicenseNumber)
            .MaximumLength(100);
    }
}
