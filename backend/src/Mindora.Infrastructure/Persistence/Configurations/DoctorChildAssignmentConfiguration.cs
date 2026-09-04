using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Mindora.Domain.Entities;

namespace Mindora.Infrastructure.Persistence.Configurations;

public class DoctorChildAssignmentConfiguration : IEntityTypeConfiguration<DoctorChildAssignment>
{
    public void Configure(EntityTypeBuilder<DoctorChildAssignment> builder)
    {
        builder.ToTable("DoctorChildAssignments");

        builder.HasKey(a => a.Id);

        builder.Property(a => a.DoctorId)
            .IsRequired();

        builder.Property(a => a.ChildId)
            .IsRequired();

        builder.Property(a => a.AssignedAtUtc)
            .IsRequired();

        builder.Property(a => a.IsActive)
            .IsRequired();

        // Index on (DoctorId, ChildId) for efficient patient roster queries
        builder.HasIndex(a => new { a.DoctorId, a.ChildId });

        builder.HasOne<DoctorProfile>()
            .WithMany()
            .HasForeignKey(a => a.DoctorId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne<Child>()
            .WithMany()
            .HasForeignKey(a => a.ChildId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
