using FluentValidation.Results;
using Mindora.Application.Common.Exceptions;
using Xunit;

namespace Mindora.UnitTests.Application;

public class ApplicationExceptionsTests
{
    [Fact]
    public void ValidationException_Default_Initializes_Empty_Errors()
    {
        // Act
        var ex = new ValidationException();

        // Assert
        Assert.NotNull(ex.Errors);
        Assert.Empty(ex.Errors);
        Assert.Equal("One or more validation failures have occurred.", ex.Message);
    }

    [Fact]
    public void ValidationException_Single_Property_Error_Populates_Dictionary()
    {
        // Act
        var ex = new ValidationException("Email", "Invalid email address format.");

        // Assert
        Assert.True(ex.Errors.ContainsKey("Email"));
        Assert.Single(ex.Errors["Email"]);
        Assert.Equal("Invalid email address format.", ex.Errors["Email"][0]);
    }

    [Fact]
    public void ValidationException_From_FluentValidation_Failures_Groups_Properly()
    {
        // Arrange
        var failures = new List<ValidationFailure>
        {
            new("Password", "Password must be at least 8 characters."),
            new("Password", "Password must contain a digit."),
            new("FullName", "FullName is required.")
        };

        // Act
        var ex = new ValidationException(failures);

        // Assert
        Assert.Equal(2, ex.Errors.Count);
        Assert.Equal(2, ex.Errors["Password"].Length);
        Assert.Single(ex.Errors["FullName"]);
        Assert.Contains("Password must be at least 8 characters.", ex.Errors["Password"]);
        Assert.Contains("Password must contain a digit.", ex.Errors["Password"]);
    }

    [Fact]
    public void NotFoundException_With_Resource_And_Key_Formats_Message_Safely()
    {
        // Arrange
        var childId = Guid.NewGuid();

        // Act
        var ex = new NotFoundException("Child", childId);

        // Assert
        Assert.Equal($"Entity \"Child\" ({childId}) was not found.", ex.Message);
    }

    [Fact]
    public void ForbiddenException_Has_Safe_Default_Message()
    {
        // Act
        var ex = new ForbiddenException();

        // Assert
        Assert.Equal("Access to the requested resource is forbidden.", ex.Message);
    }

    [Fact]
    public void ConflictException_Stores_Conflict_Message()
    {
        // Act
        var ex = new ConflictException("A session is already active for this child.");

        // Assert
        Assert.Equal("A session is already active for this child.", ex.Message);
    }
}
