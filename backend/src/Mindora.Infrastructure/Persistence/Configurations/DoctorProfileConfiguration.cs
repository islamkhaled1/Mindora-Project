using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Mindora.Domain.Entities;
using Mindora.Infrastructure.Identity;

namespace Mindora.Infrastructure.Persistence.Configurations;

public class DoctorProfileConfiguration : IEntityTypeConfiguration<DoctorProfile>
{
    public void Configure(EntityTypeBuilder<DoctorProfile> builder)
    {
        builder.ToTable("DoctorProfiles");

        builder.HasKey(d => d.Id);

        builder.Property(d => d.UserId)
            .IsRequired();

        builder.Property(d => d.Specialization)
            .IsRequired()
            .HasMaxLength(150);

        builder.Property(d => d.ClinicName)
            .HasMaxLength(200);

        builder.Property(d => d.LicenseNumber)
            .HasMaxLength(100);

        builder.Property(d => d.CreatedAtUtc)
            .IsRequired();

        // 1-to-1 unique relationship with Identity ApplicationUser
        builder.HasIndex(d => d.UserId)
            .IsUnique();

        builder.HasOne<ApplicationUser>()
            .WithOne()
            .HasForeignKey<DoctorProfile>(d => d.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
