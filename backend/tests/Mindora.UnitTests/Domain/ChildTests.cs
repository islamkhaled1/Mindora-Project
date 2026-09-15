using Mindora.Domain.Common;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;
using Xunit;

namespace Mindora.UnitTests.Domain;

public class ChildTests
{
    private readonly Guid _parentId = Guid.NewGuid();

    [Fact]
    public void Child_With_Valid_Past_DateOfBirth_Is_Accepted()
    {
        // Arrange
        var birthDate = DateOnly.FromDateTime(DateTime.UtcNow.AddYears(-6));

        // Act
        var child = Child.Create(_parentId, "Leo Miller", birthDate);

        // Assert
        Assert.Equal("Leo Miller", child.FullName);
        Assert.Equal(birthDate, child.DateOfBirth);
        Assert.False(child.IsDeleted);
        Assert.Equal(DifficultyLevel.Beginner, child.CurrentMovementLevel);
    }

    [Fact]
    public void Child_DateOfBirth_In_Future_Throws_DomainException()
    {
        // Arrange
        var futureBirthDate = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(1));

        // Act & Assert
        var ex = Assert.Throws<DomainException>(() => Child.Create(_parentId, "Leo Miller", futureBirthDate));
        Assert.Contains("valid past date", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Child_DateOfBirth_Today_Throws_DomainException()
    {
        // Arrange
        var today = DateOnly.FromDateTime(DateTime.UtcNow);

        // Act & Assert
        var ex = Assert.Throws<DomainException>(() => Child.Create(_parentId, "Leo Miller", today));
        Assert.Contains("valid past date", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    [InlineData(null)]
    public void Empty_Child_FullName_Throws_DomainException(string? invalidName)
    {
        // Arrange
        var birthDate = DateOnly.FromDateTime(DateTime.UtcNow.AddYears(-5));

        // Act & Assert
        var ex = Assert.Throws<DomainException>(() => Child.Create(_parentId, invalidName!, birthDate));
        Assert.Contains("FullName cannot be empty", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Empty_ParentId_Throws_DomainException()
    {
        // Arrange
        var birthDate = DateOnly.FromDateTime(DateTime.UtcNow.AddYears(-5));

        // Act & Assert
        var ex = Assert.Throws<DomainException>(() => Child.Create(Guid.Empty, "Leo Miller", birthDate));
        Assert.Contains("ParentId cannot be empty", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void MarkAsDeleted_Sets_IsDeleted_To_True()
    {
        // Arrange
        var child = Child.Create(_parentId, "Leo Miller", DateOnly.FromDateTime(DateTime.UtcNow.AddYears(-5)));

        // Act
        child.MarkAsDeleted();

        // Assert
        Assert.True(child.IsDeleted);
    }

    [Fact]
    public void Restore_Sets_IsDeleted_To_False()
    {
        // Arrange
        var child = Child.Create(_parentId, "Leo Miller", DateOnly.FromDateTime(DateTime.UtcNow.AddYears(-5)));
        child.MarkAsDeleted();
        Assert.True(child.IsDeleted);

        // Act
        child.Restore();

        // Assert
        Assert.False(child.IsDeleted);
    }

    [Fact]
    public void UpdateLevels_Updates_All_Three_Domains()
    {
        // Arrange
        var child = Child.Create(_parentId, "Leo Miller", DateOnly.FromDateTime(DateTime.UtcNow.AddYears(-5)));

        // Act
        child.UpdateLevels(DifficultyLevel.Intermediate, DifficultyLevel.Advanced, DifficultyLevel.Intermediate);

        // Assert
        Assert.Equal(DifficultyLevel.Intermediate, child.CurrentMovementLevel);
        Assert.Equal(DifficultyLevel.Advanced, child.CurrentSpeechLevel);
        Assert.Equal(DifficultyLevel.Intermediate, child.CurrentAttentionLevel);
    }

    [Fact]
    public void Child_With_Extended_Profile_Fields_Sets_All_Properties()
    {
        // Arrange
        var birthDate = DateOnly.FromDateTime(DateTime.UtcNow.AddYears(-5));

        // Act
        var child = Child.Create(
            _parentId,
            "Leo Miller",
            birthDate,
            supportNotes: "Responsive to sound cues",
            currentMovementLevel: DifficultyLevel.Beginner,
            currentSpeechLevel: DifficultyLevel.Beginner,
            currentAttentionLevel: DifficultyLevel.Beginner,
            createdAtUtc: DateTime.UtcNow,
            gender: Gender.Boy,
            diagnosis: "ADHD",
            avatarUrl: "https://mindora.app/avatars/leo.png",
            supportLevel: SupportLevel.Mild,
            hearingStatus: SensoryStatus.Normal,
            visionStatus: SensoryStatus.Normal,
            focusDurationMinutes: 10,
            preferredPracticeTime: "Morning",
            preferredActivityType: ActivityTypePreference.Stories);

        // Assert
        Assert.Equal(Gender.Boy, child.Gender);
        Assert.Equal("ADHD", child.Diagnosis);
        Assert.Equal("https://mindora.app/avatars/leo.png", child.AvatarUrl);
        Assert.Equal(SupportLevel.Mild, child.SupportLevel);
        Assert.Equal(SensoryStatus.Normal, child.HearingStatus);
        Assert.Equal(SensoryStatus.Normal, child.VisionStatus);
        Assert.Equal(10, child.FocusDurationMinutes);
        Assert.Equal("Morning", child.PreferredPracticeTime);
        Assert.Equal(ActivityTypePreference.Stories, child.PreferredActivityType);
    }

    [Fact]
    public void Child_With_Excessive_Diagnosis_Length_Throws_DomainException()
    {
        // Arrange
        var birthDate = DateOnly.FromDateTime(DateTime.UtcNow.AddYears(-5));
        var excessiveDiagnosis = new string('A', 201);

        // Act & Assert
        var ex = Assert.Throws<DomainException>(() => Child.Create(
            _parentId, "Leo", birthDate, diagnosis: excessiveDiagnosis));
        Assert.Contains("diagnosis cannot exceed 200 characters", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Child_With_Invalid_FocusDuration_Throws_DomainException()
    {
        // Arrange
        var birthDate = DateOnly.FromDateTime(DateTime.UtcNow.AddYears(-5));

        // Act & Assert (Zero)
        Assert.Throws<DomainException>(() => Child.Create(
            _parentId, "Leo", birthDate, focusDurationMinutes: 0));

        // Act & Assert (> 240)
        Assert.Throws<DomainException>(() => Child.Create(
            _parentId, "Leo", birthDate, focusDurationMinutes: 250));
    }

    [Fact]
    public void UpdateProfile_With_Extended_Fields_Updates_Correctly()
    {
        // Arrange
        var child = Child.Create(_parentId, "Leo Miller", DateOnly.FromDateTime(DateTime.UtcNow.AddYears(-5)));

        // Act
        child.UpdateProfile(
            "Leo M.",
            DateOnly.FromDateTime(DateTime.UtcNow.AddYears(-5)),
            "Updated notes",
            gender: Gender.Boy,
            diagnosis: "Dyspraxia",
            avatarUrl: "https://avatar.png",
            supportLevel: SupportLevel.High,
            hearingStatus: SensoryStatus.Normal,
            visionStatus: SensoryStatus.HasDifficulty,
            focusDurationMinutes: 20,
            preferredPracticeTime: "Evening",
            preferredActivityType: ActivityTypePreference.Games);

        // Assert
        Assert.Equal("Leo M.", child.FullName);
        Assert.Equal(Gender.Boy, child.Gender);
        Assert.Equal("Dyspraxia", child.Diagnosis);
        Assert.Equal(SupportLevel.High, child.SupportLevel);
        Assert.Equal(SensoryStatus.HasDifficulty, child.VisionStatus);
        Assert.Equal(20, child.FocusDurationMinutes);
    }
}
