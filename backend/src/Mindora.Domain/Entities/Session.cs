using Mindora.Domain.Common;
using Mindora.Domain.Enums;

namespace Mindora.Domain.Entities;

/// <summary>
/// Represents one execution of an Activity by a Child.
/// Strictly enforces lifecycle transitions and telemetry metric recording.
/// </summary>
public class Session : BaseEntity
{
    private readonly List<PerformanceMetric> _metrics = new();

    public Guid ChildId { get; private set; }
    public Guid ActivityId { get; private set; }
    public ActivityDomain Domain { get; private set; }
    public SessionStatus Status { get; private set; }
    public DateTime StartTimeUtc { get; private set; }
    public DateTime? EndTimeUtc { get; private set; }
    public int? ActualDurationSeconds { get; private set; }
    public SessionAnalysisResult? AnalysisResult { get; private set; }

    // P0 Parent Feedback Fields from UI Audit
    public ParentSentimentRating? ParentRating { get; private set; }
    public string? ParentNotes { get; private set; }

    public IReadOnlyCollection<PerformanceMetric> Metrics => _metrics.AsReadOnly();

    // Parameterless constructor for ORM deserialization
    protected Session() : base()
    {
    }

    public Session(
        Guid id,
        Guid childId,
        Guid activityId,
        ActivityDomain domain,
        DateTime? startTimeUtc = null) : base(id)
    {
        if (childId == Guid.Empty)
        {
            throw new DomainException("ChildId cannot be empty for Session.");
        }

        if (activityId == Guid.Empty)
        {
            throw new DomainException("ActivityId cannot be empty for Session.");
        }

        ChildId = childId;
        ActivityId = activityId;
        Domain = domain;
        Status = SessionStatus.Started;
        StartTimeUtc = startTimeUtc ?? DateTime.UtcNow;
    }

    public static Session Start(
        Guid childId,
        Guid activityId,
        ActivityDomain domain,
        DateTime? startTimeUtc = null)
    {
        return new Session(Guid.NewGuid(), childId, activityId, domain, startTimeUtc);
    }

    /// <summary>
    /// Records a new performance telemetry metric for the session.
    /// Metrics may only be added while the session is currently active (Started).
    /// </summary>
    public PerformanceMetric AddMetric(string metricType, decimal value, DateTime? timestampUtc = null)
    {
        EnsureSessionIsActive();

        var metric = PerformanceMetric.Create(Id, metricType, value, timestampUtc);
        _metrics.Add(metric);
        return metric;
    }

    /// <summary>
    /// Adds an existing PerformanceMetric entity to the session.
    /// </summary>
    public void AddMetric(PerformanceMetric metric)
    {
        ArgumentNullException.ThrowIfNull(metric);

        EnsureSessionIsActive();

        if (metric.SessionId != Id)
        {
            throw new DomainException($"Metric session ID '{metric.SessionId}' does not match this session ID '{Id}'.");
        }

        _metrics.Add(metric);
    }

    /// <summary>
    /// Completes the session.
    /// Valid transition: Started -> Completed.
    /// </summary>
    public void Complete(DateTime completedAtUtc, int? actualDurationSeconds = null)
    {
        if (Status == SessionStatus.Completed)
        {
            throw new DomainException("Session is already completed. Cannot transition from Completed to Completed.");
        }

        if (Status == SessionStatus.Abandoned)
        {
            throw new DomainException("Cannot complete an abandoned session. Invalid lifecycle transition.");
        }

        if (completedAtUtc < StartTimeUtc)
        {
            throw new DomainException("Completion time cannot be earlier than start time.");
        }

        Status = SessionStatus.Completed;
        EndTimeUtc = completedAtUtc;

        if (actualDurationSeconds.HasValue)
        {
            if (actualDurationSeconds.Value < 0)
            {
                throw new DomainException("Actual duration seconds cannot be negative.");
            }
            ActualDurationSeconds = actualDurationSeconds.Value;
        }
        else
        {
            ActualDurationSeconds = (int)Math.Max(0, (completedAtUtc - StartTimeUtc).TotalSeconds);
        }
    }

    /// <summary>
    /// Abandons the session.
    /// Valid transition: Started -> Abandoned.
    /// </summary>
    public void Abandon(DateTime abandonedAtUtc)
    {
        if (Status == SessionStatus.Abandoned)
        {
            throw new DomainException("Session is already abandoned. Cannot transition from Abandoned to Abandoned.");
        }

        if (Status == SessionStatus.Completed)
        {
            throw new DomainException("Cannot abandon a completed session. Invalid lifecycle transition.");
        }

        if (abandonedAtUtc < StartTimeUtc)
        {
            throw new DomainException("Abandoned time cannot be earlier than start time.");
        }

        Status = SessionStatus.Abandoned;
        EndTimeUtc = abandonedAtUtc;
        ActualDurationSeconds = (int)Math.Max(0, (abandonedAtUtc - StartTimeUtc).TotalSeconds);
    }

    /// <summary>
    /// Attaches the analysis result produced by the adaptation engine to this session.
    /// May only be attached once the session is completed.
    /// </summary>
    public void AttachAnalysisResult(SessionAnalysisResult analysisResult)
    {
        ArgumentNullException.ThrowIfNull(analysisResult);

        if (Status != SessionStatus.Completed)
        {
            throw new DomainException("Analysis result can only be attached to a completed session.");
        }

        if (analysisResult.SessionId != Id)
        {
            throw new DomainException($"Analysis result session ID '{analysisResult.SessionId}' does not match this session ID '{Id}'.");
        }

        AnalysisResult = analysisResult;
    }

    /// <summary>
    /// Records parent sentiment rating and qualitative observation notes for a completed session.
    /// </summary>
    public void RecordParentFeedback(ParentSentimentRating rating, string? notes = null)
    {
        if (Status != SessionStatus.Completed)
        {
            throw new DomainException("Parent feedback can only be recorded for a completed session.");
        }

        if (notes != null && notes.Length > 1000)
        {
            throw new DomainException("Parent notes cannot exceed 1000 characters.");
        }

        ParentRating = rating;
        ParentNotes = notes?.Trim();
    }

    private void EnsureSessionIsActive()
    {
        if (Status != SessionStatus.Started)
        {
            throw new DomainException($"Cannot add metrics to a session with status '{Status}'. Metrics may only be added while the session is Started.");
        }
    }
}
