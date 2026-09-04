using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Mindora.Api.Middleware;
using Mindora.Application.Common.Exceptions;
using Mindora.Domain.Common;
using Xunit;

namespace Mindora.UnitTests.Api;

public class ProblemDetailsMappingTests
{
    private static DefaultHttpContext CreateHttpContext(string path = "/api/test")
    {
        var context = new DefaultHttpContext();
        context.Request.Path = path;
        return context;
    }

    [Fact]
    public void ValidationException_Maps_To_400_With_HttpValidationProblemDetails()
    {
        // Arrange
        var context = CreateHttpContext("/api/sessions");
        var errors = new Dictionary<string, string[]>
        {
            { "ChildId", new[] { "ChildId cannot be empty." } },
            { "ActivityId", new[] { "ActivityId is required." } }
        };
        var exception = new ValidationException(errors);

        // Act
        var (statusCode, problemDetails) = GlobalExceptionHandler.MapExceptionToProblemDetails(exception, context);

        // Assert
        Assert.Equal(StatusCodes.Status400BadRequest, statusCode);
        Assert.IsType<HttpValidationProblemDetails>(problemDetails);

        var validationDetails = (HttpValidationProblemDetails)problemDetails;
        Assert.Equal("Validation Failure", validationDetails.Title);
        Assert.Equal(2, validationDetails.Errors.Count);
        Assert.Contains("ChildId", validationDetails.Errors.Keys);
        Assert.Contains("ActivityId", validationDetails.Errors.Keys);
        Assert.Equal("/api/sessions", validationDetails.Instance);
    }

    [Fact]
    public void DomainException_Maps_To_400_With_Safe_Detail()
    {
        // Arrange
        var context = CreateHttpContext("/api/sessions/complete");
        var exception = new DomainException("Cannot complete an already completed session.");

        // Act
        var (statusCode, problemDetails) = GlobalExceptionHandler.MapExceptionToProblemDetails(exception, context);

        // Assert
        Assert.Equal(StatusCodes.Status400BadRequest, statusCode);
        Assert.Equal("Domain Rule Violation", problemDetails.Title);
        Assert.Equal("Cannot complete an already completed session.", problemDetails.Detail);
        Assert.Equal("/api/sessions/complete", problemDetails.Instance);
    }

    [Fact]
    public void NotFoundException_Maps_To_404_With_Resource_Not_Found_Title()
    {
        // Arrange
        var context = CreateHttpContext("/api/children/123");
        var exception = new NotFoundException("Child", "123");

        // Act
        var (statusCode, problemDetails) = GlobalExceptionHandler.MapExceptionToProblemDetails(exception, context);

        // Assert
        Assert.Equal(StatusCodes.Status404NotFound, statusCode);
        Assert.Equal("Resource Not Found", problemDetails.Title);
        Assert.Contains("Child", problemDetails.Detail);
        Assert.Equal("/api/children/123", problemDetails.Instance);
    }

    [Fact]
    public void ForbiddenException_Maps_To_403_With_Forbidden_Title()
    {
        // Arrange
        var context = CreateHttpContext("/api/children/456");
        var exception = new ForbiddenException();

        // Act
        var (statusCode, problemDetails) = GlobalExceptionHandler.MapExceptionToProblemDetails(exception, context);

        // Assert
        Assert.Equal(StatusCodes.Status403Forbidden, statusCode);
        Assert.Equal("Forbidden", problemDetails.Title);
        Assert.Equal("Access to the requested resource is forbidden.", problemDetails.Detail);
        Assert.Equal("/api/children/456", problemDetails.Instance);
    }

    [Fact]
    public void ConflictException_Maps_To_409_With_Conflict_Title()
    {
        // Arrange
        var context = CreateHttpContext("/api/sessions");
        var exception = new ConflictException("Another session is currently active.");

        // Act
        var (statusCode, problemDetails) = GlobalExceptionHandler.MapExceptionToProblemDetails(exception, context);

        // Assert
        Assert.Equal(StatusCodes.Status409Conflict, statusCode);
        Assert.Equal("Conflict", problemDetails.Title);
        Assert.Equal("Another session is currently active.", problemDetails.Detail);
        Assert.Equal("/api/sessions", problemDetails.Instance);
    }

    [Fact]
    public void Unexpected_Exception_Maps_To_500_And_Does_NOT_Expose_Internal_Details_Or_StackTrace()
    {
        // Arrange
        var context = CreateHttpContext("/api/secure-action");
        var internalSensitiveMessage = "FATAL: Database connection to server 10.0.0.1 failed with password secret123! Table [Users] locked.";
        var exception = new InvalidOperationException(internalSensitiveMessage, new Exception("Inner confidential message"));

        // Act
        var (statusCode, problemDetails) = GlobalExceptionHandler.MapExceptionToProblemDetails(exception, context);

        // Assert
        Assert.Equal(StatusCodes.Status500InternalServerError, statusCode);
        Assert.Equal("Internal Server Error", problemDetails.Title);

        // Critical Security Check: Ensure sensitive messages, passwords, and stack traces are NOT in detail or title
        Assert.DoesNotContain("secret123", problemDetails.Detail, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("10.0.0.1", problemDetails.Detail, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("Database connection", problemDetails.Detail, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("Inner confidential", problemDetails.Detail, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("FATAL", problemDetails.Detail, StringComparison.OrdinalIgnoreCase);

        // Detail must be a safe, sanitized consumer message
        Assert.Equal("An unexpected error occurred while processing your request. Please try again later.", problemDetails.Detail);
        Assert.Equal("/api/secure-action", problemDetails.Instance);
    }
}
