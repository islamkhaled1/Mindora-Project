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

    // Parameterless constructor for ORM deserialization
    protected DoctorChildAssignment() : base()
    {
    }

    public DoctorChildAssignment(
        Guid id,
        Guid doctorId,
        Guid childId,
        DateTime? assignedAtUtc = null,
        bool isActive = true) : base(id)
    {
        if (doctorId == Guid.Empty)
        {
            throw new DomainException("DoctorId cannot be empty for DoctorChildAssignment.");
        }

        if (childId == Guid.Empty)
        {
            throw new DomainException("ChildId cannot be empty for DoctorChildAssignment.");
        }

        DoctorId = doctorId;
        ChildId = childId;
        AssignedAtUtc = assignedAtUtc ?? DateTime.UtcNow;
        IsActive = isActive;
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
}
