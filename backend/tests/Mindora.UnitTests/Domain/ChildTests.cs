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
}
