using Mindora.Domain.Common;
using Mindora.Domain.Enums;

namespace Mindora.Domain.Entities;

/// <summary>
/// Represents the individual receiving developmental rehabilitation and support.
/// Note: The Child does not have an independent login; the authenticated Parent operates Child Mode.
/// </summary>
public class Child : BaseEntity
{
    public Guid ParentId { get; private set; }
    public string FullName { get; private set; } = string.Empty;
    public DateOnly DateOfBirth { get; private set; }
    public string? SupportNotes { get; private set; }
    public DifficultyLevel CurrentMovementLevel { get; private set; }
    public DifficultyLevel CurrentSpeechLevel { get; private set; }
    public DifficultyLevel CurrentAttentionLevel { get; private set; }
    public bool IsDeleted { get; private set; }
    public DateTime CreatedAtUtc { get; private set; }

    // Parameterless constructor for ORM deserialization
    protected Child() : base()
    {
    }

    public Child(
        Guid id,
        Guid parentId,
        string fullName,
        DateOnly dateOfBirth,
        string? supportNotes = null,
        DifficultyLevel currentMovementLevel = DifficultyLevel.Beginner,
        DifficultyLevel currentSpeechLevel = DifficultyLevel.Beginner,
        DifficultyLevel currentAttentionLevel = DifficultyLevel.Beginner,
        bool isDeleted = false,
        DateTime? createdAtUtc = null) : base(id)
    {
        if (parentId == Guid.Empty)
        {
            throw new DomainException("ParentId cannot be empty for Child.");
        }

        ValidateFullName(fullName);
        ValidateDateOfBirth(dateOfBirth);

        ParentId = parentId;
        FullName = fullName.Trim();
        DateOfBirth = dateOfBirth;
        SupportNotes = supportNotes?.Trim();
        CurrentMovementLevel = currentMovementLevel;
        CurrentSpeechLevel = currentSpeechLevel;
        CurrentAttentionLevel = currentAttentionLevel;
        IsDeleted = isDeleted;
        CreatedAtUtc = createdAtUtc ?? DateTime.UtcNow;
    }

    public static Child Create(
        Guid parentId,
        string fullName,
        DateOnly dateOfBirth,
        string? supportNotes = null,
        DifficultyLevel currentMovementLevel = DifficultyLevel.Beginner,
        DifficultyLevel currentSpeechLevel = DifficultyLevel.Beginner,
        DifficultyLevel currentAttentionLevel = DifficultyLevel.Beginner,
        DateTime? createdAtUtc = null)
    {
        return new Child(
            Guid.NewGuid(),
            parentId,
            fullName,
            dateOfBirth,
            supportNotes,
            currentMovementLevel,
            currentSpeechLevel,
            currentAttentionLevel,
            false,
            createdAtUtc);
    }

    public void UpdateProfile(string fullName, DateOnly dateOfBirth, string? supportNotes)
    {
        ValidateFullName(fullName);
        ValidateDateOfBirth(dateOfBirth);

        FullName = fullName.Trim();
        DateOfBirth = dateOfBirth;
        SupportNotes = supportNotes?.Trim();
    }

    public void UpdateLevels(DifficultyLevel movement, DifficultyLevel speech, DifficultyLevel attention)
    {
        CurrentMovementLevel = movement;
        CurrentSpeechLevel = speech;
        CurrentAttentionLevel = attention;
    }

    public void MarkAsDeleted()
    {
        IsDeleted = true;
    }

    public void Restore()
    {
        IsDeleted = false;
    }

    private static void ValidateFullName(string fullName)
    {
        if (string.IsNullOrWhiteSpace(fullName))
        {
            throw new DomainException("Child FullName cannot be empty or whitespace.");
        }
    }

    private static void ValidateDateOfBirth(DateOnly dateOfBirth)
    {
        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        if (dateOfBirth >= today)
        {
            throw new DomainException("Child date of birth must be a valid past date.");
        }
    }
}
