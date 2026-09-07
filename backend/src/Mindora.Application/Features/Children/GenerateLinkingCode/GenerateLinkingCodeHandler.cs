using System.Security.Cryptography;
using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Features.Children.Models;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Children.GenerateLinkingCode;

public class GenerateLinkingCodeHandler
{
    private const string CodeAlphabet = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"; // 32 characters, no ambiguous 0/O, 1/I/L
    private readonly ICurrentUserService _currentUserService;
    private readonly IApplicationDbContext _context;

    public GenerateLinkingCodeHandler(
        ICurrentUserService currentUserService,
        IApplicationDbContext context)
    {
        _currentUserService = currentUserService;
        _context = context;
    }

    public async Task<ChildLinkingCodeDto> HandleAsync(Guid childId, CancellationToken cancellationToken = default)
    {
        if (!_currentUserService.IsAuthenticated || _currentUserService.UserId == null)
        {
            throw new UnauthorizedException("User is not authenticated.");
        }

        if (_currentUserService.Role != UserRole.Parent)
        {
            throw new ForbiddenException("Only parents may generate linking codes for children.");
        }

        var userId = _currentUserService.UserId.Value;
        var parentProfile = _context.ParentProfiles.FirstOrDefault(p => p.UserId == userId);
        if (parentProfile == null)
        {
            throw new NotFoundException("ParentProfile", userId);
        }

        var child = _context.Children.FirstOrDefault(c => c.Id == childId && c.ParentId == parentProfile.Id);
        if (child == null)
        {
            throw new NotFoundException("Child", childId);
        }

        // Invalidate any existing active/unredeemed linking codes for this child
        var activeCodes = _context.ChildLinkingCodes
            .Where(c => c.ChildId == childId && !c.IsRedeemed && c.ExpiresAtUtc > DateTime.UtcNow)
            .ToList();

        foreach (var existingCode in activeCodes)
        {
            existingCode.Expire();
        }

        // Generate cryptographically secure random 6-character code
        var rawCode = GenerateRandomCode(6);
        var formattedCode = $"MND-{rawCode}";
        var codeHash = ChildLinkingCode.ComputeHash(formattedCode);

        var linkingCodeEntity = ChildLinkingCode.Create(child.Id, codeHash);
        _context.Add(linkingCodeEntity);
        await _context.SaveChangesAsync(cancellationToken);

        return new ChildLinkingCodeDto(formattedCode, linkingCodeEntity.ExpiresAtUtc, linkingCodeEntity.CreatedAtUtc);
    }

    private static string GenerateRandomCode(int length)
    {
        var chars = new char[length];
        var bytes = new byte[length];
        RandomNumberGenerator.Fill(bytes);

        for (int i = 0; i < length; i++)
        {
            chars[i] = CodeAlphabet[bytes[i] % CodeAlphabet.Length];
        }

        return new string(chars);
    }
}
