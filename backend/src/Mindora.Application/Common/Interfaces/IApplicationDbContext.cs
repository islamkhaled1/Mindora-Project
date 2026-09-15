using Mindora.Domain.Entities;

namespace Mindora.Application.Common.Interfaces;

/// <summary>
/// Application persistence abstraction.
/// Enables querying and persisting domain aggregates without referencing EF Core or SQL Server.
/// </summary>
public interface IApplicationDbContext
{
    IQueryable<Child> Children { get; }
    IQueryable<ParentProfile> ParentProfiles { get; }
    IQueryable<DoctorProfile> DoctorProfiles { get; }
    IQueryable<DoctorChildAssignment> DoctorChildAssignments { get; }
    IQueryable<Activity> Activities { get; }
    IQueryable<Session> Sessions { get; }
    IQueryable<PerformanceMetric> PerformanceMetrics { get; }
    IQueryable<SessionAnalysisResult> SessionAnalysisResults { get; }
    IQueryable<ChildLinkingCode> ChildLinkingCodes { get; }
    IQueryable<BaselineAssessment> BaselineAssessments { get; }
    IQueryable<DoctorLinkRequest> DoctorLinkRequests { get; }
    IQueryable<PasswordResetToken> PasswordResetTokens { get; }
    IQueryable<EmailVerificationToken> EmailVerificationTokens { get; }

    void Add<TEntity>(TEntity entity) where TEntity : class;
    void Remove<TEntity>(TEntity entity) where TEntity : class;

    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
