using FluentValidation;
using Microsoft.Extensions.DependencyInjection;

namespace Mindora.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplicationServices(this IServiceCollection services)
    {
        services.AddValidatorsFromAssembly(typeof(DependencyInjection).Assembly);

        // Auth Feature Handlers
        services.AddScoped<Features.Auth.RegisterParent.RegisterParentHandler>();
        services.AddScoped<Features.Auth.RegisterDoctor.RegisterDoctorHandler>();
        services.AddScoped<Features.Auth.Login.LoginHandler>();
        services.AddScoped<Features.Auth.GetCurrentUser.GetCurrentUserHandler>();

        // Children Feature Handlers
        services.AddScoped<Features.Children.CreateChild.CreateChildHandler>();
        services.AddScoped<Features.Children.GetParentChildren.GetParentChildrenHandler>();
        services.AddScoped<Features.Children.GetChildDetails.GetChildDetailsHandler>();
        services.AddScoped<Features.Children.AssignDoctor.AssignDoctorHandler>();
        services.AddScoped<Features.Children.SoftDeleteChild.SoftDeleteChildHandler>();

        // Activities Feature Handlers
        services.AddScoped<Features.Activities.GetActivities.GetActivitiesHandler>();
        services.AddScoped<Features.Activities.GetActivityById.GetActivityByIdHandler>();

        // Sessions Feature Handlers
        services.AddScoped<Features.Sessions.StartSession.StartSessionHandler>();
        services.AddScoped<Features.Sessions.RecordMetrics.RecordMetricsHandler>();
        services.AddScoped<Features.Sessions.CompleteSession.CompleteSessionHandler>();
        services.AddScoped<Features.Sessions.GetSessionDetails.GetSessionDetailsHandler>();

        // Progress Feature Handlers
        services.AddScoped<Features.Progress.GetChildProgress.GetChildProgressHandler>();
        services.AddScoped<Features.Progress.GetChildProgressHistory.GetChildProgressHistoryHandler>();

        return services;
    }
}
