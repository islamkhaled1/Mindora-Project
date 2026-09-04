using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Mindora.Domain.Entities;

namespace Mindora.Infrastructure.Persistence.Configurations;

public class SessionConfiguration : IEntityTypeConfiguration<Session>
{
    public void Configure(EntityTypeBuilder<Session> builder)
    {
        builder.ToTable("Sessions");

        builder.HasKey(s => s.Id);

        builder.Property(s => s.ChildId)
            .IsRequired();

        builder.Property(s => s.ActivityId)
            .IsRequired();

        builder.Property(s => s.Domain)
            .HasConversion<int>()
            .IsRequired();

        builder.Property(s => s.Status)
            .HasConversion<int>()
            .IsRequired();

        builder.Property(s => s.StartTimeUtc)
            .IsRequired();

        builder.Property(s => s.EndTimeUtc);

        builder.Property(s => s.ActualDurationSeconds);

        // Index on (ChildId, StartTimeUtc) for rapid longitudinal progress queries
        builder.HasIndex(s => new { s.ChildId, s.StartTimeUtc });

        // Restrict delete behavior from Child to Sessions:
        // Soft deleting a Child MUST NEVER cascade-delete historical rehabilitation records
        builder.HasOne<Child>()
            .WithMany()
            .HasForeignKey(s => s.ChildId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne<Activity>()
            .WithMany()
            .HasForeignKey(s => s.ActivityId)
            .OnDelete(DeleteBehavior.Restrict);

        // Session -> PerformanceMetrics: Cascade delete
        builder.HasMany(s => s.Metrics)
            .WithOne()
            .HasForeignKey(m => m.SessionId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Navigation(s => s.Metrics)
            .UsePropertyAccessMode(PropertyAccessMode.Field);

        // Session -> SessionAnalysisResult: 1-to-1 Cascade delete
        builder.HasOne(s => s.AnalysisResult)
            .WithOne()
            .HasForeignKey<SessionAnalysisResult>(r => r.SessionId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
