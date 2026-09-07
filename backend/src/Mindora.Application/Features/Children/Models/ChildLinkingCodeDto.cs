namespace Mindora.Application.Features.Children.Models;

public record ChildLinkingCodeDto(
    string Code,
    DateTime ExpiresAtUtc,
    DateTime CreatedAtUtc);
