using Mindora.Domain.Common;

namespace Mindora.Domain.Entities;

/// <summary>
/// Represents the professional clinical/therapist profile.
/// Reviews performance insights and monitors assigned children.
/// </summary>
public class DoctorProfile : BaseEntity
{
    public Guid UserId { get; private set; }
    public string Specialization { get; private set; } = string.Empty;
    public string? ClinicName { get; private set; }
    public string? LicenseNumber { get; private set; }
    public DateTime CreatedAtUtc { get; private set; }

    // Parameterless constructor for ORM deserialization
    protected DoctorProfile() : base()
    {
    }

    public DoctorProfile(
        Guid id,
        Guid userId,
        string specialization,
        string? clinicName = null,
        string? licenseNumber = null,
        DateTime? createdAtUtc = null) : base(id)
    {
        if (userId == Guid.Empty)
        {
            throw new DomainException("UserId cannot be empty for DoctorProfile.");
        }

        if (string.IsNullOrWhiteSpace(specialization))
        {
            throw new DomainException("Specialization is required for DoctorProfile.");
        }

        UserId = userId;
        Specialization = specialization.Trim();
        ClinicName = clinicName?.Trim();
        LicenseNumber = licenseNumber?.Trim();
        CreatedAtUtc = createdAtUtc ?? DateTime.UtcNow;
    }

    public static DoctorProfile Create(
        Guid userId,
        string specialization,
        string? clinicName = null,
        string? licenseNumber = null,
        DateTime? createdAtUtc = null)
    {
        return new DoctorProfile(Guid.NewGuid(), userId, specialization, clinicName, licenseNumber, createdAtUtc);
    }

    public void UpdateProfessionalDetails(string specialization, string? clinicName, string? licenseNumber)
    {
        if (string.IsNullOrWhiteSpace(specialization))
        {
            throw new DomainException("Specialization cannot be empty.");
        }

        Specialization = specialization.Trim();
        ClinicName = clinicName?.Trim();
        LicenseNumber = licenseNumber?.Trim();
    }
}
