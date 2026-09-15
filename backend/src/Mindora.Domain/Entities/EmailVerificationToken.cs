using System.Security.Cryptography;
using System.Text;
using Mindora.Domain.Common;
using Mindora.Domain.Enums;

namespace Mindora.Domain.Entities;

/// <summary>
/// Represents a secure, time-bounded email verification lifecycle record.
/// Dedicated strictly to account email confirmation and isolated from password recovery.
/// Stores cryptographically hashed 6-digit OTPs and enforces attempt limits and resend cooldowns.
/// </summary>
public class EmailVerificationToken : BaseEntity
{
    public const int DefaultOtpValidityMinutes = 10;
    public const int MaxAttempts = 5;
    public const int ResendCooldownSeconds = 60;

    public Guid UserId { get; private set; }
    public string Email { get; private set; } = string.Empty;
    public ClientPlatform Platform { get; private set; }
    public string OtpHash { get; private set; } = string.Empty;
    public DateTime OtpExpiresAtUtc { get; private set; }
    public int AttemptCount { get; private set; }
    public DateTime CreatedAtUtc { get; private set; }
    public DateTime LastRequestedAtUtc { get; private set; }
    public bool IsVerified { get; private set; }
    public DateTime? VerifiedAtUtc { get; private set; }
    public bool IsActive { get; private set; }

    // Parameterless constructor for EF Core
    protected EmailVerificationToken() : base()
    {
    }

    public EmailVerificationToken(
        Guid id,
        Guid userId,
        string email,
        ClientPlatform platform,
        string otpHash,
        DateTime createdAtUtc,
        DateTime otpExpiresAtUtc) : base(id)
    {
        if (userId == Guid.Empty)
        {
            throw new DomainException("UserId cannot be empty for EmailVerificationToken.");
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
        Platform = platform;
        OtpHash = otpHash.Trim().ToLowerInvariant();
        CreatedAtUtc = createdAtUtc;
        LastRequestedAtUtc = createdAtUtc;
        OtpExpiresAtUtc = otpExpiresAtUtc;
        AttemptCount = 0;
        IsVerified = false;
        IsActive = true;
    }

    public static EmailVerificationToken Create(
        Guid userId,
        string email,
        ClientPlatform platform,
        string plainOtp,
        TimeSpan? otpValidity = null,
        DateTime? createdAtUtc = null)
    {
        var created = createdAtUtc ?? DateTime.UtcNow;
        var expires = created.Add(otpValidity ?? TimeSpan.FromMinutes(DefaultOtpValidityMinutes));
        var otpHash = ComputeHash(plainOtp);

        return new EmailVerificationToken(
            Guid.NewGuid(),
            userId,
            email,
            platform,
            otpHash,
            created,
            expires);
    }

    public static string GenerateOtp()
    {
        // Cryptographically secure 6-digit number [100000, 999999]
        return RandomNumberGenerator.GetInt32(100000, 1000000).ToString();
    }

    public bool IsOtpExpired(DateTime utcNow) => utcNow > OtpExpiresAtUtc;

    public bool CanResend(DateTime utcNow, out int secondsRemaining)
    {
        var elapsed = utcNow - LastRequestedAtUtc;
        if (elapsed.TotalSeconds < ResendCooldownSeconds)
        {
            secondsRemaining = (int)Math.Ceiling(ResendCooldownSeconds - elapsed.TotalSeconds);
            return false;
        }

        secondsRemaining = 0;
        return true;
    }

    public void RecordNewRequest(string newPlainOtp, DateTime utcNow, TimeSpan? validity = null)
    {
        if (!CanResend(utcNow, out var remaining))
        {
            throw new DomainException($"يرجى الانتظار {remaining} ثانية قبل طلب رمز تحقق جديد.");
        }

        if (IsVerified)
        {
            throw new DomainException("تم التحقق من هذا الحساب مسبقاً.");
        }

        OtpHash = ComputeHash(newPlainOtp);
        LastRequestedAtUtc = utcNow;
        OtpExpiresAtUtc = utcNow.Add(validity ?? TimeSpan.FromMinutes(DefaultOtpValidityMinutes));
        AttemptCount = 0;
        IsActive = true;
    }

    public (bool Succeeded, string? ErrorMessage) VerifyOtp(string plainOtp, DateTime utcNow)
    {
        if (IsVerified)
        {
            return (false, "تم التحقق من هذا الحساب مسبقاً.");
        }

        if (!IsActive)
        {
            return (false, "رمز التحقق غير صالح أو تم إلغاؤه. يرجى طلب رمز جديد.");
        }

        if (IsOtpExpired(utcNow))
        {
            Invalidate();
            return (false, "انتهت صلاحية رمز التحقق. يرجى طلب رمز جديد.");
        }

        if (AttemptCount >= MaxAttempts)
        {
            Invalidate();
            return (false, "تم تجاوز الحد الأقصى للمحاولات. يرجى طلب رمز جديد.");
        }

        AttemptCount++;

        var incomingHash = ComputeHash(plainOtp);
        if (!CryptographicOperations.FixedTimeEquals(
            Encoding.UTF8.GetBytes(incomingHash),
            Encoding.UTF8.GetBytes(OtpHash)))
        {
            if (AttemptCount >= MaxAttempts)
            {
                Invalidate();
                return (false, "تم تجاوز الحد الأقصى للمحاولات. تم إلغاء رمز التحقق، يرجى طلب رمز جديد.");
            }

            return (false, "رمز التحقق غير صحيح.");
        }

        IsVerified = true;
        VerifiedAtUtc = utcNow;
        IsActive = false;
        return (true, null);
    }

    public void Invalidate()
    {
        IsActive = false;
        OtpExpiresAtUtc = DateTime.UtcNow;
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
