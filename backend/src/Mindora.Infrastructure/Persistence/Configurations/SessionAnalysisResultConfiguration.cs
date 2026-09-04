using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Mindora.Domain.Entities;

namespace Mindora.Infrastructure.Persistence.Configurations;

public class SessionAnalysisResultConfiguration : IEntityTypeConfiguration<SessionAnalysisResult>
{
    public void Configure(EntityTypeBuilder<SessionAnalysisResult> builder)
    {
        builder.ToTable("SessionAnalysisResults");

        builder.HasKey(r => r.Id);

        builder.Property(r => r.SessionId)
            .IsRequired();

        // Standardized decimal(5,2) for performance scores (0.00 to 100.00)
        builder.Property(r => r.OverallPerformanceScore)
            .HasPrecision(5, 2)
            .IsRequired();

        builder.Property(r => r.DomainScore)
            .HasPrecision(5, 2)
            .IsRequired();

        builder.Property(r => r.SupportiveObservations)
            .IsRequired();

        builder.Property(r => r.FatigueObserved)
            .IsRequired();

        builder.Property(r => r.RecommendedDifficultyAdjustment)
            .HasConversion<int>()
            .IsRequired();

        builder.Property(r => r.AdaptiveParametersJson);

        builder.Property(r => r.IsFallbackResult)
            .IsRequired();

        builder.Property(r => r.AnalyzedAtUtc)
            .IsRequired();

        // 1-to-1 unique index on SessionId
        builder.HasIndex(r => r.SessionId)
            .IsUnique();
    }
}
