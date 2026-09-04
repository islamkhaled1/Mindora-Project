namespace Mindora.Application.Common.Exceptions;

/// <summary>
/// Thrown when authentication fails or valid credentials are missing.
/// </summary>
public class UnauthorizedException : Exception
{
    public UnauthorizedException(string message = "Invalid email or password.")
        : base(message)
    {
    }
}
