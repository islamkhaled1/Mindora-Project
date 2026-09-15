using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using Mindora.Application.Common.Interfaces;
using Mindora.Domain.Entities;
using Mindora.Infrastructure.Identity;

namespace Mindora.Infrastructure.Persistence;

/// <summary>
/// Entity Framework Core DbContext implementing application persistence and Identity storage.
/// </summary>
public class ApplicationDbContext : IdentityDbContext<ApplicationUser, IdentityRole<Guid>, Guid>, IApplicationDbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public DbSet<Child> Children => Set<Child>();
    public DbSet<ParentProfile> ParentProfiles => Set<ParentProfile>();
    public DbSet<DoctorProfile> DoctorProfiles => Set<DoctorProfile>();
    public DbSet<DoctorChildAssignment> DoctorChildAssignments => Set<DoctorChildAssignment>();
    public DbSet<Activity> Activities => Set<Activity>();
    public DbSet<Session> Sessions => Set<Session>();
    public DbSet<PerformanceMetric> PerformanceMetrics => Set<PerformanceMetric>();
    public DbSet<SessionAnalysisResult> SessionAnalysisResults => Set<SessionAnalysisResult>();
    public DbSet<ChildLinkingCode> ChildLinkingCodes => Set<ChildLinkingCode>();
    public DbSet<BaselineAssessment> BaselineAssessments => Set<BaselineAssessment>();
    public DbSet<DoctorLinkRequest> DoctorLinkRequests => Set<DoctorLinkRequest>();
    public DbSet<PasswordResetToken> PasswordResetTokens => Set<PasswordResetToken>();
    public DbSet<EmailVerificationToken> EmailVerificationTokens => Set<EmailVerificationToken>();

    // IApplicationDbContext explicit interface implementations
    IQueryable<Child> IApplicationDbContext.Children => Children;
    IQueryable<ParentProfile> IApplicationDbContext.ParentProfiles => ParentProfiles;
    IQueryable<DoctorProfile> IApplicationDbContext.DoctorProfiles => DoctorProfiles;
    IQueryable<DoctorChildAssignment> IApplicationDbContext.DoctorChildAssignments => DoctorChildAssignments;
    IQueryable<Activity> IApplicationDbContext.Activities => Activities;
    IQueryable<Session> IApplicationDbContext.Sessions => Sessions;
    IQueryable<PerformanceMetric> IApplicationDbContext.PerformanceMetrics => PerformanceMetrics;
    IQueryable<SessionAnalysisResult> IApplicationDbContext.SessionAnalysisResults => SessionAnalysisResults;
    IQueryable<ChildLinkingCode> IApplicationDbContext.ChildLinkingCodes => ChildLinkingCodes;
    IQueryable<BaselineAssessment> IApplicationDbContext.BaselineAssessments => BaselineAssessments;
    IQueryable<DoctorLinkRequest> IApplicationDbContext.DoctorLinkRequests => DoctorLinkRequests;
    IQueryable<PasswordResetToken> IApplicationDbContext.PasswordResetTokens => PasswordResetTokens;
    IQueryable<EmailVerificationToken> IApplicationDbContext.EmailVerificationTokens => EmailVerificationTokens;

    void IApplicationDbContext.Add<TEntity>(TEntity entity) where TEntity : class
    {
        base.Add(entity);
    }

    void IApplicationDbContext.Remove<TEntity>(TEntity entity) where TEntity : class
    {
        base.Remove(entity);
    }

    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        return base.SaveChangesAsync(cancellationToken);
    }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        // Apply all focused IEntityTypeConfiguration<T> configurations from this assembly
        builder.ApplyConfigurationsFromAssembly(typeof(ApplicationDbContext).Assembly);
    }
}
