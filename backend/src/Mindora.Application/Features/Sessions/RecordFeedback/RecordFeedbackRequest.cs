using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Sessions.RecordFeedback;

public record RecordFeedbackRequest(
    ParentSentimentRating Rating,
    string? Notes = null);
