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
        services.AddScoped<Features.Auth.Login.GoogleLoginHandler>();
        services.AddScoped<Features.Auth.GetCurrentUser.GetCurrentUserHandler>();
        services.AddScoped<Features.Auth.ForgotPassword.ForgotPasswordHandler>();
        services.AddScoped<Features.Auth.VerifyOtp.VerifyOtpHandler>();
        services.AddScoped<Features.Auth.ResetPassword.ResetPasswordHandler>();
        services.AddScoped<Features.Auth.ChangePassword.ChangePasswordHandler>();
        services.AddScoped<Features.Auth.SendVerificationOtp.SendVerificationOtpHandler>();
        services.AddScoped<Features.Auth.VerifyEmail.VerifyEmailHandler>();

        // Children Feature Handlers
        services.AddScoped<Features.Children.CreateChild.CreateChildHandler>();
        services.AddScoped<Features.Children.GetParentChildren.GetParentChildrenHandler>();
        services.AddScoped<Features.Children.GetChildDetails.GetChildDetailsHandler>();
        services.AddScoped<Features.Children.AssignDoctor.AssignDoctorHandler>();
        services.AddScoped<Features.Children.SoftDeleteChild.SoftDeleteChildHandler>();
        services.AddScoped<Features.Children.GenerateLinkingCode.GenerateLinkingCodeHandler>();
        services.AddScoped<Features.Children.LinkDoctor.LinkDoctorByCodeHandler>();

        // Activities Feature Handlers
        services.AddScoped<Features.Activities.GetActivities.GetActivitiesHandler>();
        services.AddScoped<Features.Activities.GetActivityById.GetActivityByIdHandler>();
        services.AddScoped<Features.Activities.GetChildActivityPerformance.GetChildActivityPerformanceHandler>();

        // Sessions Feature Handlers
        services.AddScoped<Features.Sessions.StartSession.StartSessionHandler>();
        services.AddScoped<Features.Sessions.RecordMetrics.RecordMetricsHandler>();
        services.AddScoped<Features.Sessions.CompleteSession.CompleteSessionHandler>();
        services.AddScoped<Features.Sessions.GetSessionDetails.GetSessionDetailsHandler>();
        services.AddScoped<Features.Sessions.AbandonSession.AbandonSessionHandler>();
        services.AddScoped<Features.Sessions.RecordFeedback.RecordFeedbackHandler>();

        // Assessments Feature Handlers
        services.AddScoped<Features.Assessments.RecordBaselineAssessment.RecordBaselineAssessmentHandler>();
        services.AddScoped<Features.Assessments.GetChildBaselineAssessment.GetChildBaselineAssessmentHandler>();

        // Progress Feature Handlers
        services.AddScoped<Features.Progress.GetChildProgress.GetChildProgressHandler>();
        services.AddScoped<Features.Progress.GetChildProgressHistory.GetChildProgressHistoryHandler>();

        // Doctor Feature Handlers
        services.AddScoped<Features.Doctor.GetDoctorDashboard.GetDoctorDashboardHandler>();
        services.AddScoped<Features.Doctor.GetDoctorChildren.GetDoctorChildrenHandler>();
        services.AddScoped<Features.Doctor.LinkChild.LinkChildHandler>();
        services.AddScoped<Features.Doctor.Notes.UpdateDoctorNotesHandler>();
        services.AddScoped<Features.Doctor.Notes.GetDoctorNotesHandler>();
        services.AddScoped<Features.Doctor.ConnectionRequests.GetDoctorLinkRequestsHandler>();
        services.AddScoped<Features.Doctor.ConnectionRequests.ApproveDoctorLinkRequestHandler>();
        services.AddScoped<Features.Doctor.ConnectionRequests.RejectDoctorLinkRequestHandler>();

        // Chat Feature Handlers (AI Assistant)
        services.AddScoped<Features.Chat.SendMessage.SendMessageHandler>();

        return services;
    }
}
