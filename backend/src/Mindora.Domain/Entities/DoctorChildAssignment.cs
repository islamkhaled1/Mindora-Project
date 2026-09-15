using Mindora.Domain.Common;

namespace Mindora.Domain.Entities;

/// <summary>
/// Links a professional/therapist (Doctor) to a child for performance monitoring.
/// </summary>
public class DoctorChildAssignment : BaseEntity
{
    public Guid DoctorId { get; private set; }
    public Guid ChildId { get; private set; }
    public DateTime AssignedAtUtc { get; private set; }
    public bool IsActive { get; private set; }
    public string? DoctorNotes { get; private set; }
    public DateTime? DoctorNotesUpdatedAtUtc { get; private set; }

    // Parameterless constructor for ORM deserialization
    protected DoctorChildAssignment() : base()
    {
    }

    public DoctorChildAssignment(
        Guid id,
        Guid doctorId,
        Guid childId,
        DateTime? assignedAtUtc = null,
        bool isActive = true,
        string? doctorNotes = null,
        DateTime? doctorNotesUpdatedAtUtc = null) : base(id)
    {
        if (doctorId == Guid.Empty)
        {
            throw new DomainException("DoctorId cannot be empty for DoctorChildAssignment.");
        }

        if (childId == Guid.Empty)
        {
            throw new DomainException("ChildId cannot be empty for DoctorChildAssignment.");
        }

        if (doctorNotes != null && doctorNotes.Length > 2000)
        {
            throw new DomainException("Doctor notes cannot exceed 2000 characters.");
        }

        DoctorId = doctorId;
        ChildId = childId;
        AssignedAtUtc = assignedAtUtc ?? DateTime.UtcNow;
        IsActive = isActive;
        DoctorNotes = string.IsNullOrWhiteSpace(doctorNotes) ? null : doctorNotes.Trim();
        DoctorNotesUpdatedAtUtc = doctorNotesUpdatedAtUtc;
    }

    public static DoctorChildAssignment Create(Guid doctorId, Guid childId, DateTime? assignedAtUtc = null)
    {
        return new DoctorChildAssignment(Guid.NewGuid(), doctorId, childId, assignedAtUtc, true);
    }

    public void Deactivate()
    {
        IsActive = false;
    }

    public void Reactivate()
    {
        IsActive = true;
    }

    public void UpdateDoctorNotes(string? notes, DateTime? updatedAtUtc = null)
    {
        if (notes != null && notes.Length > 2000)
        {
            throw new DomainException("Doctor notes cannot exceed 2000 characters.");
        }

        DoctorNotes = string.IsNullOrWhiteSpace(notes) ? null : notes.Trim();
        DoctorNotesUpdatedAtUtc = updatedAtUtc ?? DateTime.UtcNow;
    }
}
