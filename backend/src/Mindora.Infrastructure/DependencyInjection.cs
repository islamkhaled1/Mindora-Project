using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.IdentityModel.Tokens;
using Mindora.Application.Common.Interfaces;
using Mindora.Infrastructure.Ai;
using Mindora.Infrastructure.Identity;
using Mindora.Infrastructure.Persistence;
using Mindora.Infrastructure.Persistence.Seeding;
using Mindora.Infrastructure.Services;

namespace Mindora.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructureServices(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        // Database Connection & Persistence
        var connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? "Server=(localdb)\\MSSQLLocalDB;Database=MindoraDb;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True";

        services.AddDbContext<ApplicationDbContext>(options =>
            options.UseSqlServer(connectionString));

        // Forward IApplicationDbContext to concrete ApplicationDbContext
        services.AddScoped<IApplicationDbContext>(provider =>
            provider.GetRequiredService<ApplicationDbContext>());

        // ASP.NET Core Identity Configuration
        services.AddIdentity<ApplicationUser, IdentityRole<Guid>>(options =>
        {
            options.Password.RequireDigit = true;
            options.Password.RequiredLength = 8;
            options.Password.RequireNonAlphanumeric = false;
            options.Password.RequireUppercase = false;
            options.Password.RequireLowercase = false;
            options.User.RequireUniqueEmail = true;
        })
        .AddEntityFrameworkStores<ApplicationDbContext>()
        .AddDefaultTokenProviders();

        // JWT Configuration & Options
        var jwtSection = configuration.GetSection(JwtOptions.SectionName);
        services.Configure<JwtOptions>(jwtSection);
        var jwtOptions = jwtSection.Get<JwtOptions>() ?? new JwtOptions();

        if (string.IsNullOrWhiteSpace(jwtOptions.SecretKey))
        {
            // Default development fallback key (never used in production)
            jwtOptions.SecretKey = "MindoraDevelopmentSecretKeyForJudgingEvaluationDemo2026!";
            services.Configure<JwtOptions>(opt => opt.SecretKey = jwtOptions.SecretKey);
        }

        // JWT Bearer Authentication
        services.AddAuthentication(options =>
        {
            options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
            options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
        })
        .AddJwtBearer(options =>
        {
            options.RequireHttpsMetadata = false;
            options.SaveToken = true;
            options.TokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidIssuer = jwtOptions.Issuer,
                ValidateAudience = true,
                ValidAudience = jwtOptions.Audience,
                ValidateLifetime = true,
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtOptions.SecretKey)),
                ClockSkew = TimeSpan.Zero
            };
        });

        // Identity and Token Services
        services.AddScoped<IIdentityService, IdentityService>();
        services.AddScoped<IJwtTokenService, JwtTokenService>();

        // Google Authentication Token Validator
        var googleAuthSection = configuration.GetSection(GoogleAuthOptions.SectionName);
        services.Configure<GoogleAuthOptions>(googleAuthSection);
        services.AddScoped<IGoogleTokenValidator, GoogleTokenValidator>();

        // Current User Context (Uses IHttpContextAccessor)
        services.AddHttpContextAccessor();
        services.AddScoped<ICurrentUserService, CurrentUserService>();

        // Database Seeder
        services.AddScoped<DatabaseSeeder>();

        // AI Configuration and Resilient Service Composition
        var aiSection = configuration.GetSection(AiOptions.SectionName);
        services.Configure<AiOptions>(aiSection);

        services.AddSingleton<MockAiAnalysisService>();
        services.AddHttpClient<ExternalAiProviderClient>();
        services.AddScoped<IAiAnalysisService, ResilientAiAnalysisService>();

        // AI Chatbot Configuration and Typed HTTP Client (Google Gemini API)
        var chatSection = configuration.GetSection(ChatOptions.SectionName);
        services.Configure<ChatOptions>(chatSection);
        services.AddHttpClient<IChatAiClient, GeminiChatClient>();

        // Abuse Throttling Services
        services.AddSingleton<ILinkingRateLimiter, LinkingRateLimiter>();

        // Email Service Configuration and Brevo SMTP Implementation
        var emailSection = configuration.GetSection(EmailOptions.SectionName);
        services.Configure<EmailOptions>(emailSection);
        services.AddScoped<IEmailService, BrevoEmailService>();

        return services;
    }
}
