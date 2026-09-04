using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Mindora.Domain.Entities;

namespace Mindora.Infrastructure.Persistence.Configurations;

public class ActivityConfiguration : IEntityTypeConfiguration<Activity>
{
    public void Configure(EntityTypeBuilder<Activity> builder)
    {
        builder.ToTable("Activities");

        builder.HasKey(a => a.Id);

        builder.Property(a => a.Title)
            .IsRequired()
            .HasMaxLength(200);

        builder.Property(a => a.Description)
            .IsRequired()
            .HasMaxLength(2000);

        builder.Property(a => a.Domain)
            .HasConversion<int>()
            .IsRequired();

        builder.Property(a => a.BaseDifficulty)
            .HasConversion<int>()
            .IsRequired();

        builder.Property(a => a.AdaptiveSettingsJson);

        builder.Property(a => a.IsActive)
            .IsRequired();

        builder.Property(a => a.CreatedAtUtc)
            .IsRequired();

        // Index on (Domain, BaseDifficulty) for fast catalog search by developmental pillar
        builder.HasIndex(a => new { a.Domain, a.BaseDifficulty });
    }
}
