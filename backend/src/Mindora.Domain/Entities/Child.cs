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

    // P0 Extended Profile Fields from UI Audit
    public Gender? Gender { get; private set; }
    public string? Diagnosis { get; private set; }
    public string? AvatarUrl { get; private set; }
    public SupportLevel? SupportLevel { get; private set; }
    public SensoryStatus? HearingStatus { get; private set; }
    public SensoryStatus? VisionStatus { get; private set; }
    public int? FocusDurationMinutes { get; private set; }
    public string? PreferredPracticeTime { get; private set; }
    public ActivityTypePreference? PreferredActivityType { get; private set; }

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
        DateTime? createdAtUtc = null,
        Gender? gender = null,
        string? diagnosis = null,
        string? avatarUrl = null,
        SupportLevel? supportLevel = null,
        SensoryStatus? hearingStatus = null,
        SensoryStatus? visionStatus = null,
        int? focusDurationMinutes = null,
        string? preferredPracticeTime = null,
        ActivityTypePreference? preferredActivityType = null) : base(id)
    {
        if (parentId == Guid.Empty)
        {
            throw new DomainException("ParentId cannot be empty for Child.");
        }

        ValidateFullName(fullName);
        ValidateDateOfBirth(dateOfBirth);
        ValidateOptionalProfileFields(diagnosis, avatarUrl, focusDurationMinutes, preferredPracticeTime);

        ParentId = parentId;
        FullName = fullName.Trim();
        DateOfBirth = dateOfBirth;
        SupportNotes = supportNotes?.Trim();
        CurrentMovementLevel = currentMovementLevel;
        CurrentSpeechLevel = currentSpeechLevel;
        CurrentAttentionLevel = currentAttentionLevel;
        IsDeleted = isDeleted;
        CreatedAtUtc = createdAtUtc ?? DateTime.UtcNow;

        Gender = gender;
        Diagnosis = diagnosis?.Trim();
        AvatarUrl = avatarUrl?.Trim();
        SupportLevel = supportLevel;
        HearingStatus = hearingStatus;
        VisionStatus = visionStatus;
        FocusDurationMinutes = focusDurationMinutes;
        PreferredPracticeTime = preferredPracticeTime?.Trim();
        PreferredActivityType = preferredActivityType;
    }

    public static Child Create(
        Guid parentId,
        string fullName,
        DateOnly dateOfBirth,
        string? supportNotes = null,
        DifficultyLevel currentMovementLevel = DifficultyLevel.Beginner,
        DifficultyLevel currentSpeechLevel = DifficultyLevel.Beginner,
        DifficultyLevel currentAttentionLevel = DifficultyLevel.Beginner,
        DateTime? createdAtUtc = null,
        Gender? gender = null,
        string? diagnosis = null,
        string? avatarUrl = null,
        SupportLevel? supportLevel = null,
        SensoryStatus? hearingStatus = null,
        SensoryStatus? visionStatus = null,
        int? focusDurationMinutes = null,
        string? preferredPracticeTime = null,
        ActivityTypePreference? preferredActivityType = null)
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
            createdAtUtc,
            gender,
            diagnosis,
            avatarUrl,
            supportLevel,
            hearingStatus,
            visionStatus,
            focusDurationMinutes,
            preferredPracticeTime,
            preferredActivityType);
    }

    public void UpdateProfile(
        string fullName,
        DateOnly dateOfBirth,
        string? supportNotes,
        Gender? gender = null,
        string? diagnosis = null,
        string? avatarUrl = null,
        SupportLevel? supportLevel = null,
        SensoryStatus? hearingStatus = null,
        SensoryStatus? visionStatus = null,
        int? focusDurationMinutes = null,
        string? preferredPracticeTime = null,
        ActivityTypePreference? preferredActivityType = null)
    {
        ValidateFullName(fullName);
        ValidateDateOfBirth(dateOfBirth);
        ValidateOptionalProfileFields(diagnosis, avatarUrl, focusDurationMinutes, preferredPracticeTime);

        FullName = fullName.Trim();
        DateOfBirth = dateOfBirth;
        SupportNotes = supportNotes?.Trim();
        Gender = gender;
        Diagnosis = diagnosis?.Trim();
        AvatarUrl = avatarUrl?.Trim();
        SupportLevel = supportLevel;
        HearingStatus = hearingStatus;
        VisionStatus = visionStatus;
        FocusDurationMinutes = focusDurationMinutes;
        PreferredPracticeTime = preferredPracticeTime?.Trim();
        PreferredActivityType = preferredActivityType;
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

    private static void ValidateOptionalProfileFields(
        string? diagnosis,
        string? avatarUrl,
        int? focusDurationMinutes,
        string? preferredPracticeTime)
    {
        if (diagnosis != null && diagnosis.Length > 200)
        {
            throw new DomainException("Child diagnosis cannot exceed 200 characters.");
        }

        if (avatarUrl != null && avatarUrl.Length > 500)
        {
            throw new DomainException("Child avatar URL cannot exceed 500 characters.");
        }

        if (preferredPracticeTime != null && preferredPracticeTime.Length > 100)
        {
            throw new DomainException("Child preferred practice time cannot exceed 100 characters.");
        }

        if (focusDurationMinutes.HasValue && (focusDurationMinutes.Value <= 0 || focusDurationMinutes.Value > 240))
        {
            throw new DomainException("Focus duration must be between 1 and 240 minutes.");
        }
    }
}
