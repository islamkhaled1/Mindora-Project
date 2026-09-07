using Mindora.Domain.Common;
using Mindora.Domain.Entities;
using Xunit;

namespace Mindora.UnitTests.Domain;

public class ChildLinkingCodeTests
{
    [Fact]
    public void Create_WithValidParameters_InitializesCorrectly()
    {
        // Arrange
        var childId = Guid.NewGuid();
        var rawCode = "MND-ABC123";
        var hash = ChildLinkingCode.ComputeHash(rawCode);
        var now = DateTime.UtcNow;

        // Act
        var linkingCode = ChildLinkingCode.Create(childId, hash, TimeSpan.FromHours(48), now);

        // Assert
        Assert.NotEqual(Guid.Empty, linkingCode.Id);
        Assert.Equal(childId, linkingCode.ChildId);
        Assert.Equal(hash.ToLowerInvariant(), linkingCode.CodeHash);
        Assert.Equal(now, linkingCode.CreatedAtUtc);
        Assert.Equal(now.AddHours(48), linkingCode.ExpiresAtUtc);
        Assert.False(linkingCode.IsRedeemed);
        Assert.Null(linkingCode.RedeemedAtUtc);
        Assert.Null(linkingCode.RedeemedByDoctorId);
        Assert.False(linkingCode.IsExpired(now));
    }

    [Fact]
    public void Create_WithEmptyChildId_ThrowsDomainException()
    {
        var hash = ChildLinkingCode.ComputeHash("TEST12");
        Assert.Throws<DomainException>(() =>
            ChildLinkingCode.Create(Guid.Empty, hash, TimeSpan.FromHours(1)));
    }

    [Fact]
    public void Create_WithEmptyCodeHash_ThrowsDomainException()
    {
        Assert.Throws<DomainException>(() =>
            ChildLinkingCode.Create(Guid.NewGuid(), "", TimeSpan.FromHours(1)));
    }

    [Fact]
    public void Create_WithExpirationBeforeCreation_ThrowsDomainException()
    {
        var hash = ChildLinkingCode.ComputeHash("TEST12");
        var now = DateTime.UtcNow;
        Assert.Throws<DomainException>(() =>
            new ChildLinkingCode(Guid.NewGuid(), Guid.NewGuid(), hash, now, now.AddHours(-1)));
    }

    [Fact]
    public void ComputeHash_NormalizesHyphensAndCase()
    {
        var hash1 = ChildLinkingCode.ComputeHash("mnd-abc123");
        var hash2 = ChildLinkingCode.ComputeHash("MND-ABC123");
        var hash3 = ChildLinkingCode.ComputeHash("ABC123");

        Assert.Equal(hash1, hash2);
        Assert.Equal(hash1, hash3);
    }

    [Fact]
    public void IsExpired_ReturnsFalseBeforeExpiry_AndTrueAfterExpiry()
    {
        var childId = Guid.NewGuid();
        var hash = ChildLinkingCode.ComputeHash("ABC123");
        var now = DateTime.UtcNow;
        var linkingCode = ChildLinkingCode.Create(childId, hash, TimeSpan.FromHours(1), now);

        // Not expired before expiration
        Assert.False(linkingCode.IsExpired(now.AddMinutes(30)));

        // Expired after expiration
        Assert.True(linkingCode.IsExpired(now.AddHours(2)));

        // Redeem
        var doctorId = Guid.NewGuid();
        linkingCode.Redeem(doctorId, now.AddMinutes(10));
        Assert.True(linkingCode.IsRedeemed);
    }

    [Fact]
    public void Redeem_WhenValid_SetsRedemptionDetails()
    {
        var childId = Guid.NewGuid();
        var doctorId = Guid.NewGuid();
        var hash = ChildLinkingCode.ComputeHash("ABC123");
        var now = DateTime.UtcNow;
        var linkingCode = ChildLinkingCode.Create(childId, hash, TimeSpan.FromHours(48), now);

        linkingCode.Redeem(doctorId, now.AddHours(1));

        Assert.True(linkingCode.IsRedeemed);
        Assert.Equal(doctorId, linkingCode.RedeemedByDoctorId);
        Assert.Equal(now.AddHours(1), linkingCode.RedeemedAtUtc);
    }

    [Fact]
    public void Redeem_WhenAlreadyRedeemed_ThrowsDomainException()
    {
        var childId = Guid.NewGuid();
        var doctorId = Guid.NewGuid();
        var hash = ChildLinkingCode.ComputeHash("ABC123");
        var now = DateTime.UtcNow;
        var linkingCode = ChildLinkingCode.Create(childId, hash, TimeSpan.FromHours(48), now);

        linkingCode.Redeem(doctorId, now);
        Assert.Throws<DomainException>(() => linkingCode.Redeem(doctorId, now.AddMinutes(5)));
    }

    [Fact]
    public void Redeem_WhenExpired_ThrowsDomainException()
    {
        var childId = Guid.NewGuid();
        var doctorId = Guid.NewGuid();
        var hash = ChildLinkingCode.ComputeHash("ABC123");
        var now = DateTime.UtcNow;
        var linkingCode = ChildLinkingCode.Create(childId, hash, TimeSpan.FromHours(1), now);

        Assert.Throws<DomainException>(() => linkingCode.Redeem(doctorId, now.AddHours(2)));
    }

    [Fact]
    public void Redeem_WithEmptyDoctorId_ThrowsDomainException()
    {
        var childId = Guid.NewGuid();
        var hash = ChildLinkingCode.ComputeHash("ABC123");
        var now = DateTime.UtcNow;
        var linkingCode = ChildLinkingCode.Create(childId, hash, TimeSpan.FromHours(1), now);

        Assert.Throws<DomainException>(() => linkingCode.Redeem(Guid.Empty, now));
    }
}
