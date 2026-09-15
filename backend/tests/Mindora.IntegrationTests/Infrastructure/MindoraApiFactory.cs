using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Mindora.Application.Common.Interfaces;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;
using Mindora.Infrastructure.Persistence;

namespace Mindora.IntegrationTests.Infrastructure;

public class MindoraApiFactory : WebApplicationFactory<Program>
{
    private readonly string _dbName = Guid.NewGuid().ToString();

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.ConfigureServices(services =>
        {
            var dbContextDescriptor = services.SingleOrDefault(d => d.ServiceType == typeof(DbContextOptions<ApplicationDbContext>));
            if (dbContextDescriptor != null)
            {
                services.Remove(dbContextDescriptor);
            }

            var inMemoryProvider = new ServiceCollection()
                .AddEntityFrameworkInMemoryDatabase()
                .BuildServiceProvider();

            services.AddDbContext<ApplicationDbContext>(options =>
            {
                options.UseInMemoryDatabase(_dbName)
                       .UseInternalServiceProvider(inMemoryProvider);
            });

            var appDbDescriptor = services.SingleOrDefault(d => d.ServiceType == typeof(IApplicationDbContext));
            if (appDbDescriptor != null)
            {
                services.Remove(appDbDescriptor);
            }
            services.AddScoped<IApplicationDbContext>(sp => sp.GetRequiredService<ApplicationDbContext>());

            var sp = services.BuildServiceProvider();
            using var scope = sp.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
            db.Database.EnsureCreated();

            if (!db.Activities.Any())
            {
                db.Activities.Add(Activity.Create(
                    "Balance Path",
                    "Follow the path to improve motor coordination.",
                    ActivityDomain.Movement,
                    DifficultyLevel.Beginner));

                db.Activities.Add(Activity.Create(
                    "Speech Rhyme Fun",
                    "Repeat rhymes to develop phonological awareness.",
                    ActivityDomain.Speech,
                    DifficultyLevel.Intermediate));

                db.SaveChanges();
            }
        });

        builder.UseEnvironment("Testing");
    }

    public async Task ConfirmUserEmailAsync(string email)
    {
        using var scope = Services.CreateScope();
        var identityService = scope.ServiceProvider.GetRequiredService<IIdentityService>();
        var user = await identityService.GetUserByEmailAsync(email);
        if (user != null)
        {
            await identityService.ConfirmEmailAsync(user.Value.UserId);
        }
    }

    public async Task<string> ConfirmAndLoginAsync(string email, string password = "Password123!")
    {
        await ConfirmUserEmailAsync(email);

        var client = CreateClient();
        var loginResponse = await System.Net.Http.Json.HttpClientJsonExtensions.PostAsJsonAsync(
            client,
            "/api/auth/login",
            new Mindora.Application.Features.Auth.Login.LoginRequest(email, password));

        var loginResult = await System.Net.Http.Json.HttpContentJsonExtensions.ReadFromJsonAsync<Mindora.Application.Features.Auth.Models.AuthResponseDto>(
            loginResponse.Content);

        return loginResult!.Token!;
    }
}
