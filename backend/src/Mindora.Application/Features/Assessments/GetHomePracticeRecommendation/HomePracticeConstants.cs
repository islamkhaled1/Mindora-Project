namespace Mindora.Application.Features.Assessments.GetHomePracticeRecommendation;

/// <summary>
/// Configurable product-level constants for the Home Practice Recommendation engine.
///
/// IMPORTANT: These are product-level heuristics, NOT clinically validated values.
/// They should be reviewed by a qualified specialist before being presented as clinical guidance.
/// All frequency suggestions must be shown alongside the standard preliminary disclaimer.
/// </summary>
public static class HomePracticeConstants
{
    // ─── Score thresholds for DISPLAY LABELS only ────────────────────────────
    // These are NOT used for recommendation priority decisions.
    // Recommendation priority is driven entirely by relative domain ranking.

    /// <summary>Score at or above which a domain is labelled "قوة واضحة".</summary>
    public const decimal StrongLevelThreshold = 75m;

    /// <summary>Score at or above which a domain is labelled "مستوى متوسط".</summary>
    public const decimal MidLevelThreshold = 50m;

    // Below MidLevelThreshold → labelled "مجال للتركيز"

    // ─── Difficulty selection thresholds ─────────────────────────────────────
    // Determines the PREFERRED starting difficulty for activity selection.
    // Deterministic and catalog-driven. NOT a clinical difficulty assignment.

    /// <summary>
    /// Domain scores at or above this value suggest starting at Intermediate difficulty.
    /// Below this value → prefer Beginner.
    /// </summary>
    public const decimal IntermediatePreferenceThreshold = 75m;

    // ─── Activity limits per area ─────────────────────────────────────────────
    public const int MaxActivitiesPerPrimaryFocus = 2;
    public const int MaxActivitiesPerSecondaryFocus = 2;
    public const int MaxActivitiesPerStrength = 1;

    // ─── Practice frequency suggestions ──────────────────────────────────────
    // Product heuristics only. NOT medically prescribed.
    // Change these after expert review without touching recommendation logic.

    /// <summary>Suggested weekly practice frequency for a Primary Focus domain.</summary>
    public const string PrimaryFocusFrequency = "٣ مرات أسبوعياً";

    /// <summary>Suggested weekly practice frequency for a Secondary Focus domain.</summary>
    public const string SecondaryFocusFrequency = "٣ مرات أسبوعياً";

    /// <summary>Suggested weekly practice frequency for a Strength/Maintenance domain.</summary>
    public const string MaintenanceFrequency = "١–٢ مرات أسبوعياً";

    // ─── Disclaimer ───────────────────────────────────────────────────────────
    /// <summary>Standard Arabic disclaimer shown on all recommendation responses.</summary>
    public const string Disclaimer =
        "هذه التوصيات مبدئية للممارسة المنزلية، ويُفضل مراجعتها مع المختص.";
}
