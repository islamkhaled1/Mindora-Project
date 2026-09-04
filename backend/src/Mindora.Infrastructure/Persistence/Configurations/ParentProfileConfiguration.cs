using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Mindora.Domain.Entities;
using Mindora.Infrastructure.Identity;

namespace Mindora.Infrastructure.Persistence.Configurations;

public class ParentProfileConfiguration : IEntityTypeConfiguration<ParentProfile>
{
    public void Configure(EntityTypeBuilder<ParentProfile> builder)
    {
        builder.ToTable("ParentProfiles");

        builder.HasKey(p => p.Id);

        builder.Property(p => p.UserId)
            .IsRequired();

        builder.Property(p => p.PhoneNumber)
            .HasMaxLength(30);

        builder.Property(p => p.CreatedAtUtc)
            .IsRequired();

        // 1-to-1 unique relationship with Identity ApplicationUser
        builder.HasIndex(p => p.UserId)
            .IsUnique();

        builder.HasOne<ApplicationUser>()
            .WithOne()
            .HasForeignKey<ParentProfile>(p => p.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
