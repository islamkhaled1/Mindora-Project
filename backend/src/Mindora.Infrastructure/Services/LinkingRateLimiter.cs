using System.Collections.Concurrent;
using Mindora.Application.Common.Interfaces;

namespace Mindora.Infrastructure.Services;

/// <summary>
/// In-memory rate limiter enforcing a sliding-window lockout for failed linking code attempts.
/// Allows up to 5 failed attempts per doctor within a 15-minute window.
/// </summary>
public class LinkingRateLimiter : ILinkingRateLimiter
{
    private const int MaxFailedAttempts = 5;
    private static readonly TimeSpan Window = TimeSpan.FromMinutes(15);

    private readonly ConcurrentDictionary<Guid, List<DateTime>> _attempts = new();

    public bool IsLimitExceeded(Guid doctorId)
    {
        if (!_attempts.TryGetValue(doctorId, out var timestamps))
        {
            return false;
        }

        lock (timestamps)
        {
            var cutoff = DateTime.UtcNow - Window;
            timestamps.RemoveAll(t => t < cutoff);
            return timestamps.Count >= MaxFailedAttempts;
        }
    }

    public void RecordFailedAttempt(Guid doctorId)
    {
        var list = _attempts.GetOrAdd(doctorId, _ => new List<DateTime>());
        lock (list)
        {
            var cutoff = DateTime.UtcNow - Window;
            list.RemoveAll(t => t < cutoff);
            list.Add(DateTime.UtcNow);
        }
    }

    public void ResetAttempts(Guid doctorId)
    {
        _attempts.TryRemove(doctorId, out _);
    }
}
