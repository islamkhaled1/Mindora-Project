using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Mindora.Domain.Entities;

namespace Mindora.Infrastructure.Persistence.Configurations;

public class DoctorLinkRequestConfiguration : IEntityTypeConfiguration<DoctorLinkRequest>
{
    public void Configure(EntityTypeBuilder<DoctorLinkRequest> builder)
    {
        builder.ToTable("DoctorLinkRequests");

        builder.HasKey(r => r.Id);

        builder.Property(r => r.DoctorId)
            .IsRequired();

        builder.Property(r => r.ParentId)
            .IsRequired();

        builder.Property(r => r.ChildId)
            .IsRequired();

        builder.Property(r => r.Status)
            .IsRequired()
            .HasConversion<int>();

        builder.Property(r => r.CreatedAtUtc)
            .IsRequired();

        builder.Property(r => r.RespondedAtUtc)
            .IsRequired(false);

        // Index for doctor's pending requests queue
        builder.HasIndex(r => new { r.DoctorId, r.Status });

        // Index for child/parent duplicate checks
        builder.HasIndex(r => new { r.ChildId, r.DoctorId, r.Status });

        builder.HasOne<DoctorProfile>()
            .WithMany()
            .HasForeignKey(r => r.DoctorId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne<ParentProfile>()
            .WithMany()
            .HasForeignKey(r => r.ParentId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne<Child>()
            .WithMany()
            .HasForeignKey(r => r.ChildId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
