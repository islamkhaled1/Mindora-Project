using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using Mindora.Application.Common.Exceptions;
using Mindora.Domain.Common;

namespace Mindora.Api.Middleware;

/// <summary>
/// Centralized RFC 7807 ProblemDetails exception handler for Mindora API.
/// Maps domain and application exceptions to standard HTTP status codes while
/// safeguarding internal technical details and stack traces from client exposure.
/// </summary>
public class GlobalExceptionHandler : IExceptionHandler
{
    private readonly ILogger<GlobalExceptionHandler> _logger;

    public GlobalExceptionHandler(ILogger<GlobalExceptionHandler> logger)
    {
        _logger = logger;
    }

    public async ValueTask<bool> TryHandleAsync(
        HttpContext httpContext,
        Exception exception,
        CancellationToken cancellationToken)
    {
        _logger.LogError(
            exception,
            "An unhandled exception occurred during request execution. Path: {Path}, Method: {Method}",
            httpContext.Request.Path,
            httpContext.Request.Method);

        var (statusCode, problemDetails) = MapExceptionToProblemDetails(exception, httpContext);

        httpContext.Response.StatusCode = statusCode;
        httpContext.Response.ContentType = "application/problem+json";

        await httpContext.Response.WriteAsJsonAsync(problemDetails, problemDetails.GetType(), cancellationToken: cancellationToken);
        return true;
    }

    public static (int StatusCode, ProblemDetails Details) MapExceptionToProblemDetails(Exception exception, HttpContext context)
    {
        var path = context.Request.Path.Value ?? "/";

        return exception switch
        {
            UnauthorizedException unauthorizedEx => (
                StatusCodes.Status401Unauthorized,
                new ProblemDetails
                {
                    Status = StatusCodes.Status401Unauthorized,
                    Title = "Unauthorized",
                    Detail = unauthorizedEx.Message,
                    Instance = path
                }),

            BadRequestException badRequestEx => (
                StatusCodes.Status400BadRequest,
                new ProblemDetails
                {
                    Status = StatusCodes.Status400BadRequest,
                    Title = "Bad Request",
                    Detail = badRequestEx.Message,
                    Instance = path
                }),

            ValidationException validationEx => (
                StatusCodes.Status400BadRequest,
                new HttpValidationProblemDetails(validationEx.Errors.ToDictionary(k => k.Key, v => v.Value))
                {
                    Status = StatusCodes.Status400BadRequest,
                    Title = "Validation Failure",
                    Detail = "One or more validation failures occurred.",
                    Instance = path
                }),

            DomainException domainEx => (
                StatusCodes.Status400BadRequest,
                new ProblemDetails
                {
                    Status = StatusCodes.Status400BadRequest,
                    Title = "Domain Rule Violation",
                    Detail = domainEx.Message,
                    Instance = path
                }),

            NotFoundException notFoundEx => (
                StatusCodes.Status404NotFound,
                new ProblemDetails
                {
                    Status = StatusCodes.Status404NotFound,
                    Title = "Resource Not Found",
                    Detail = notFoundEx.Message,
                    Instance = path
                }),

            ForbiddenException forbiddenEx => (
                StatusCodes.Status403Forbidden,
                new ProblemDetails
                {
                    Status = StatusCodes.Status403Forbidden,
                    Title = "Forbidden",
                    Detail = forbiddenEx.Message,
                    Instance = path
                }),

            EmailNotConfirmedException emailNotConfirmedEx => (
                StatusCodes.Status403Forbidden,
                new ProblemDetails
                {
                    Status = StatusCodes.Status403Forbidden,
                    Title = "EmailNotConfirmed",
                    Detail = emailNotConfirmedEx.Message,
                    Instance = path,
                    Extensions =
                    {
                        ["email"] = emailNotConfirmedEx.Email,
                        ["requiresEmailVerification"] = true
                    }
                }),

            ConflictException conflictEx => (
                StatusCodes.Status409Conflict,
                new ProblemDetails
                {
                    Status = StatusCodes.Status409Conflict,
                    Title = "Conflict",
                    Detail = conflictEx.Message,
                    Instance = path
                }),

            _ => (
                StatusCodes.Status500InternalServerError,
                new ProblemDetails
                {
                    Status = StatusCodes.Status500InternalServerError,
                    Title = "Internal Server Error",
                    Detail = "An unexpected error occurred while processing your request. Please try again later.",
                    Instance = path
                })
        };
    }
}
