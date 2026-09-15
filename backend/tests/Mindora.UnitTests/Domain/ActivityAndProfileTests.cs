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
        Assert.StartsWith("DR-", doctor.ReferralCode);
    }

    [Fact]
    public void DoctorProfile_With_Explicit_ReferralCode_Normalizes_Code()
    {
        // Arrange
        var userId = Guid.NewGuid();

        // Act
        var doctor = DoctorProfile.Create(userId, "Pediatric Neurologist", referralCode: "dr-custom123");

        // Assert
        Assert.Equal("DR-CUSTOM123", doctor.ReferralCode);
    }

    [Fact]
    public void BaselineAssessment_With_Valid_Scores_Is_Created()
    {
        // Arrange
        var childId = Guid.NewGuid();

        // Act
        var assessment = BaselineAssessment.Create(
            childId,
            overallScore: 85.5m,
            cognitiveScore: 80.0m,
            communicationScore: 88.0m,
            motorScore: 92.0m,
            emotionalScore: 78.5m);

        // Assert
        Assert.Equal(childId, assessment.ChildId);
        Assert.Equal(85.5m, assessment.OverallScore);
        Assert.Equal(80.0m, assessment.CognitiveScore);
        Assert.Equal(88.0m, assessment.CommunicationScore);
        Assert.Equal(92.0m, assessment.MotorScore);
        Assert.Equal(78.5m, assessment.EmotionalScore);
        Assert.True(assessment.CompletedAtUtc <= DateTime.UtcNow);
    }

    [Fact]
    public void BaselineAssessment_With_Empty_ChildId_Throws_DomainException()
    {
        // Act & Assert
        Assert.Throws<DomainException>(() => BaselineAssessment.Create(
            Guid.Empty, 80, 80, 80, 80, 80));
    }

    [Theory]
    [InlineData(-1, 80, 80, 80, 80)]
    [InlineData(101, 80, 80, 80, 80)]
    [InlineData(80, -5, 80, 80, 80)]
    [InlineData(80, 105, 80, 80, 80)]
    [InlineData(80, 80, -10, 80, 80)]
    [InlineData(80, 80, 80, -2, 80)]
    [InlineData(80, 80, 80, 80, 150)]
    public void BaselineAssessment_With_Out_Of_Range_Score_Throws_DomainException(
        decimal overall, decimal cog, decimal comm, decimal motor, decimal emo)
    {
        // Act & Assert
        Assert.Throws<DomainException>(() => BaselineAssessment.Create(
            Guid.NewGuid(), overall, cog, comm, motor, emo));
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

    [Fact]
    public void DoctorChildAssignment_Can_Update_DoctorNotes()
    {
        // Arrange
        var assignment = DoctorChildAssignment.Create(Guid.NewGuid(), Guid.NewGuid());
        Assert.Null(assignment.DoctorNotes);
        Assert.Null(assignment.DoctorNotesUpdatedAtUtc);

        // Act
        assignment.UpdateDoctorNotes("Child shows steady progress in motor balance.");

        // Assert
        Assert.Equal("Child shows steady progress in motor balance.", assignment.DoctorNotes);
        Assert.NotNull(assignment.DoctorNotesUpdatedAtUtc);

        // Act - clear notes
        assignment.UpdateDoctorNotes("   ");
        Assert.Null(assignment.DoctorNotes);
    }

    [Fact]
    public void DoctorChildAssignment_With_DoctorNotes_Exceeding_2000_Chars_Throws_DomainException()
    {
        // Arrange
        var assignment = DoctorChildAssignment.Create(Guid.NewGuid(), Guid.NewGuid());
        var longNote = new string('A', 2001);

        // Act & Assert
        Assert.Throws<DomainException>(() => assignment.UpdateDoctorNotes(longNote));
    }
}
