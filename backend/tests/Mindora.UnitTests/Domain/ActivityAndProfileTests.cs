using Mindora.Domain.Common;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;
using Xunit;

namespace Mindora.UnitTests.Domain;

public class ActivityAndProfileTests
{
    [Theory]
    [InlineData("", "Description")]
    [InlineData("   ", "Description")]
    [InlineData("Title", "")]
    [InlineData("Title", "   ")]
    public void Activity_With_Empty_Title_Or_Description_Throws_DomainException(string title, string description)
    {
        // Act & Assert
        Assert.Throws<DomainException>(() =>
            Activity.Create(title, description, ActivityDomain.Movement, DifficultyLevel.Beginner));
    }

    [Fact]
    public void ParentProfile_With_Empty_UserId_Throws_DomainException()
    {
        // Act & Assert
        Assert.Throws<DomainException>(() => ParentProfile.Create(Guid.Empty));
    }

    [Fact]
    public void ParentProfile_With_Valid_UserId_Is_Created()
    {
        // Arrange
        var userId = Guid.NewGuid();

        // Act
        var profile = ParentProfile.Create(userId, "+123456789");

        // Assert
        Assert.Equal(userId, profile.UserId);
        Assert.Equal("+123456789", profile.PhoneNumber);
    }

    [Fact]
    public void DoctorProfile_With_Empty_UserId_Or_Specialization_Throws_DomainException()
    {
        // Act & Assert
        Assert.Throws<DomainException>(() =>
            DoctorProfile.Create(Guid.Empty, "Pediatric Occupational Therapist"));

        Assert.Throws<DomainException>(() =>
            DoctorProfile.Create(Guid.NewGuid(), "   "));
    }

    [Fact]
    public void DoctorProfile_With_Valid_Data_Is_Created()
    {
        // Arrange
        var userId = Guid.NewGuid();

        // Act
        var doctor = DoctorProfile.Create(userId, "Speech-Language Pathologist", "Children's Therapy Center", "LIC-98765");

        // Assert
        Assert.Equal(userId, doctor.UserId);
        Assert.Equal("Speech-Language Pathologist", doctor.Specialization);
        Assert.Equal("Children's Therapy Center", doctor.ClinicName);
        Assert.Equal("LIC-98765", doctor.LicenseNumber);
    }

    [Fact]
    public void DoctorChildAssignment_With_Empty_Ids_Throws_DomainException()
    {
        // Act & Assert
        Assert.Throws<DomainException>(() =>
            DoctorChildAssignment.Create(Guid.Empty, Guid.NewGuid()));

        Assert.Throws<DomainException>(() =>
            DoctorChildAssignment.Create(Guid.NewGuid(), Guid.Empty));
    }

    [Fact]
    public void DoctorChildAssignment_Can_Deactivate_And_Reactivate()
    {
        // Arrange
        var assignment = DoctorChildAssignment.Create(Guid.NewGuid(), Guid.NewGuid());
        Assert.True(assignment.IsActive);

        // Act & Assert
        assignment.Deactivate();
        Assert.False(assignment.IsActive);

        assignment.Reactivate();
        Assert.True(assignment.IsActive);
    }
}
