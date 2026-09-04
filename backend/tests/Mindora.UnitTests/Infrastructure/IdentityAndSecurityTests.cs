using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;
using Mindora.Infrastructure.Identity;
using Mindora.Infrastructure.Persistence;
using Mindora.Infrastructure.Persistence.Seeding;
using Xunit;

namespace Mindora.UnitTests.Infrastructure;

public class IdentityAndSecurityTests
{
    private static ApplicationDbContext CreateInMemoryDbContext()
    {
        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;

        return new ApplicationDbContext(options);
    }

    [Fact]
    public void Identity_PasswordHasher_Does_Not_Store_Plaintext()
    {
        // Arrange
        var hasher = new PasswordHasher<ApplicationUser>();
        var user = new ApplicationUser { UserName = "test@mindora.com" };
        var plaintext = "SuperSecretPassword123!";

        // Act
        var hashedPassword = hasher.HashPassword(user, plaintext);

        // Assert
        Assert.NotEqual(plaintext, hashedPassword);
        Assert.DoesNotContain("SuperSecret", hashedPassword);

        var verificationResult = hasher.VerifyHashedPassword(user, hashedPassword, plaintext);
        Assert.Equal(PasswordVerificationResult.Success, verificationResult);
    }

    [Fact]
    public async Task Seeder_Does_Not_Run_Outside_Development_Environment()
    {
        // Arrange
        using var context = CreateInMemoryDbContext();
        var userStore = new UserStore<ApplicationUser, IdentityRole<Guid>, ApplicationDbContext, Guid>(context);
        var userManager = new UserManager<ApplicationUser>(
            userStore, null!, new PasswordHasher<ApplicationUser>(), null!, null!, null!, null!, null!, null!);
        var roleStore = new RoleStore<IdentityRole<Guid>, ApplicationDbContext, Guid>(context);
        var roleManager = new RoleManager<IdentityRole<Guid>>(roleStore, null!, null!, null!, null!);

        var stubProductionEnv = new StubWebHostEnvironment { EnvironmentName = "Production" };
        var inMemoryConfig = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?> { { "Database:SeedDemoData", "true" } })
            .Build();

        var seeder = new DatabaseSeeder(
            context,
            userManager,
            roleManager,
            stubProductionEnv,
            inMemoryConfig,
            NullLogger<DatabaseSeeder>.Instance);

        // Act
        await seeder.SeedAsync();

        // Assert: In Production, nothing should be seeded even if config has SeedDemoData = true
        Assert.Empty(context.Users);
        Assert.Empty(context.Children);
        Assert.Empty(context.Activities);
    }

    [Fact]
    public async Task Seeder_Does_Not_Run_When_SeedDemoData_Config_Is_False()
    {
        // Arrange
        using var context = CreateInMemoryDbContext();
        var userStore = new UserStore<ApplicationUser, IdentityRole<Guid>, ApplicationDbContext, Guid>(context);
        var userManager = new UserManager<ApplicationUser>(
            userStore, null!, new PasswordHasher<ApplicationUser>(), null!, null!, null!, null!, null!, null!);
        var roleStore = new RoleStore<IdentityRole<Guid>, ApplicationDbContext, Guid>(context);
        var roleManager = new RoleManager<IdentityRole<Guid>>(roleStore, null!, null!, null!, null!);

        var stubDevEnv = new StubWebHostEnvironment { EnvironmentName = "Development" };
        var inMemoryConfig = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?> { { "Database:SeedDemoData", "false" } })
            .Build();

        var seeder = new DatabaseSeeder(
            context,
            userManager,
            roleManager,
            stubDevEnv,
            inMemoryConfig,
            NullLogger<DatabaseSeeder>.Instance);

        // Act
        await seeder.SeedAsync();

        // Assert: Disabled by config
        Assert.Empty(context.Users);
        Assert.Empty(context.Children);
    }

    private sealed class StubWebHostEnvironment : IWebHostEnvironment
    {
        public string EnvironmentName { get; set; } = "Development";
        public string ApplicationName { get; set; } = "Mindora.Api";
        public string WebRootPath { get; set; } = string.Empty;
        public Microsoft.Extensions.FileProviders.IFileProvider WebRootFileProvider { get; set; } = null!;
        public string ContentRootPath { get; set; } = string.Empty;
        public Microsoft.Extensions.FileProviders.IFileProvider ContentRootFileProvider { get; set; } = null!;
    }
}
