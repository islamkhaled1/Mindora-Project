namespace Mindora.Application.Common.Exceptions;

/// <summary>
/// Thrown when an authenticated user attempts an operation they are not authorized to perform.
/// </summary>
public class ForbiddenException : Exception
{
    public ForbiddenException()
        : base("Access to the requested resource is forbidden.")
    {
    }

    public ForbiddenException(string message)
        : base(message)
    {
    }
}
