using FluentValidation;
using AppValidationException = Mindora.Application.Common.Exceptions.ValidationException;

namespace Mindora.Application.Common.Validation;

/// <summary>
/// Helper extensions for executing FluentValidation validators and translating results into Application ValidationException.
/// </summary>
public static class ValidationExtensions
{
    /// <summary>
    /// Validates the given instance and throws an Application-level ValidationException if validation fails.
    /// </summary>
    public static async Task ValidateAndThrowAppAsync<T>(
        this IValidator<T> validator,
        T instance,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(validator);

        var result = await validator.ValidateAsync(instance, cancellationToken);
        if (!result.IsValid)
        {
            throw new AppValidationException(result.Errors);
        }
    }
}
