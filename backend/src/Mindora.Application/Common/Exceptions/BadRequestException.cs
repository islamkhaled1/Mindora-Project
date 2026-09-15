namespace Mindora.Application.Common.Exceptions;

/// <summary>
/// Thrown when a request is malformed, invalid, or violates business operation rules.
/// Maps to HTTP 400 Bad Request.
/// </summary>
public class BadRequestException : Exception
{
    public BadRequestException(string message) : base(message)
    {
    }
}
