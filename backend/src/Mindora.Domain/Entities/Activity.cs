using Mindora.Domain.Common;
using Mindora.Domain.Enums;

namespace Mindora.Domain.Entities;

/// <summary>
/// Represents a rehabilitation/support exercise or interactive game.
/// Categorized into Movement, Speech, or Attention domains.
/// </summary>
public class Activity : BaseEntity
{
    public string Title { get; private set; } = string.Empty;
    public string Description { get; private set; } = string.Empty;
    public ActivityDomain Domain { get; private set; }
    public DifficultyLevel BaseDifficulty { get; private set; }
    public string? AdaptiveSettingsJson { get; private set; }
    public bool IsActive { get; private set; }
    public DateTime CreatedAtUtc { get; private set; }

    // Parameterless constructor for ORM deserialization
    protected Activity() : base()
    {
    }

    public Activity(
        Guid id,
        string title,
        string description,
        ActivityDomain domain,
        DifficultyLevel baseDifficulty,
        string? adaptiveSettingsJson = null,
        bool isActive = true,
        DateTime? createdAtUtc = null) : base(id)
    {
        if (string.IsNullOrWhiteSpace(title))
        {
            throw new DomainException("Activity Title cannot be empty or whitespace.");
        }

        if (string.IsNullOrWhiteSpace(description))
        {
            throw new DomainException("Activity Description cannot be empty or whitespace.");
        }

        Title = title.Trim();
        Description = description.Trim();
        Domain = domain;
        BaseDifficulty = baseDifficulty;
        AdaptiveSettingsJson = adaptiveSettingsJson;
        IsActive = isActive;
        CreatedAtUtc = createdAtUtc ?? DateTime.UtcNow;
    }

    public static Activity Create(
        string title,
        string description,
        ActivityDomain domain,
        DifficultyLevel baseDifficulty,
        string? adaptiveSettingsJson = null,
        DateTime? createdAtUtc = null)
    {
        return new Activity(
            Guid.NewGuid(),
            title,
            description,
            domain,
            baseDifficulty,
            adaptiveSettingsJson,
            true,
            createdAtUtc);
    }

    public void UpdateDetails(string title, string description, DifficultyLevel baseDifficulty)
    {
        if (string.IsNullOrWhiteSpace(title))
        {
            throw new DomainException("Activity Title cannot be empty.");
        }

        if (string.IsNullOrWhiteSpace(description))
        {
            throw new DomainException("Activity Description cannot be empty.");
        }

        Title = title.Trim();
        Description = description.Trim();
        BaseDifficulty = baseDifficulty;
    }

    public void UpdateAdaptiveSettings(string? adaptiveSettingsJson)
    {
        AdaptiveSettingsJson = adaptiveSettingsJson;
    }

    public void Deactivate()
    {
        IsActive = false;
    }

    public void Activate()
    {
        IsActive = true;
    }
}
