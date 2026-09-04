using FluentValidation;
using Mindora.Application.Common.Validation;
using Xunit;
using AppValidationException = Mindora.Application.Common.Exceptions.ValidationException;

namespace Mindora.UnitTests.Application;

public class ValidationFoundationTests
{
    private sealed record TestRequest(string Title, int Score);

    private sealed class TestRequestValidator : AbstractValidator<TestRequest>
    {
        public TestRequestValidator()
        {
            RuleFor(x => x.Title)
                .NotEmpty().WithMessage("Title is required.")
                .MaximumLength(50).WithMessage("Title cannot exceed 50 characters.");

            RuleFor(x => x.Score)
                .InclusiveBetween(0, 100).WithMessage("Score must be between 0 and 100.");
        }
    }

    [Fact]
    public async Task ValidateAndThrowAppAsync_With_Valid_Request_Succeeds()
    {
        // Arrange
        var validator = new TestRequestValidator();
        var validRequest = new TestRequest("Finger Tap Exercise", 85);

        // Act & Assert (should not throw)
        await validator.ValidateAndThrowAppAsync(validRequest);
    }

    [Fact]
    public async Task ValidateAndThrowAppAsync_With_Invalid_Request_Throws_Application_ValidationException()
    {
        // Arrange
        var validator = new TestRequestValidator();
        var invalidRequest = new TestRequest("", 120);

        // Act & Assert
        var ex = await Assert.ThrowsAsync<AppValidationException>(() =>
            validator.ValidateAndThrowAppAsync(invalidRequest));

        Assert.Equal(2, ex.Errors.Count);
        Assert.True(ex.Errors.ContainsKey("Title"));
        Assert.True(ex.Errors.ContainsKey("Score"));
        Assert.Contains("Title is required.", ex.Errors["Title"]);
        Assert.Contains("Score must be between 0 and 100.", ex.Errors["Score"]);
    }
}
