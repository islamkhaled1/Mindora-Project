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

        // P0 Doctor Referral Code from UI Audit
        builder.Property(d => d.ReferralCode)
            .IsRequired()
            .HasMaxLength(50);

        builder.Property(d => d.CreatedAtUtc)
            .IsRequired();

        builder.Property(d => d.Gender)
            .HasConversion<int>();

        // 1-to-1 unique relationship with Identity ApplicationUser
        builder.HasIndex(d => d.UserId)
            .IsUnique();

        // Unique index on ReferralCode to enable fast lookups and prevent duplicates
        builder.HasIndex(d => d.ReferralCode)
            .IsUnique();

        builder.HasOne<ApplicationUser>()
            .WithOne()
            .HasForeignKey<DoctorProfile>(d => d.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
