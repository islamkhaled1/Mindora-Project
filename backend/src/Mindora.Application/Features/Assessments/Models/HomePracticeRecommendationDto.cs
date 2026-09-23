namespace Mindora.Application.Features.Assessments.Models;

/// <summary>
/// Full response for the GET /api/children/{childId}/home-practice-recommendation endpoint.
///
/// IsPreliminary is always true. This is a supportive preliminary home-practice suggestion,
/// not a medical treatment plan or clinical prescription.
/// </summary>
public record HomePracticeRecommendationDto(
    Guid ChildId,
    decimal OverallScore,

    /// <summary>
    /// Domains where the child shows relatively stronger performance.
    /// Ranked by relative score — NOT by an absolute clinical threshold.
    /// Emotional CAN appear here even though it has no activity mapping.
    /// </summary>
    IReadOnlyList<DomainProfileDto> Strengths,

    /// <summary>
    /// Domains where the child shows relatively lower performance.
    /// These drive the prioritised activity recommendations.
    /// </summary>
    IReadOnlyList<DomainProfileDto> FocusAreas,

    /// <summary>
    /// Small personalised set of recommended home-practice activities.
    /// Only includes domains that have a valid activity mapping
    /// (Motor→Movement, Communication→Speech, Cognitive→Attention).
    /// Emotional domain NEVER generates activity recommendations.
    /// </summary>
    IReadOnlyList<RecommendedActivityDto> RecommendedActivities,

    /// <summary>Always true — indicates these are preliminary suggestions.</summary>
    bool IsPreliminary,

    /// <summary>Arabic disclaimer string — must always be displayed to the user.</summary>
    string Disclaimer,

    DateTime GeneratedAtUtc);

/// <summary>
/// Represents one assessment domain in the child's preliminary performance profile.
/// All four assessment domains appear here (Motor, Communication, Cognitive, Emotional).
/// HasActivityMapping = false for Emotional until a dedicated activity domain is added.
/// </summary>
public record DomainProfileDto(
    /// <summary>"Motor" | "Communication" | "Cognitive" | "Emotional"</summary>
    string AssessmentDomain,

    /// <summary>Arabic display name shown in the UI.</summary>
    string AssessmentDomainArabic,

    decimal Score,

    /// <summary>
    /// UI display label only — NOT a clinical assessment.
    /// "قوة واضحة" | "مستوى متوسط" | "مجال للتركيز"
    /// </summary>
    string Level,

    /// <summary>
    /// True for Motor, Communication, Cognitive.
    /// False for Emotional — no dedicated activity domain exists yet.
    /// </summary>
    bool HasActivityMapping);

/// <summary>
/// A single recommended home-practice activity.
/// Only created for domains with valid mappings.
/// Reason string explains the product logic in plain Arabic — not clinical language.
/// </summary>
public record RecommendedActivityDto(
    Guid ActivityId,
    string Title,
    string Description,

    /// <summary>"Movement" | "Speech" | "Attention" (backend ActivityDomain enum name)</summary>
    string ActivityDomain,

    /// <summary>Arabic display label for the activity domain.</summary>
    string ActivityDomainArabic,

    /// <summary>"Motor" | "Communication" | "Cognitive"</summary>
    string AssessmentDomain,

    /// <summary>"Beginner" | "Intermediate" | "Advanced"</summary>
    string BaseDifficulty,

    /// <summary>Arabic display label for difficulty.</summary>
    string BaseDifficultyArabic,

    /// <summary>"High" for Focus Area activities. "Low" for Strength/maintenance activities.</summary>
    string Priority,

    /// <summary>Arabic display label for priority.</summary>
    string PriorityArabic,

    /// <summary>
    /// Plain Arabic product-logic rationale.
    /// Explains WHY this activity was selected based on the assessment result.
    /// Example: "تم ترشيح هذا النشاط لأن التواصل يُعد المجال الأولى بالتركيز حالياً."
    /// Must NOT contain clinical claims.
    /// </summary>
    string Reason,

    /// <summary>
    /// Configurable product heuristic. NOT a medical prescription.
    /// Example: "٣ مرات أسبوعياً"
    /// </summary>
    string SuggestedPracticeFrequency,

    /// <summary>Always true.</summary>
    bool IsPreliminary);
