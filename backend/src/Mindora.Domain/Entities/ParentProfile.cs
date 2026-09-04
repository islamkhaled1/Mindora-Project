using Mindora.Domain.Common;

namespace Mindora.Domain.Entities;

/// <summary>
/// Represents the authenticated guardian profile.
/// Operates the child mode and exercises parental governance.
/// </summary>
public class ParentProfile : BaseEntity
{
    public Guid UserId { get; private set; }
    public string? PhoneNumber { get; private set; }
    public DateTime CreatedAtUtc { get; private set; }

    // Parameterless constructor for ORM deserialization
    protected ParentProfile() : base()
    {
    }

    public ParentProfile(Guid id, Guid userId, string? phoneNumber = null, DateTime? createdAtUtc = null) : base(id)
    {
        if (userId == Guid.Empty)
        {
            throw new DomainException("UserId cannot be empty for ParentProfile.");
        }

        UserId = userId;
        PhoneNumber = phoneNumber?.Trim();
        CreatedAtUtc = createdAtUtc ?? DateTime.UtcNow;
    }

    public static ParentProfile Create(Guid userId, string? phoneNumber = null, DateTime? createdAtUtc = null)
    {
        return new ParentProfile(Guid.NewGuid(), userId, phoneNumber, createdAtUtc);
    }

    public void UpdatePhoneNumber(string? phoneNumber)
    {
        PhoneNumber = phoneNumber?.Trim();
    }
}
