namespace Mindora.Domain.Enums;

/// <summary>
/// Status of a parent-to-doctor connection request.
/// </summary>
public enum DoctorLinkRequestStatus
{
    Pending = 1,
    Approved = 2,
    Rejected = 3
}
