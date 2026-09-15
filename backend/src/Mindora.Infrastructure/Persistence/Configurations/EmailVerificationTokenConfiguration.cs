using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Mindora.Domain.Entities;
using Mindora.Infrastructure.Identity;

namespace Mindora.Infrastructure.Persistence.Configurations;

public class EmailVerificationTokenConfiguration : IEntityTypeConfiguration<EmailVerificationToken>
{
    public void Configure(EntityTypeBuilder<EmailVerificationToken> builder)
    {
        builder.ToTable("EmailVerificationTokens");

        builder.HasKey(t => t.Id);

        builder.Property(t => t.UserId)
            .IsRequired();

        builder.Property(t => t.Email)
            .IsRequired()
            .HasMaxLength(256);

        builder.Property(t => t.Platform)
            .IsRequired();

        builder.Property(t => t.OtpHash)
            .IsRequired()
            .HasMaxLength(128);

        builder.Property(t => t.OtpExpiresAtUtc)
            .IsRequired();

        builder.Property(t => t.AttemptCount)
            .IsRequired();

        builder.Property(t => t.CreatedAtUtc)
            .IsRequired();

        builder.Property(t => t.LastRequestedAtUtc)
            .IsRequired();

        builder.Property(t => t.IsVerified)
            .IsRequired();

        builder.Property(t => t.VerifiedAtUtc);

        builder.Property(t => t.IsActive)
            .IsRequired();

        // Enforce at database level that at most ONE active verification OTP exists per (UserId, Platform)
        builder.HasIndex(t => new { t.UserId, t.Platform })
            .HasFilter("[IsActive] = 1")
            .IsUnique();

        // Index on Email and Platform for fast lookups
        builder.HasIndex(t => new { t.Email, t.Platform });

        // Foreign key to ApplicationUser (cascade on user deletion)
        builder.HasOne<ApplicationUser>()
            .WithMany()
            .HasForeignKey(t => t.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
