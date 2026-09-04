using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;
using Mindora.Infrastructure.Identity;

namespace Mindora.Infrastructure.Persistence.Seeding;

/// <summary>
/// Idempotent database seeder for development and live demonstration.
/// Strictly environment-gated: only executes in Development when Database:SeedDemoData is true.
/// </summary>
public class DatabaseSeeder
{
    public const string DemoParentEmail = "parent@mindora.com";
    public const string DemoParentPassword = "Parent123!";
    public const string DemoDoctorEmail = "doctor@mindora.com";
    public const string DemoDoctorPassword = "Doctor123!";

    private readonly ApplicationDbContext _context;
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly RoleManager<IdentityRole<Guid>> _roleManager;
    private readonly IWebHostEnvironment _environment;
    private readonly IConfiguration _configuration;
    private readonly ILogger<DatabaseSeeder> _logger;

    public DatabaseSeeder(
        ApplicationDbContext context,
        UserManager<ApplicationUser> userManager,
        RoleManager<IdentityRole<Guid>> roleManager,
        IWebHostEnvironment environment,
        IConfiguration configuration,
        ILogger<DatabaseSeeder> logger)
    {
        _context = context;
        _userManager = userManager;
        _roleManager = roleManager;
        _environment = environment;
        _configuration = configuration;
        _logger = logger;
    }

    public async Task SeedAsync(CancellationToken cancellationToken = default)
    {
        // Strict environment gate: NEVER execute outside Development
        if (!_environment.IsDevelopment())
        {
            return;
        }

        // Configuration gate: check if demo seeding is explicitly enabled
        var seedEnabled = _configuration.GetValue<bool>("Database:SeedDemoData", false);
        if (!seedEnabled)
        {
            return;
        }

        _logger.LogInformation("Starting idempotent demo data seeding...");

        await SeedRolesAsync();
        var (parentUser, parentProfile) = await SeedParentAsync();
        var (doctorUser, doctorProfile) = await SeedDoctorAsync();
        var child = await SeedChildAsync(parentProfile.Id);
        await SeedDoctorAssignmentAsync(doctorProfile.Id, child.Id);
        var activities = await SeedActivitiesAsync();
        await SeedHistoricalSessionsAsync(child.Id, activities);

        _logger.LogInformation("Demo data seeding completed successfully.");
    }

    private async Task SeedRolesAsync()
    {
        var roles = new[] { UserRole.Parent.ToString(), UserRole.Doctor.ToString() };
        foreach (var role in roles)
        {
            if (!await _roleManager.RoleExistsAsync(role))
            {
                await _roleManager.CreateAsync(new IdentityRole<Guid>(role));
            }
        }
    }

    private async Task<(ApplicationUser User, ParentProfile Profile)> SeedParentAsync()
    {
        var user = await _userManager.FindByEmailAsync(DemoParentEmail);
        if (user == null)
        {
            user = new ApplicationUser
            {
                Id = Guid.NewGuid(),
                UserName = DemoParentEmail,
                Email = DemoParentEmail,
                EmailConfirmed = true,
                FullName = "Sarah Miller",
                CreatedAtUtc = DateTime.UtcNow
            };

            var createResult = await _userManager.CreateAsync(user, DemoParentPassword);
            if (!createResult.Succeeded)
            {
                var errors = string.Join(", ", createResult.Errors.Select(e => e.Description));
                throw new InvalidOperationException($"Failed to create demo parent user: {errors}");
            }

            await _userManager.AddToRoleAsync(user, UserRole.Parent.ToString());
        }

        var profile = await _context.ParentProfiles.FirstOrDefaultAsync(p => p.UserId == user.Id);
        if (profile == null)
        {
            profile = ParentProfile.Create(user.Id, "+1 (555) 234-5678");
            _context.ParentProfiles.Add(profile);
            await _context.SaveChangesAsync();
        }

        return (user, profile);
    }

    private async Task<(ApplicationUser User, DoctorProfile Profile)> SeedDoctorAsync()
    {
        var user = await _userManager.FindByEmailAsync(DemoDoctorEmail);
        if (user == null)
        {
            user = new ApplicationUser
            {
                Id = Guid.NewGuid(),
                UserName = DemoDoctorEmail,
                Email = DemoDoctorEmail,
                EmailConfirmed = true,
                FullName = "Dr. Elena Rostova",
                CreatedAtUtc = DateTime.UtcNow
            };

            var createResult = await _userManager.CreateAsync(user, DemoDoctorPassword);
            if (!createResult.Succeeded)
            {
                var errors = string.Join(", ", createResult.Errors.Select(e => e.Description));
                throw new InvalidOperationException($"Failed to create demo doctor user: {errors}");
            }

            await _userManager.AddToRoleAsync(user, UserRole.Doctor.ToString());
        }

        var profile = await _context.DoctorProfiles.FirstOrDefaultAsync(d => d.UserId == user.Id);
        if (profile == null)
        {
            profile = DoctorProfile.Create(
                user.Id,
                specialization: "Pediatric Occupational & Speech Therapist",
                clinicName: "Mindora Developmental Clinic",
                licenseNumber: "LIC-OT-88941");

            _context.DoctorProfiles.Add(profile);
            await _context.SaveChangesAsync();
        }

        return (user, profile);
    }

    private async Task<Child> SeedChildAsync(Guid parentId)
    {
        var child = await _context.Children.FirstOrDefaultAsync(c => c.ParentId == parentId && c.FullName == "Leo Miller");
        if (child == null)
        {
            var birthDate = DateOnly.FromDateTime(DateTime.UtcNow.AddYears(-6));
            child = Child.Create(
                parentId,
                fullName: "Leo Miller",
                dateOfBirth: birthDate,
                supportNotes: "Energetic and motivated by musical and visual cues. Responds well to gentle repetition pacing.",
                currentMovementLevel: DifficultyLevel.Beginner,
                currentSpeechLevel: DifficultyLevel.Beginner,
                currentAttentionLevel: DifficultyLevel.Intermediate);

            _context.Children.Add(child);
            await _context.SaveChangesAsync();
        }

        return child;
    }

    private async Task SeedDoctorAssignmentAsync(Guid doctorId, Guid childId)
    {
        var assignmentExists = await _context.DoctorChildAssignments
            .AnyAsync(a => a.DoctorId == doctorId && a.ChildId == childId && a.IsActive);

        if (!assignmentExists)
        {
            var assignment = DoctorChildAssignment.Create(doctorId, childId);
            _context.DoctorChildAssignments.Add(assignment);
            await _context.SaveChangesAsync();
        }
    }

    private async Task<List<Activity>> SeedActivitiesAsync()
    {
        var existing = await _context.Activities.ToListAsync();
        if (existing.Count >= 3)
        {
            return existing;
        }

        var activities = new List<Activity>
        {
            Activity.Create(
                title: "Gentle Reach & Tap",
                description: "Interactive visual targets appear to guide bilateral arm reaching and coordination.",
                domain: ActivityDomain.Movement,
                baseDifficulty: DifficultyLevel.Beginner,
                adaptiveSettingsJson: "{\"targetCount\": 10, \"cueSpeedMs\": 1200, \"targetSizePx\": 80}"),

            Activity.Create(
                title: "Vowel Safari Sounds",
                description: "Playful phoneme repetition game encouraging vowel articulation and vocal response timing.",
                domain: ActivityDomain.Speech,
                baseDifficulty: DifficultyLevel.Beginner,
                adaptiveSettingsJson: "{\"phonemeSet\": [\"ah\", \"oo\", \"ee\"], \"repeatTarget\": 3, \"latencyThresholdMs\": 2500}"),

            Activity.Create(
                title: "Gaze & Star Focus",
                description: "Visual attention exercise tracking sustained focus duration on gentle animated celestial stars.",
                domain: ActivityDomain.Attention,
                baseDifficulty: DifficultyLevel.Intermediate,
                adaptiveSettingsJson: "{\"sustainTargetSeconds\": 30, \"distractorFrequency\": \"Low\", \"contrastLevel\": \"High\"}")
        };

        foreach (var act in activities)
        {
            if (!existing.Any(e => e.Title == act.Title))
            {
                _context.Activities.Add(act);
            }
        }

        await _context.SaveChangesAsync();
        return await _context.Activities.ToListAsync();
    }

    private async Task SeedHistoricalSessionsAsync(Guid childId, List<Activity> activities)
    {
        var sessionCount = await _context.Sessions.CountAsync(s => s.ChildId == childId);
        if (sessionCount >= 3)
        {
            return;
        }

        var movementActivity = activities.First(a => a.Domain == ActivityDomain.Movement);
        var speechActivity = activities.First(a => a.Domain == ActivityDomain.Speech);
        var attentionActivity = activities.First(a => a.Domain == ActivityDomain.Attention);

        // Session 1: Movement (completed 3 days ago)
        var s1Start = DateTime.UtcNow.AddDays(-3);
        var s1 = Session.Start(childId, movementActivity.Id, ActivityDomain.Movement, s1Start);
        s1.AddMetric("RepetitionCount", 12.00m, s1Start.AddMinutes(2));
        s1.AddMetric("AccuracyPercentage", 91.50m, s1Start.AddMinutes(4));
        s1.Complete(s1Start.AddMinutes(5), actualDurationSeconds: 300);
        var r1 = SessionAnalysisResult.Create(
            s1.Id,
            overallPerformanceScore: 88.00m,
            domainScore: 91.50m,
            supportiveObservations: "Child maintained stable bilateral coordination with consistent reach pacing.",
            fatigueObserved: false,
            recommendedDifficultyAdjustment: DifficultyAdjustment.Maintain,
            analyzedAtUtc: s1Start.AddMinutes(5));
        s1.AttachAnalysisResult(r1);
        _context.Sessions.Add(s1);

        // Session 2: Speech (completed 2 days ago)
        var s2Start = DateTime.UtcNow.AddDays(-2);
        var s2 = Session.Start(childId, speechActivity.Id, ActivityDomain.Speech, s2Start);
        s2.AddMetric("SpeechClarityScore", 82.00m, s2Start.AddMinutes(3));
        s2.AddMetric("ReactionTimeMs", 1850.00m, s2Start.AddMinutes(4));
        s2.Complete(s2Start.AddMinutes(6), actualDurationSeconds: 360);
        var r2 = SessionAnalysisResult.Create(
            s2.Id,
            overallPerformanceScore: 84.00m,
            domainScore: 82.00m,
            supportiveObservations: "Strong vowel repetition; latency slightly elevated toward end indicating slight fatigue.",
            fatigueObserved: true,
            recommendedDifficultyAdjustment: DifficultyAdjustment.Maintain,
            analyzedAtUtc: s2Start.AddMinutes(6));
        s2.AttachAnalysisResult(r2);
        _context.Sessions.Add(s2);

        // Session 3: Attention (completed yesterday)
        var s3Start = DateTime.UtcNow.AddDays(-1);
        var s3 = Session.Start(childId, attentionActivity.Id, ActivityDomain.Attention, s3Start);
        s3.AddMetric("AttentionDurationSeconds", 45.00m, s3Start.AddMinutes(3));
        s3.AddMetric("AccuracyPercentage", 95.00m, s3Start.AddMinutes(5));
        s3.Complete(s3Start.AddMinutes(5), actualDurationSeconds: 300);
        var r3 = SessionAnalysisResult.Create(
            s3.Id,
            overallPerformanceScore: 94.00m,
            domainScore: 95.00m,
            supportiveObservations: "Exceptional visual tracking persistence; child exceeded baseline sustained attention duration.",
            fatigueObserved: false,
            recommendedDifficultyAdjustment: DifficultyAdjustment.Increase,
            analyzedAtUtc: s3Start.AddMinutes(5));
        s3.AttachAnalysisResult(r3);
        _context.Sessions.Add(s3);

        await _context.SaveChangesAsync();
    }
}
