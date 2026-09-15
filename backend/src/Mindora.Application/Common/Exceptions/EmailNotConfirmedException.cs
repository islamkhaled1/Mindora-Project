namespace Mindora.Application.Common.Exceptions;

/// <summary>
/// Thrown when an unverified user attempts an operation (such as login) that requires email confirmation.
/// </summary>
public class EmailNotConfirmedException : Exception
{
    public string Email { get; }

    public EmailNotConfirmedException(string email, string message = "البريد الإلكتروني غير مؤكد. يرجى تأكيد حسابك عبر رمز التحقق (OTP).")
        : base(message)
    {
        Email = email;
    }
}
