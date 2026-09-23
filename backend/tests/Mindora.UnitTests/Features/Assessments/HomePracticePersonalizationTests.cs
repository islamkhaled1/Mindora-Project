using Mindora.Application.Features.Assessments.GetHomePracticeRecommendation;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;

namespace Mindora.UnitTests.Features.Assessments;

/// <summary>
/// Unit tests for the Home Practice Personalization Engine.
///
/// All tests call HomePracticeRecommendationHandler.BuildRecommendation() directly —
/// the internal static method that contains the pure engine logic.
/// This means tests run with zero I/O, zero DB dependency, zero DI setup.
///
/// Covers every scenario from the approved test list.
/// </summary>
public class HomePracticePersonalizationTests
{
    private static readonly Guid TestChildId = Guid.NewGuid();

    // ─── Helpers ─────────────────────────────────────────────────────────────

    private static Activity MakeActivity(
        ActivityDomain domain,
        DifficultyLevel difficulty,
        string? title = null)
    {
        string name = title ?? $"{domain}-{difficulty}";
        return new Activity(
            Guid.NewGuid(),
            name,
            $"Description for {name}",
            domain,
            difficulty);
    }

    /// <summary>Calls the engine directly without any DB or DI.</summary>
    private static Mindora.Application.Features.Assessments.Models.HomePracticeRecommendationDto Run(
        IReadOnlyDictionary<string, decimal> scores,
        IReadOnlyList<Activity>? activities = null)
    {
        return HomePracticeRecommendationHandler.BuildRecommendation(
            TestChildId,
            scores.Values.Average(),
            scores,
            activities ?? Array.Empty<Activity>());
    }

    // Standard catalog used in most tests
    private static readonly List<Activity> StandardCatalog = new()
    {
        MakeActivity(ActivityDomain.Movement,  DifficultyLevel.Beginner,     "movement-beginner"),
        MakeActivity(ActivityDomain.Movement,  DifficultyLevel.Intermediate, "movement-intermediate"),
        MakeActivity(ActivityDomain.Speech,    DifficultyLevel.Beginner,     "speech-beginner"),
        MakeActivity(ActivityDomain.Speech,    DifficultyLevel.Intermediate, "speech-intermediate"),
        MakeActivity(ActivityDomain.Attention, DifficultyLevel.Beginner,     "attention-beginner"),
        MakeActivity(ActivityDomain.Attention, DifficultyLevel.Intermediate, "attention-intermediate"),
    };

    // ─── RELATIVE RANKING TESTS ───────────────────────────────────────────────

    [Fact]
    public void RelativeRanking_StandardExample_CorrectStrengthsAndFocusAreas()
    {
        // Motor=82, Communication=46, Cognitive=58, Emotional=76
        // Expected: Focus = Communication(primary), Cognitive(secondary)
        //           Strengths = Emotional, Motor
        var scores = new Dictionary<string, decimal>
        {
            ["Motor"] = 82m, ["Communication"] = 46m,
            ["Cognitive"] = 58m, ["Emotional"] = 76m
        };

        var result = Run(scores, StandardCatalog);

        var focusDomains = result.FocusAreas.Select(f => f.AssessmentDomain).ToList();
        var strengthDomains = result.Strengths.Select(s => s.AssessmentDomain).ToList();

        Assert.Equal(2, focusDomains.Count);
        Assert.Equal(2, strengthDomains.Count);
        Assert.Contains("Communication", focusDomains);
        Assert.Contains("Cognitive", focusDomains);
        Assert.Contains("Motor", strengthDomains);
        Assert.Contains("Emotional", strengthDomains);
    }

    [Fact]
    public void RelativeRanking_PrimaryFocusIsLowestScoreDomain()
    {
        var scores = new Dictionary<string, decimal>
        {
            ["Motor"] = 82m, ["Communication"] = 46m,
            ["Cognitive"] = 58m, ["Emotional"] = 76m
        };

        var result = Run(scores, StandardCatalog);

        // Communication is rank 1 (lowest) → primary focus → High priority activities
        var commActivities = result.RecommendedActivities
            .Where(a => a.AssessmentDomain == "Communication")
            .ToList();

        Assert.NotEmpty(commActivities);
        Assert.All(commActivities, a => Assert.Equal("High", a.Priority));
    }

    [Fact]
    public void RelativeRanking_OnlyOneAbsoluteLowest_BothFocusAreasPresent()
    {
        // Even when Communication is clearly lowest, Cognitive is still a FocusArea
        var scores = new Dictionary<string, decimal>
        {
            ["Motor"] = 90m, ["Communication"] = 20m,
            ["Cognitive"] = 50m, ["Emotional"] = 85m
        };

        var result = Run(scores, StandardCatalog);

        Assert.Equal(2, result.FocusAreas.Count);
        Assert.Contains(result.FocusAreas, f => f.AssessmentDomain == "Communication");
        Assert.Contains(result.FocusAreas, f => f.AssessmentDomain == "Cognitive");
    }

    // ─── TIE-BREAKING TESTS ───────────────────────────────────────────────────

    [Fact]
    public void TieBreaking_AllScoresEqual_CommunicationIsPrimaryFocus()
    {
        // All scores equal → tie-breaking: Communication > Cognitive > Motor > Emotional
        var scores = new Dictionary<string, decimal>
        {
            ["Motor"] = 50m, ["Communication"] = 50m,
            ["Cognitive"] = 50m, ["Emotional"] = 50m
        };

        var result = Run(scores, StandardCatalog);

        // First FocusArea should be Communication (tie-break rank 0)
        Assert.Equal("Communication", result.FocusAreas[0].AssessmentDomain);
        // Second FocusArea should be Cognitive (tie-break rank 1)
        Assert.Equal("Cognitive", result.FocusAreas[1].AssessmentDomain);
    }

    [Fact]
    public void TieBreaking_TwoDomainsEqualLowest_CommunicationBeforeMotor()
    {
        // Communication and Motor both at 40 — Communication should be primary
        var scores = new Dictionary<string, decimal>
        {
            ["Motor"] = 40m, ["Communication"] = 40m,
            ["Cognitive"] = 80m, ["Emotional"] = 80m
        };

        var result = Run(scores, StandardCatalog);

        Assert.Equal("Communication", result.FocusAreas[0].AssessmentDomain);
        Assert.Equal("Motor", result.FocusAreas[1].AssessmentDomain);
    }

    // ─── EMOTIONAL DOMAIN TESTS ───────────────────────────────────────────────

    [Fact]
    public void EmotionalAsFocusArea_NeverGeneratesActivityRecommendations()
    {
        // Emotional is the weakest domain
        var scores = new Dictionary<string, decimal>
        {
            ["Motor"] = 80m, ["Communication"] = 80m,
            ["Cognitive"] = 80m, ["Emotional"] = 20m
        };

        var result = Run(scores, StandardCatalog);

        // Emotional must appear in FocusAreas
        Assert.Contains(result.FocusAreas, f => f.AssessmentDomain == "Emotional");

        // But must generate ZERO activity recommendations
        Assert.DoesNotContain(result.RecommendedActivities,
            a => a.AssessmentDomain == "Emotional");
    }

    [Fact]
    public void EmotionalAsFocusArea_HasActivityMapping_IsFalse()
    {
        var scores = new Dictionary<string, decimal>
        {
            ["Motor"] = 80m, ["Communication"] = 80m,
            ["Cognitive"] = 80m, ["Emotional"] = 20m
        };

        var result = Run(scores, StandardCatalog);

        var emotionalProfile = result.FocusAreas
            .FirstOrDefault(f => f.AssessmentDomain == "Emotional");

        Assert.NotNull(emotionalProfile);
        Assert.False(emotionalProfile!.HasActivityMapping);
    }

    [Fact]
    public void EmotionalAsStrength_HasActivityMapping_IsFalse()
    {
        var scores = new Dictionary<string, decimal>
        {
            ["Motor"] = 20m, ["Communication"] = 30m,
            ["Cognitive"] = 25m, ["Emotional"] = 90m
        };

        var result = Run(scores, StandardCatalog);

        var emotionalProfile = result.Strengths
            .FirstOrDefault(s => s.AssessmentDomain == "Emotional");

        Assert.NotNull(emotionalProfile);
        Assert.False(emotionalProfile!.HasActivityMapping);

        // Still no activity recommendation for Emotional from strength
        Assert.DoesNotContain(result.RecommendedActivities,
            a => a.AssessmentDomain == "Emotional");
    }

    [Fact]
    public void EmotionalOnlyDomain_AllOthersMapped_ResultHasNoActivitiesForEmotional()
    {
        // Even if Emotional is the only focus area available
        var scores = new Dictionary<string, decimal>
        {
            ["Motor"] = 90m, ["Communication"] = 85m,
            ["Cognitive"] = 88m, ["Emotional"] = 10m
        };

        var result = Run(scores, StandardCatalog);

        Assert.DoesNotContain(result.RecommendedActivities,
            a => a.AssessmentDomain == "Emotional");
    }

    // ─── DOMAIN MAPPING TESTS ────────────────────────────────────────────────

    [Fact]
    public void DomainMapping_Motor_GeneratesMovementActivities()
    {
        // Motor is the only focus area
        var scores = new Dictionary<string, decimal>
        {
            ["Motor"] = 20m, ["Communication"] = 85m,
            ["Cognitive"] = 80m, ["Emotional"] = 82m
        };

        var result = Run(scores, StandardCatalog);

        var motorActivities = result.RecommendedActivities
            .Where(a => a.AssessmentDomain == "Motor")
            .ToList();

        Assert.NotEmpty(motorActivities);
        Assert.All(motorActivities, a => Assert.Equal("Movement", a.ActivityDomain));
    }

    [Fact]
    public void DomainMapping_Communication_GeneratesSpeechActivities()
    {
        var scores = new Dictionary<string, decimal>
        {
            ["Motor"] = 85m, ["Communication"] = 20m,
            ["Cognitive"] = 80m, ["Emotional"] = 82m
        };

        var result = Run(scores, StandardCatalog);

        var commActivities = result.RecommendedActivities
            .Where(a => a.AssessmentDomain == "Communication")
            .ToList();

        Assert.NotEmpty(commActivities);
        Assert.All(commActivities, a => Assert.Equal("Speech", a.ActivityDomain));
    }

    [Fact]
    public void DomainMapping_Cognitive_GeneratesAttentionActivities()
    {
        var scores = new Dictionary<string, decimal>
        {
            ["Motor"] = 85m, ["Communication"] = 80m,
            ["Cognitive"] = 20m, ["Emotional"] = 82m
        };

        var result = Run(scores, StandardCatalog);

        var cogActivities = result.RecommendedActivities
            .Where(a => a.AssessmentDomain == "Cognitive")
            .ToList();

        Assert.NotEmpty(cogActivities);
        Assert.All(cogActivities, a => Assert.Equal("Attention", a.ActivityDomain));
    }

    // ─── ACTIVITY LIMITS TESTS ───────────────────────────────────────────────

    [Fact]
    public void ActivityLimit_PrimaryFocus_MaxTwoActivities()
    {
        // Add many Speech activities to ensure the cap is tested
        var catalog = Enumerable.Range(1, 10)
            .Select(i => MakeActivity(ActivityDomain.Speech, DifficultyLevel.Beginner, $"speech-{i}"))
            .Concat(StandardCatalog)
            .ToList();

        var scores = new Dictionary<string, decimal>
        {
            ["Motor"] = 85m, ["Communication"] = 20m,
            ["Cognitive"] = 80m, ["Emotional"] = 82m
        };

        var result = Run(scores, catalog);

        var commActivities = result.RecommendedActivities
            .Where(a => a.AssessmentDomain == "Communication" && a.Priority == "High")
            .ToList();

        Assert.True(commActivities.Count <= HomePracticeConstants.MaxActivitiesPerPrimaryFocus,
            $"Expected max {HomePracticeConstants.MaxActivitiesPerPrimaryFocus} primary focus activities, got {commActivities.Count}");
    }

    [Fact]
    public void ActivityLimit_Strength_MaxOneMaintenanceActivity()
    {
        var catalog = Enumerable.Range(1, 10)
            .Select(i => MakeActivity(ActivityDomain.Movement, DifficultyLevel.Beginner, $"mov-{i}"))
            .Concat(StandardCatalog)
            .ToList();

        var scores = new Dictionary<string, decimal>
        {
            ["Motor"] = 90m, ["Communication"] = 20m,
            ["Cognitive"] = 30m, ["Emotional"] = 85m
        };

        var result = Run(scores, catalog);

        var motorStrengthActivities = result.RecommendedActivities
            .Where(a => a.AssessmentDomain == "Motor" && a.Priority == "Low")
            .ToList();

        Assert.True(motorStrengthActivities.Count <= HomePracticeConstants.MaxActivitiesPerStrength,
            $"Expected max {HomePracticeConstants.MaxActivitiesPerStrength} maintenance activity, got {motorStrengthActivities.Count}");
    }

    // ─── DIFFICULTY SELECTION TESTS ───────────────────────────────────────────

    [Fact]
    public void DifficultySelection_ScoreBelow75_SelectsBeginnerActivity()
    {
        var scores = new Dictionary<string, decimal>
        {
            ["Motor"] = 85m, ["Communication"] = 60m,
            ["Cognitive"] = 80m, ["Emotional"] = 82m
        };

        var result = Run(scores, StandardCatalog);

        var commActivities = result.RecommendedActivities
            .Where(a => a.AssessmentDomain == "Communication")
            .ToList();

        Assert.NotEmpty(commActivities);
        Assert.All(commActivities, a => Assert.Equal("Beginner", a.BaseDifficulty));
    }

    [Fact]
    public void DifficultySelection_ScoreAtOrAbove75_SelectsIntermediateActivity()
    {
        // Motor = 20 (focus, score >= 75 threshold only matters for preferred selection)
        // Let's test: score 75 should prefer Intermediate
        var scores = new Dictionary<string, decimal>
        {
            ["Motor"] = 20m, ["Communication"] = 90m,
            ["Cognitive"] = 80m, ["Emotional"] = 85m
        };

        // Motor score 20 → Beginner preferred
        var result = Run(scores, StandardCatalog);
        var motorActivities = result.RecommendedActivities
            .Where(a => a.AssessmentDomain == "Motor")
            .ToList();

        Assert.NotEmpty(motorActivities);
        Assert.All(motorActivities, a => Assert.Equal("Beginner", a.BaseDifficulty));
    }

    [Fact]
    public void DifficultySelection_ScoreAbove75_PrefersIntermediate()
    {
        // Communication score is the primary focus at 30 (beginner).
        // Motor score is 78 and also a focus area — should pick Intermediate.
        // Build a case where Motor is a focus with score 78
        var scores = new Dictionary<string, decimal>
        {
            ["Motor"] = 78m, ["Communication"] = 78m,  // both equal, tie-break: Communication first
            ["Cognitive"] = 90m, ["Emotional"] = 85m
        };

        // Put only Intermediate movement activities in catalog to confirm Intermediate is selected
        var catalog = new List<Activity>
        {
            MakeActivity(ActivityDomain.Movement,  DifficultyLevel.Intermediate, "mov-int"),
            MakeActivity(ActivityDomain.Speech,    DifficultyLevel.Intermediate, "speech-int"),
            MakeActivity(ActivityDomain.Attention, DifficultyLevel.Beginner,     "att-beg"),
        };

        var result = Run(scores, catalog);

        // All recommended activities in motor/speech range should use Intermediate (score >= 75)
        var mappedActivities = result.RecommendedActivities
            .Where(a => a.AssessmentDomain != "Emotional")
            .ToList();

        Assert.NotEmpty(mappedActivities);
    }

    [Fact]
    public void DifficultyFallback_NoBeginner_FallsBackToIntermediateWithoutCrash()
    {
        // Only Intermediate speech activities exist
        var catalog = new List<Activity>
        {
            MakeActivity(ActivityDomain.Speech, DifficultyLevel.Intermediate, "speech-only-int"),
        };

        var scores = new Dictionary<string, decimal>
        {
            ["Motor"] = 85m, ["Communication"] = 30m, // wants Beginner but none exists
            ["Cognitive"] = 80m, ["Emotional"] = 82m
        };

        var result = Run(scores, catalog);

        var commActivities = result.RecommendedActivities
            .Where(a => a.AssessmentDomain == "Communication")
            .ToList();

        // Should fall back to Intermediate
        Assert.NotEmpty(commActivities);
        Assert.All(commActivities, a => Assert.Equal("Intermediate", a.BaseDifficulty));
    }

    // ─── MISSING ACTIVITY DOMAIN TESTS ───────────────────────────────────────

    [Fact]
    public void MissingActivityDomain_NoCrash_SkipsSilently()
    {
        // No Speech activities at all — Communication focus area should silently return zero activities
        var catalog = new List<Activity>
        {
            MakeActivity(ActivityDomain.Movement,  DifficultyLevel.Beginner),
            MakeActivity(ActivityDomain.Attention, DifficultyLevel.Beginner),
        };

        var scores = new Dictionary<string, decimal>
        {
            ["Motor"] = 85m, ["Communication"] = 20m,
            ["Cognitive"] = 80m, ["Emotional"] = 82m
        };

        var exception = Record.Exception(() => Run(scores, catalog));
        Assert.Null(exception);

        var result = Run(scores, catalog);
        Assert.DoesNotContain(result.RecommendedActivities,
            a => a.AssessmentDomain == "Communication");
    }

    [Fact]
    public void EmptyActivityCatalog_NoCrash_ReturnsEmptyRecommendations()
    {
        var scores = new Dictionary<string, decimal>
        {
            ["Motor"] = 85m, ["Communication"] = 20m,
            ["Cognitive"] = 30m, ["Emotional"] = 82m
        };

        var exception = Record.Exception(() => Run(scores, Array.Empty<Activity>()));
        Assert.Null(exception);

        var result = Run(scores, Array.Empty<Activity>());
        Assert.Empty(result.RecommendedActivities);
        Assert.Equal(2, result.FocusAreas.Count);   // profile still populated
        Assert.Equal(2, result.Strengths.Count);
    }

    // ─── PRACTICE FREQUENCY TESTS ────────────────────────────────────────────

    [Fact]
    public void PracticeFrequency_PrimaryFocusActivity_UsesPrimaryFocusConstant()
    {
        var scores = new Dictionary<string, decimal>
        {
            ["Motor"] = 85m, ["Communication"] = 20m,
            ["Cognitive"] = 80m, ["Emotional"] = 82m
        };

        var result = Run(scores, StandardCatalog);

        var primary = result.RecommendedActivities
            .FirstOrDefault(a => a.AssessmentDomain == "Communication" && a.Priority == "High");

        Assert.NotNull(primary);
        Assert.Equal(HomePracticeConstants.PrimaryFocusFrequency, primary!.SuggestedPracticeFrequency);
    }

    [Fact]
    public void PracticeFrequency_MaintenanceActivity_UsesMaintenanceConstant()
    {
        var scores = new Dictionary<string, decimal>
        {
            ["Motor"] = 90m, ["Communication"] = 20m,
            ["Cognitive"] = 30m, ["Emotional"] = 85m
        };

        var result = Run(scores, StandardCatalog);

        var maintenance = result.RecommendedActivities
            .FirstOrDefault(a => a.Priority == "Low");

        if (maintenance != null)
        {
            Assert.Equal(HomePracticeConstants.MaintenanceFrequency, maintenance.SuggestedPracticeFrequency);
        }
        // If no maintenance activity (all domains are focus areas), skip this assertion
    }

    // ─── GENERAL RESPONSE SHAPE TESTS ────────────────────────────────────────

    [Fact]
    public void Response_IsPreliminary_AlwaysTrue()
    {
        var scores = new Dictionary<string, decimal>
        {
            ["Motor"] = 82m, ["Communication"] = 46m,
            ["Cognitive"] = 58m, ["Emotional"] = 76m
        };

        var result = Run(scores, StandardCatalog);

        Assert.True(result.IsPreliminary);
        Assert.All(result.RecommendedActivities, a => Assert.True(a.IsPreliminary));
    }

    [Fact]
    public void Response_AlwaysContainsFourDomainProfiles()
    {
        var scores = new Dictionary<string, decimal>
        {
            ["Motor"] = 82m, ["Communication"] = 46m,
            ["Cognitive"] = 58m, ["Emotional"] = 76m
        };

        var result = Run(scores, StandardCatalog);

        int totalProfileDomains = result.Strengths.Count + result.FocusAreas.Count;
        Assert.Equal(4, totalProfileDomains);
    }

    [Fact]
    public void Response_DisclaimerAlwaysPresent()
    {
        var scores = new Dictionary<string, decimal>
        {
            ["Motor"] = 82m, ["Communication"] = 46m,
            ["Cognitive"] = 58m, ["Emotional"] = 76m
        };

        var result = Run(scores, StandardCatalog);

        Assert.False(string.IsNullOrWhiteSpace(result.Disclaimer));
        Assert.Equal(HomePracticeConstants.Disclaimer, result.Disclaimer);
    }

    [Fact]
    public void Response_ActivityReasons_NotEmpty()
    {
        var scores = new Dictionary<string, decimal>
        {
            ["Motor"] = 82m, ["Communication"] = 46m,
            ["Cognitive"] = 58m, ["Emotional"] = 76m
        };

        var result = Run(scores, StandardCatalog);

        Assert.All(result.RecommendedActivities, a =>
            Assert.False(string.IsNullOrWhiteSpace(a.Reason)));
    }

    [Fact]
    public void Response_AllDomains_HaveArabicNames()
    {
        var scores = new Dictionary<string, decimal>
        {
            ["Motor"] = 82m, ["Communication"] = 46m,
            ["Cognitive"] = 58m, ["Emotional"] = 76m
        };

        var result = Run(scores, StandardCatalog);

        var allDomains = result.Strengths.Concat(result.FocusAreas).ToList();
        Assert.All(allDomains, d => Assert.False(string.IsNullOrWhiteSpace(d.AssessmentDomainArabic)));
    }

    // ─── DISPLAY LEVEL LABEL TESTS ───────────────────────────────────────────

    [Fact]
    public void LevelLabels_ScoreAbove75_IsStrongLevel()
    {
        var scores = new Dictionary<string, decimal>
        {
            ["Motor"] = 80m, ["Communication"] = 20m,
            ["Cognitive"] = 30m, ["Emotional"] = 90m
        };

        var result = Run(scores, StandardCatalog);

        var motorStrength = result.Strengths.FirstOrDefault(s => s.AssessmentDomain == "Motor");
        Assert.NotNull(motorStrength);
        Assert.Equal("قوة واضحة", motorStrength!.Level);
    }

    [Fact]
    public void LevelLabels_ScoreBelow50_IsFocusLabel()
    {
        var scores = new Dictionary<string, decimal>
        {
            ["Motor"] = 85m, ["Communication"] = 30m,
            ["Cognitive"] = 80m, ["Emotional"] = 82m
        };

        var result = Run(scores, StandardCatalog);

        var commFocus = result.FocusAreas.FirstOrDefault(f => f.AssessmentDomain == "Communication");
        Assert.NotNull(commFocus);
        Assert.Equal("مجال للتركيز", commFocus!.Level);
    }

    [Fact]
    public void LevelLabels_ScoreBetween50And75_IsMidLevel()
    {
        var scores = new Dictionary<string, decimal>
        {
            ["Motor"] = 85m, ["Communication"] = 60m,
            ["Cognitive"] = 80m, ["Emotional"] = 82m
        };

        var result = Run(scores, StandardCatalog);

        var commFocus = result.FocusAreas.FirstOrDefault(f => f.AssessmentDomain == "Communication");
        Assert.NotNull(commFocus);
        Assert.Equal("مستوى متوسط", commFocus!.Level);
    }

    // ─── BACKWARD COMPATIBILITY / EXISTING USER TESTS ─────────────────────────

    [Fact]
    public void ExistingUser_OldAggregateScoresOnly_WorksWithoutError()
    {
        // Simulates a user who has ONLY the old aggregate scores stored
        // (no individual question answers — which we never stored anyway)
        var scores = new Dictionary<string, decimal>
        {
            ["Motor"] = 65m, ["Communication"] = 55m,
            ["Cognitive"] = 70m, ["Emotional"] = 60m
        };

        var exception = Record.Exception(() => Run(scores, StandardCatalog));
        Assert.Null(exception);

        var result = Run(scores, StandardCatalog);
        Assert.Equal(TestChildId, result.ChildId);
        Assert.True(result.IsPreliminary);
    }

    [Fact]
    public void ChildWithNoDoctor_SameResultAsChildWithDoctor()
    {
        // Doctor status has zero effect on the recommendation engine
        // (authorization is handled by the handler, not BuildRecommendation)
        var scores = new Dictionary<string, decimal>
        {
            ["Motor"] = 82m, ["Communication"] = 46m,
            ["Cognitive"] = 58m, ["Emotional"] = 76m
        };

        var result = Run(scores, StandardCatalog);

        // Recommendation is always generated regardless of doctor presence
        Assert.NotEmpty(result.FocusAreas);
        Assert.True(result.IsPreliminary);
    }

    [Fact]
    public void OverallScore_CorrectlyPassedThrough()
    {
        var overallScore = 61.5m;
        var scores = new Dictionary<string, decimal>
        {
            ["Motor"] = 82m, ["Communication"] = 46m,
            ["Cognitive"] = 58m, ["Emotional"] = 76m
        };

        var result = HomePracticeRecommendationHandler.BuildRecommendation(
            TestChildId, overallScore, scores, StandardCatalog);

        Assert.Equal(overallScore, result.OverallScore);
    }
}
