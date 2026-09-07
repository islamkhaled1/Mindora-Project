namespace Mindora.Application.Features.Progress.GetChildProgressHistory;

public record GetChildProgressHistoryRequest(
    int Page = 1,
    int PageSize = 20,
    string? Domain = null,
    DateTime? FromDate = null,
    DateTime? ToDate = null);
