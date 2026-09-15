using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Mindora.Domain.Entities;
using Mindora.Infrastructure.Identity;

namespace Mindora.Infrastructure.Persistence.Configurations;

public class PasswordResetTokenConfiguration : IEntityTypeConfiguration<PasswordResetToken>
{
    public void Configure(EntityTypeBuilder<PasswordResetToken> builder)
    {
        builder.ToTable("PasswordResetTokens");

        builder.HasKey(t => t.Id);

        builder.Property(t => t.UserId)
            .IsRequired();

        builder.Property(t => t.Email)
            .IsRequired()
            .HasMaxLength(256);

        builder.Property(t => t.OtpHash)
            .IsRequired()
            .HasMaxLength(128);

        builder.Property(t => t.OtpExpiresAtUtc)
            .IsRequired();

        builder.Property(t => t.OtpAttempts)
            .IsRequired();

        builder.Property(t => t.IsOtpVerified)
            .IsRequired();

        builder.Property(t => t.OtpVerifiedAtUtc);

        builder.Property(t => t.ResetTokenHash)
            .HasMaxLength(128);

        builder.Property(t => t.ResetTokenExpiresAtUtc);

        builder.Property(t => t.IsUsed)
            .IsRequired();

        builder.Property(t => t.UsedAtUtc);

        builder.Property(t => t.CreatedAtUtc)
            .IsRequired();

        // Index on Email and IsUsed for fast active token lookups and cooldown checking
        builder.HasIndex(t => new { t.Email, t.IsUsed });

        // Index on ResetTokenHash for fast token validation
        builder.HasIndex(t => t.ResetTokenHash);

        // Foreign key to ApplicationUser (soft/cascade delete behavior)
        builder.HasOne<ApplicationUser>()
            .WithMany()
            .HasForeignKey(t => t.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
