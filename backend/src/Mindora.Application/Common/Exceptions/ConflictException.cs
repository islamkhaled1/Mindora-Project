namespace Mindora.Application.Common.Exceptions;

/// <summary>
/// Thrown when a request conflicts with the current state of a resource (e.g. duplicate active session or state conflict).
/// </summary>
public class ConflictException : Exception
{
    public ConflictException(string message)
        : base(message)
    {
    }
}
