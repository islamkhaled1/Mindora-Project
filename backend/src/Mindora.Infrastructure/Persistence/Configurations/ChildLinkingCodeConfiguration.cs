using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Mindora.Domain.Entities;

namespace Mindora.Infrastructure.Persistence.Configurations;

public class ChildLinkingCodeConfiguration : IEntityTypeConfiguration<ChildLinkingCode>
{
    public void Configure(EntityTypeBuilder<ChildLinkingCode> builder)
    {
        builder.ToTable("ChildLinkingCodes");

        builder.HasKey(c => c.Id);

        builder.Property(c => c.ChildId)
            .IsRequired();

        builder.Property(c => c.CodeHash)
            .IsRequired()
            .HasMaxLength(64);

        builder.Property(c => c.CreatedAtUtc)
            .IsRequired();

        builder.Property(c => c.ExpiresAtUtc)
            .IsRequired();

        builder.Property(c => c.IsRedeemed)
            .IsRequired();

        builder.Property(c => c.RedeemedAtUtc);

        builder.Property(c => c.RedeemedByDoctorId);

        // Unique index on CodeHash to ensure fast, deterministic single-use lookup
        builder.HasIndex(c => c.CodeHash)
            .IsUnique();

        // Index on (ChildId, ExpiresAtUtc) to rapidly invalidate previous unredeemed codes
        builder.HasIndex(c => new { c.ChildId, c.ExpiresAtUtc });

        builder.HasOne<Child>()
            .WithMany()
            .HasForeignKey(c => c.ChildId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne<DoctorProfile>()
            .WithMany()
            .HasForeignKey(c => c.RedeemedByDoctorId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
