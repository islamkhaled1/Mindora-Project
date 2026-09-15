using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Mindora.Domain.Entities;

namespace Mindora.Infrastructure.Persistence.Configurations;

public class ChildConfiguration : IEntityTypeConfiguration<Child>
{
    public void Configure(EntityTypeBuilder<Child> builder)
    {
        builder.ToTable("Children");

        builder.HasKey(c => c.Id);

        builder.Property(c => c.FullName)
            .IsRequired()
            .HasMaxLength(200);

        builder.Property(c => c.DateOfBirth)
            .IsRequired();

        builder.Property(c => c.SupportNotes)
            .HasMaxLength(2000);

        builder.Property(c => c.CurrentMovementLevel)
            .HasConversion<int>()
            .IsRequired();

        builder.Property(c => c.CurrentSpeechLevel)
            .HasConversion<int>()
            .IsRequired();

        builder.Property(c => c.CurrentAttentionLevel)
            .HasConversion<int>()
            .IsRequired();

        builder.Property(c => c.IsDeleted)
            .IsRequired();

        builder.Property(c => c.CreatedAtUtc)
            .IsRequired();

        // P0 Child Profile Extensions from UI Audit
        builder.Property(c => c.Gender)
            .HasConversion<int>();

        builder.Property(c => c.Diagnosis)
            .HasMaxLength(200);

        builder.Property(c => c.AvatarUrl)
            .HasMaxLength(500);

        builder.Property(c => c.SupportLevel)
            .HasConversion<int>();

        builder.Property(c => c.HearingStatus)
            .HasConversion<int>();

        builder.Property(c => c.VisionStatus)
            .HasConversion<int>();

        builder.Property(c => c.FocusDurationMinutes);

        builder.Property(c => c.PreferredPracticeTime)
            .HasMaxLength(100);

        builder.Property(c => c.PreferredActivityType)
            .HasConversion<int>();

        // Index on ParentId for rapid retrieval of parent's children
        builder.HasIndex(c => c.ParentId);

        // Global Query Filter: automatically isolates deleted children from normal application queries
        builder.HasQueryFilter(c => !c.IsDeleted);

        builder.HasOne<ParentProfile>()
            .WithMany()
            .HasForeignKey(c => c.ParentId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
