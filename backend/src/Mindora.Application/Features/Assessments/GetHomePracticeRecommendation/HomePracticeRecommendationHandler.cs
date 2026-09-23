using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Features.Assessments.Models;
using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Assessments.GetHomePracticeRecommendation;

/// <summary>
/// Generates a preliminary home-practice recommendation from a child's baseline assessment scores.
///
/// DESIGN CONTRACT:
/// - No database schema changes. Reads existing BaselineAssessment and Activity records only.
/// - No AI/LLM involvement. All decisions are deterministic and explainable.
/// - Emotional domain never generates activity recommendations.
/// - Domain ranking (relative) drives Strength/FocusArea classification, not an absolute threshold.
/// - Absolute thresholds are used ONLY for display level labels.
/// - All frequency values come from HomePracticeConstants — configurable without code changes.
/// </summary>
public class HomePracticeRecommendationHandler
{
    private readonly ICurrentUserService _currentUserService;
    private readonly IApplicationDbContext _context;

    public HomePracticeRecommendationHandler(
        ICurrentUserService currentUserService,
        IApplicationDbContext context)
    {
        _currentUserService = currentUserService;
        _context = context;
    }

    // ─── Domain metadata ──────────────────────────────────────────────────────
    // Strict explicit mapping. No fallbacks invented.
    // Emotional has no mapping — it NEVER generates activities.

    private static readonly IReadOnlyDictionary<string, ActivityDomain?> AssessmentToActivityDomain =
        new Dictionary<string, ActivityDomain?>
        {
            ["Motor"]         = ActivityDomain.Movement,
            ["Communication"] = ActivityDomain.Speech,
            ["Cognitive"]     = ActivityDomain.Attention,
            ["Emotional"]     = null  // no activity domain — never generates recommendations
        };

    private static readonly IReadOnlyDictionary<string, string> DomainArabicNames =
        new Dictionary<string, string>
        {
            ["Motor"]         = "المهارات الحركية",
            ["Communication"] = "التواصل واللغة",
            ["Cognitive"]     = "الإدراك والتعلم",
            ["Emotional"]     = "المهارات الاجتماعية والعاطفية"
        };

    private static readonly IReadOnlyDictionary<ActivityDomain, string> ActivityDomainArabicNames =
        new Dictionary<ActivityDomain, string>
        {
            [ActivityDomain.Movement]  = "الحركة",
            [ActivityDomain.Speech]    = "اللغة والنطق",
            [ActivityDomain.Attention] = "الانتباه والتركيز"
        };

    // Tie-breaking precedence: lower index = treated as weaker first when scores are equal.
    // Communication > Cognitive > Motor > Emotional
    private static readonly List<string> TieBreakingPrecedence =
        new() { "Communication", "Cognitive", "Motor", "Emotional" };

    // ─── Public entry point ───────────────────────────────────────────────────

    public async Task<HomePracticeRecommendationDto> HandleAsync(
        Guid childId,
        CancellationToken cancellationToken = default)
    {
        // ── Authorization ─────────────────────────────────────────────────────
        if (!_currentUserService.IsAuthenticated || _currentUserService.UserId == null)
            throw new UnauthorizedException("User is not authenticated.");

        var userId = _currentUserService.UserId.Value;
        var role = _currentUserService.Role;

        if (role == UserRole.Parent)
        {
            var parentProfile = _context.ParentProfiles
                .FirstOrDefault(p => p.UserId == userId);
            if (parentProfile == null)
                throw new NotFoundException("ParentProfile", userId);

            var ownsChild = _context.Children
                .Any(c => c.Id == childId && c.ParentId == parentProfile.Id);
            if (!ownsChild)
                throw new NotFoundException("Child", childId);
        }
        else if (role == UserRole.Doctor)
        {
            var doctorProfile = _context.DoctorProfiles
                .FirstOrDefault(d => d.UserId == userId);
            if (doctorProfile == null)
                throw new NotFoundException("DoctorProfile", userId);

            var isAssigned = _context.DoctorChildAssignments
                .Any(a => a.DoctorId == doctorProfile.Id && a.ChildId == childId && a.IsActive);
            if (!isAssigned)
                throw new NotFoundException("Child", childId);
        }
        else
        {
            throw new ForbiddenException("You do not have permission to view home practice recommendations.");
        }

        // ── Load latest assessment ────────────────────────────────────────────
        var assessment = _context.BaselineAssessments
            .Where(b => b.ChildId == childId)
            .OrderByDescending(b => b.CompletedAtUtc)
            .FirstOrDefault();

        if (assessment == null)
            throw new NotFoundException("BaselineAssessment", childId);

        // ── Load active activities ────────────────────────────────────────────
        var allActivities = _context.Activities
            .Where(a => a.IsActive)
            .ToList();

        // ── Run personalization engine ────────────────────────────────────────
        return BuildRecommendation(childId, assessment.OverallScore, new Dictionary<string, decimal>
        {
            ["Motor"]         = assessment.MotorScore,
            ["Communication"] = assessment.CommunicationScore,
            ["Cognitive"]     = assessment.CognitiveScore,
            ["Emotional"]     = assessment.EmotionalScore
        }, allActivities);
    }

    // ─── Core engine (public static — independently testable with no DB/DI) ──

    /// <summary>
    /// Pure in-memory personalization logic.
    /// Separated from the handler so unit tests can call it without a DB context.
    /// </summary>
    public static HomePracticeRecommendationDto BuildRecommendation(
        Guid childId,
        decimal overallScore,
        IReadOnlyDictionary<string, decimal> domainScores,
        IReadOnlyList<Domain.Entities.Activity> activeActivities)
    {
        // STEP 1 — Rank domains by score, lowest first.
        // Ties are broken deterministically by TieBreakingPrecedence:
        // Communication → Cognitive → Motor → Emotional
        var ranked = domainScores
            .OrderBy(kv => kv.Value)
            .ThenBy(kv => TieBreakingPrecedence.IndexOf(kv.Key))
            .Select(kv => kv.Key)
            .ToList();

        // STEP 2 — Split: bottom half = Focus Areas, top half = Strengths
        int focusCount = ranked.Count / 2;  // 2 out of 4
        var focusDomains  = ranked.Take(focusCount).ToList();       // ranks 1–2 (lowest)
        var strengthDomains = ranked.Skip(focusCount).ToList();     // ranks 3–4 (highest)

        // STEP 3 — Build performance profile DTOs (all 4 domains, including Emotional)
        var strengthDtos = strengthDomains
            .Select(d => BuildDomainProfile(d, domainScores[d]))
            .ToList();

        var focusDtos = focusDomains
            .Select(d => BuildDomainProfile(d, domainScores[d]))
            .ToList();

        // STEP 4 — Build activity recommendations
        // Only domains with a valid ActivityDomain mapping generate recommendations.
        // Emotional is always excluded.
        var recommendations = new List<RecommendedActivityDto>();

        for (int i = 0; i < focusDomains.Count; i++)
        {
            string assessmentDomain = focusDomains[i];
            bool isPrimary = (i == 0);  // rank 1 is primary focus

            if (!AssessmentToActivityDomain.TryGetValue(assessmentDomain, out var activityDomain)
                || activityDomain == null)
            {
                // Emotional or unmapped domain — skip activity generation entirely.
                continue;
            }

            decimal score = domainScores[assessmentDomain];
            string frequency = isPrimary
                ? HomePracticeConstants.PrimaryFocusFrequency
                : HomePracticeConstants.SecondaryFocusFrequency;

            string reason = isPrimary
                ? $"تم ترشيح هذا النشاط لأن {DomainArabicNames[assessmentDomain]} يُعد المجال الأولى بالتركيز حالياً."
                : $"تم ترشيح هذا النشاط لأن {DomainArabicNames[assessmentDomain]} يُعد من مجالات التركيز الحالية.";

            int limit = isPrimary
                ? HomePracticeConstants.MaxActivitiesPerPrimaryFocus
                : HomePracticeConstants.MaxActivitiesPerSecondaryFocus;

            var selected = SelectActivities(
                activityDomain.Value,
                score,
                limit,
                activeActivities);

            foreach (var activity in selected)
            {
                recommendations.Add(BuildActivityDto(
                    activity,
                    assessmentDomain,
                    priority: "High",
                    priorityArabic: "أولوية عالية",
                    reason: reason,
                    frequency: frequency));
            }
        }

        // Maintenance activities from strength domains (up to 1 each, mappable only)
        foreach (string assessmentDomain in strengthDomains)
        {
            if (!AssessmentToActivityDomain.TryGetValue(assessmentDomain, out var activityDomain)
                || activityDomain == null)
            {
                continue;  // Emotional or unmapped — skip
            }

            decimal score = domainScores[assessmentDomain];
            string reason =
                $"تم ترشيح هذا النشاط للمحافظة على مستوى {DomainArabicNames[assessmentDomain]} الجيد.";

            var selected = SelectActivities(
                activityDomain.Value,
                score,
                HomePracticeConstants.MaxActivitiesPerStrength,
                activeActivities);

            foreach (var activity in selected)
            {
                recommendations.Add(BuildActivityDto(
                    activity,
                    assessmentDomain,
                    priority: "Low",
                    priorityArabic: "صيانة وتعزيز",
                    reason: reason,
                    frequency: HomePracticeConstants.MaintenanceFrequency));
            }
        }

        return new HomePracticeRecommendationDto(
            ChildId: childId,
            OverallScore: overallScore,
            Strengths: strengthDtos,
            FocusAreas: focusDtos,
            RecommendedActivities: recommendations,
            IsPreliminary: true,
            Disclaimer: HomePracticeConstants.Disclaimer,
            GeneratedAtUtc: DateTime.UtcNow);
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    /// <summary>
    /// Selects up to <paramref name="limit"/> activities for a given domain.
    /// Preferred difficulty is determined by the domain score (product heuristic, not clinical).
    /// Falls back to any available difficulty if preferred tier has no activities.
    /// Returns empty list (never throws) if no activities exist in the domain.
    /// </summary>
    private static List<Domain.Entities.Activity> SelectActivities(
        ActivityDomain targetDomain,
        decimal domainScore,
        int limit,
        IReadOnlyList<Domain.Entities.Activity> allActivities)
    {
        // Preferred difficulty: Intermediate if score ≥ 75, otherwise Beginner.
        // This is a transparent product heuristic, not a clinical standard.
        DifficultyLevel preferredDifficulty = domainScore >= HomePracticeConstants.IntermediatePreferenceThreshold
            ? DifficultyLevel.Intermediate
            : DifficultyLevel.Beginner;

        var inDomain = allActivities
            .Where(a => a.Domain == targetDomain)
            .ToList();

        if (!inDomain.Any())
            return new List<Domain.Entities.Activity>(); // no activities — skip silently

        // Try preferred difficulty first
        var preferred = inDomain
            .Where(a => a.BaseDifficulty == preferredDifficulty)
            .Take(limit)
            .ToList();

        if (preferred.Any())
            return preferred;

        // Fallback: any difficulty in the domain, ordered by difficulty ascending
        return inDomain
            .OrderBy(a => (int)a.BaseDifficulty)
            .Take(limit)
            .ToList();
    }

    private static DomainProfileDto BuildDomainProfile(string assessmentDomain, decimal score)
    {
        string level = score >= HomePracticeConstants.StrongLevelThreshold
            ? "قوة واضحة"
            : score >= HomePracticeConstants.MidLevelThreshold
                ? "مستوى متوسط"
                : "مجال للتركيز";

        bool hasMapping = AssessmentToActivityDomain.TryGetValue(assessmentDomain, out var mapped)
                          && mapped != null;

        return new DomainProfileDto(
            AssessmentDomain: assessmentDomain,
            AssessmentDomainArabic: DomainArabicNames.GetValueOrDefault(assessmentDomain, assessmentDomain),
            Score: score,
            Level: level,
            HasActivityMapping: hasMapping);
    }

    private static RecommendedActivityDto BuildActivityDto(
        Domain.Entities.Activity activity,
        string assessmentDomain,
        string priority,
        string priorityArabic,
        string reason,
        string frequency)
    {
        string difficultyArabic = activity.BaseDifficulty switch
        {
            DifficultyLevel.Beginner     => "مبتدئ",
            DifficultyLevel.Intermediate => "متوسط",
            DifficultyLevel.Advanced     => "متقدم",
            _                            => activity.BaseDifficulty.ToString()
        };

        string activityDomainArabic = ActivityDomainArabicNames.GetValueOrDefault(
            activity.Domain, activity.Domain.ToString());

        return new RecommendedActivityDto(
            ActivityId: activity.Id,
            Title: activity.Title,
            Description: activity.Description,
            ActivityDomain: activity.Domain.ToString(),
            ActivityDomainArabic: activityDomainArabic,
            AssessmentDomain: assessmentDomain,
            BaseDifficulty: activity.BaseDifficulty.ToString(),
            BaseDifficultyArabic: difficultyArabic,
            Priority: priority,
            PriorityArabic: priorityArabic,
            Reason: reason,
            SuggestedPracticeFrequency: frequency,
            IsPreliminary: true);
    }
}
