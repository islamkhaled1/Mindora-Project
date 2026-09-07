namespace Mindora.Application.Common.Interfaces;

/// <summary>
/// Throttles failed linking code redemption attempts to mitigate brute-force guessing attacks.
/// </summary>
public interface ILinkingRateLimiter
{
    bool IsLimitExceeded(Guid doctorId);
    void RecordFailedAttempt(Guid doctorId);
    void ResetAttempts(Guid doctorId);
}
