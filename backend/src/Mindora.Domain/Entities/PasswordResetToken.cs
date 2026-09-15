using System.Security.Cryptography;
using System.Text;
using Mindora.Domain.Common;

namespace Mindora.Domain.Entities;

/// <summary>
/// Represents a secure, time-bounded password reset lifecycle record.
/// Stores cryptographically hashed 6-digit OTPs and hashed single-use reset tokens.
/// Raw OTPs and reset tokens are never persisted in plaintext.
/// </summary>
public class PasswordResetToken : BaseEntity
{
    public const int DefaultOtpValidityMinutes = 10;
    public const int DefaultResetTokenValidityMinutes = 15;
    public const int MaxOtpAttempts = 5;

    public Guid UserId { get; private set; }
    public string Email { get; private set; } = string.Empty;
    public string OtpHash { get; private set; } = string.Empty;
    public DateTime OtpExpiresAtUtc { get; private set; }
    public int OtpAttempts { get; private set; }
    public bool IsOtpVerified { get; private set; }
    public DateTime? OtpVerifiedAtUtc { get; private set; }

    public string? ResetTokenHash { get; private set; }
    public DateTime? ResetTokenExpiresAtUtc { get; private set; }
    public bool IsUsed { get; private set; }
    public DateTime? UsedAtUtc { get; private set; }
    public DateTime CreatedAtUtc { get; private set; }

    // Parameterless constructor for EF Core
    protected PasswordResetToken() : base()
    {
    }

    public PasswordResetToken(
        Guid id,
        Guid userId,
        string email,
        string otpHash,
        DateTime createdAtUtc,
        DateTime otpExpiresAtUtc) : base(id)
    {
        if (userId == Guid.Empty)
        {
            throw new DomainException("UserId cannot be empty for PasswordResetToken.");
        }

        if (string.IsNullOrWhiteSpace(email))
        {
            throw new DomainException("Email cannot be empty or whitespace.");
        }

        if (string.IsNullOrWhiteSpace(otpHash))
        {
            throw new DomainException("OtpHash cannot be empty or whitespace.");
        }

        if (otpExpiresAtUtc <= createdAtUtc)
        {
            throw new DomainException("OtpExpiresAtUtc must be strictly later than CreatedAtUtc.");
        }

        UserId = userId;
        Email = email.Trim().ToLowerInvariant();
        OtpHash = otpHash.Trim().ToLowerInvariant();
        CreatedAtUtc = createdAtUtc;
        OtpExpiresAtUtc = otpExpiresAtUtc;
        OtpAttempts = 0;
        IsOtpVerified = false;
        IsUsed = false;
    }

    public static PasswordResetToken Create(
        Guid userId,
        string email,
        string plainOtp,
        TimeSpan? otpValidity = null,
        DateTime? createdAtUtc = null)
    {
        var created = createdAtUtc ?? DateTime.UtcNow;
        var expires = created.Add(otpValidity ?? TimeSpan.FromMinutes(DefaultOtpValidityMinutes));
        var otpHash = ComputeHash(plainOtp);

        return new PasswordResetToken(
            Guid.NewGuid(),
            userId,
            email,
            otpHash,
            created,
            expires);
    }

    public bool IsOtpExpired(DateTime utcNow) => utcNow > OtpExpiresAtUtc;

    public bool IsResetTokenExpired(DateTime utcNow) =>
        ResetTokenExpiresAtUtc == null || utcNow > ResetTokenExpiresAtUtc.Value;

    public (bool Succeeded, string? ErrorMessage) VerifyOtp(string plainOtp, DateTime utcNow)
    {
        if (IsUsed)
        {
            return (false, "تم استخدام طلب استعادة كلمة المرور هذا بالفعل.");
        }

        if (IsOtpVerified)
        {
            return (false, "تم التحقق من هذا الرمز مسبقاً.");
        }

        if (IsOtpExpired(utcNow))
        {
            return (false, "انتهت صلاحية رمز التحقق. يرجى طلب رمز جديد.");
        }

        if (OtpAttempts >= MaxOtpAttempts)
        {
            return (false, "تم تجاوز الحد الأقصى للمحاولات. يرجى طلب رمز جديد.");
        }

        OtpAttempts++;

        var incomingHash = ComputeHash(plainOtp);
        if (!CryptographicOperations.FixedTimeEquals(
            Encoding.UTF8.GetBytes(incomingHash),
            Encoding.UTF8.GetBytes(OtpHash)))
        {
            return (false, "رمز التحقق غير صحيح.");
        }

        IsOtpVerified = true;
        OtpVerifiedAtUtc = utcNow;
        return (true, null);
    }

    public string IssueResetToken(DateTime utcNow, TimeSpan? validity = null)
    {
        if (!IsOtpVerified)
        {
            throw new DomainException("Cannot issue a reset token before OTP verification.");
        }

        if (IsUsed)
        {
            throw new DomainException("Cannot issue reset token for an already completed reset request.");
        }

        // Generate 32 cryptographically secure random bytes
        var tokenBytes = RandomNumberGenerator.GetBytes(32);
        var plainToken = Convert.ToHexString(tokenBytes).ToLowerInvariant();

        ResetTokenHash = ComputeHash(plainToken);
        ResetTokenExpiresAtUtc = utcNow.Add(validity ?? TimeSpan.FromMinutes(DefaultResetTokenValidityMinutes));

        return plainToken;
    }

    public (bool Succeeded, string? ErrorMessage) VerifyResetToken(string plainResetToken, DateTime utcNow)
    {
        if (IsUsed)
        {
            return (false, "تم استخدام رمز إعادة التعيين بالفعل.");
        }

        if (!IsOtpVerified)
        {
            return (false, "لم يتم التحقق من صحة الطلب.");
        }

        if (string.IsNullOrWhiteSpace(ResetTokenHash) || IsResetTokenExpired(utcNow))
        {
            return (false, "انتهت صلاحية جلسة إعادة تعيين كلمة المرور. يرجى بدء العملية من جديد.");
        }

        var incomingHash = ComputeHash(plainResetToken);
        if (!CryptographicOperations.FixedTimeEquals(
            Encoding.UTF8.GetBytes(incomingHash),
            Encoding.UTF8.GetBytes(ResetTokenHash)))
        {
            return (false, "رمز إعادة تعيين كلمة المرور غير صحيح.");
        }

        return (true, null);
    }

    public void MarkUsed(DateTime utcNow)
    {
        if (IsUsed)
        {
            throw new DomainException("This password reset token has already been marked as used.");
        }

        IsUsed = true;
        UsedAtUtc = utcNow;
    }

    public void Invalidate()
    {
        IsUsed = true;
        OtpExpiresAtUtc = DateTime.UtcNow;
        if (ResetTokenExpiresAtUtc.HasValue)
        {
            ResetTokenExpiresAtUtc = DateTime.UtcNow;
        }
    }

    public static string ComputeHash(string rawValue)
    {
        if (string.IsNullOrWhiteSpace(rawValue))
        {
            return string.Empty;
        }

        var normalized = rawValue.Trim();
        var bytes = Encoding.UTF8.GetBytes(normalized);
        var hashBytes = SHA256.HashData(bytes);
        return Convert.ToHexString(hashBytes).ToLowerInvariant();
    }
}
