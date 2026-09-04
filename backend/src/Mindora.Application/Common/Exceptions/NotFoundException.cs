namespace Mindora.Application.Common.Exceptions;

/// <summary>
/// Thrown when a requested domain entity or resource cannot be found.
/// </summary>
public class NotFoundException : Exception
{
    public NotFoundException(string message)
        : base(message)
    {
    }

    public NotFoundException(string name, object key)
        : base($"Entity \"{name}\" ({key}) was not found.")
    {
    }
}
