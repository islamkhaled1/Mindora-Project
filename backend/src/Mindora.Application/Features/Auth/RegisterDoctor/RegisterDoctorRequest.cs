namespace Mindora.Application.Features.Auth.RegisterDoctor;

public record RegisterDoctorRequest(
    string Email,
    string Password,
    string FullName,
    string Specialization,
    string? ClinicName,
    string? LicenseNumber);
