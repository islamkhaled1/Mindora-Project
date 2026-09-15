using Microsoft.EntityFrameworkCore;
using Mindora.Api.Middleware;
using Mindora.Application;
using Mindora.Infrastructure;
using Mindora.Infrastructure.Persistence;
using Mindora.Infrastructure.Persistence.Seeding;

var builder = WebApplication.CreateBuilder(args);

// Register Application layer services (validators, etc.)
builder.Services.AddApplicationServices();

// Register Infrastructure services (EF Core, Identity, JWT, CurrentUser, Seeder)
builder.Services.AddInfrastructureServices(builder.Configuration);

// Configure RFC 7807 ProblemDetails and centralized exception handling
builder.Services.AddProblemDetails();
builder.Services.AddExceptionHandler<GlobalExceptionHandler>();

builder.Services.AddAuthorization();
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});
builder.Services.AddControllers();

var app = builder.Build();

app.UseCors();

app.UseExceptionHandler();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

// Apply pending EF Core database migrations on startup
try
{
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<Mindora.Infrastructure.Persistence.ApplicationDbContext>();
    if (db.Database.IsRelational())
    {
        await db.Database.MigrateAsync();
    }
}
catch (Exception ex)
{
    var logger = app.Services.GetRequiredService<ILogger<Program>>();
    logger.LogWarning(ex, "Automatic migration skipped or encountered error on startup.");
}

// Seed demo data if in Development and configured (safely caught in case DB is not yet created)
if (app.Environment.IsDevelopment())
{
    try
    {
        using var scope = app.Services.CreateScope();
        var seeder = scope.ServiceProvider.GetRequiredService<DatabaseSeeder>();
        await seeder.SeedAsync();
    }
    catch (Exception ex)
    {
        var logger = app.Services.GetRequiredService<ILogger<Program>>();
        logger.LogWarning(ex, "Seeding skipped or encountered error on startup.");
    }
}

// Minimal probe/health endpoint for operational readiness check
app.MapGet("/health", () => Results.Ok(new { status = "Healthy", timestamp = DateTime.UtcNow }));

app.Run();

// Make Program accessible for integration testing
public partial class Program { }
