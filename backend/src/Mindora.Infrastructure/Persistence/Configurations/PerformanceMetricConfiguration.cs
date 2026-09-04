using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Mindora.Domain.Entities;

namespace Mindora.Infrastructure.Persistence.Configurations;

public class PerformanceMetricConfiguration : IEntityTypeConfiguration<PerformanceMetric>
{
    public void Configure(EntityTypeBuilder<PerformanceMetric> builder)
    {
        builder.ToTable("PerformanceMetrics");

        builder.HasKey(m => m.Id);

        builder.Property(m => m.SessionId)
            .IsRequired();

        builder.Property(m => m.MetricType)
            .IsRequired()
            .HasMaxLength(100);

        // Numeric precision: decimal(18,2) safely accommodates both percentages (0.00-100.00),
        // millisecond reaction times (e.g. 2450.50 ms), duration seconds (3600.00 s), and repetition counts
        // without truncation or floating-point rounding inaccuracies.
        builder.Property(m => m.Value)
            .HasPrecision(18, 2)
            .IsRequired();

        builder.Property(m => m.TimestampUtc)
            .IsRequired();

        builder.HasIndex(m => m.SessionId);
    }
}
