using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Mindora.Domain.Entities;

namespace Mindora.Infrastructure.Persistence.Configurations;

public class BaselineAssessmentConfiguration : IEntityTypeConfiguration<BaselineAssessment>
{
    public void Configure(EntityTypeBuilder<BaselineAssessment> builder)
    {
        builder.ToTable("BaselineAssessments");

        builder.HasKey(b => b.Id);

        builder.Property(b => b.ChildId)
            .IsRequired();

        builder.Property(b => b.OverallScore)
            .HasPrecision(5, 2)
            .IsRequired();

        builder.Property(b => b.CognitiveScore)
            .HasPrecision(5, 2)
            .IsRequired();

        builder.Property(b => b.CommunicationScore)
            .HasPrecision(5, 2)
            .IsRequired();

        builder.Property(b => b.MotorScore)
            .HasPrecision(5, 2)
            .IsRequired();

        builder.Property(b => b.EmotionalScore)
            .HasPrecision(5, 2)
            .IsRequired();

        builder.Property(b => b.CompletedAtUtc)
            .IsRequired();

        // Index on ChildId and CompletedAtUtc for fast lookup of child's baseline assessments
        builder.HasIndex(b => b.ChildId);
        builder.HasIndex(b => new { b.ChildId, b.CompletedAtUtc });

        // Relationship: Child -> BaselineAssessments (Cascade delete if child is permanently removed)
        builder.HasOne<Child>()
            .WithMany()
            .HasForeignKey(b => b.ChildId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
