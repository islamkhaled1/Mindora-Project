using Mindora.Domain.Common;
using Mindora.Domain.Enums;

namespace Mindora.Domain.Entities;

/// <summary>
/// Represents a pending or resolved connection request from a Parent to link a Child with a Doctor.
/// Requires explicit Doctor approval before DoctorChildAssignment is created.
/// </summary>
public class DoctorLinkRequest : BaseEntity
{
    public Guid DoctorId { get; private set; }
    public Guid ParentId { get; private set; }
    public Guid ChildId { get; private set; }
    public DoctorLinkRequestStatus Status { get; private set; }
    public DateTime CreatedAtUtc { get; private set; }
    public DateTime? RespondedAtUtc { get; private set; }

    // Parameterless constructor for ORM deserialization
    protected DoctorLinkRequest() : base()
    {
    }

    public DoctorLinkRequest(
        Guid id,
        Guid doctorId,
        Guid parentId,
        Guid childId,
        DoctorLinkRequestStatus status = DoctorLinkRequestStatus.Pending,
        DateTime? createdAtUtc = null,
        DateTime? respondedAtUtc = null) : base(id)
    {
        if (doctorId == Guid.Empty)
        {
            throw new DomainException("DoctorId cannot be empty for DoctorLinkRequest.");
        }

        if (parentId == Guid.Empty)
        {
            throw new DomainException("ParentId cannot be empty for DoctorLinkRequest.");
        }

        if (childId == Guid.Empty)
        {
            throw new DomainException("ChildId cannot be empty for DoctorLinkRequest.");
        }

        DoctorId = doctorId;
        ParentId = parentId;
        ChildId = childId;
        Status = status;
        CreatedAtUtc = createdAtUtc ?? DateTime.UtcNow;
        RespondedAtUtc = respondedAtUtc;
    }

    public static DoctorLinkRequest Create(
        Guid doctorId,
        Guid parentId,
        Guid childId,
        DateTime? createdAtUtc = null)
    {
        return new DoctorLinkRequest(
            Guid.NewGuid(),
            doctorId,
            parentId,
            childId,
            DoctorLinkRequestStatus.Pending,
            createdAtUtc ?? DateTime.UtcNow,
            null);
    }

    public void Approve(DateTime? respondedAtUtc = null)
    {
        if (Status != DoctorLinkRequestStatus.Pending)
        {
            throw new DomainException($"Cannot approve a request with status '{Status}'. Only Pending requests can be approved.");
        }

        Status = DoctorLinkRequestStatus.Approved;
        RespondedAtUtc = respondedAtUtc ?? DateTime.UtcNow;
    }

    public void Reject(DateTime? respondedAtUtc = null)
    {
        if (Status != DoctorLinkRequestStatus.Pending)
        {
            throw new DomainException($"Cannot reject a request with status '{Status}'. Only Pending requests can be rejected.");
        }

        Status = DoctorLinkRequestStatus.Rejected;
        RespondedAtUtc = respondedAtUtc ?? DateTime.UtcNow;
    }
}
