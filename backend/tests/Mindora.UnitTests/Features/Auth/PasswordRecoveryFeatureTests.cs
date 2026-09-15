using System.Security.Claims;
using FluentValidation;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Mindora.Application;
using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Features.Auth.ChangePassword;
using Mindora.Application.Features.Auth.ForgotPassword;
using Mindora.Application.Features.Auth.ResetPassword;
using Mindora.Application.Features.Auth.VerifyOtp;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;
using Mindora.Infrastructure.Identity;
using Mindora.Infrastructure.Persistence;
using Mindora.Infrastructure.Services;
using Xunit;

namespace Mindora.UnitTests.Features.Auth;

public class TestEmailService : IEmailService
{
    public List<(string ToEmail, string OtpCode, int ExpiryMinutes)> SentEmails { get; } = new();
    public List<(string ToEmail, string OtpCode, int ExpiryMinutes, ClientPlatform Platform)> SentVerificationEmails { get; } = new();

    public Task SendPasswordResetOtpAsync(
        string toEmail,
        string otpCode,
        int expiryMinutes,
        CancellationToken cancellationToken = default)
    {
        SentEmails.Add((toEmail, otpCode, expiryMinutes));
        return Task.CompletedTask;
    }

    public Task SendEmailVerificationOtpAsync(
        string toEmail,
        string otpCode,
        int expiryMinutes,
        ClientPlatform platform,
        CancellationToken cancellationToken = default)
    {
        SentVerificationEmails.Add((toEmail, otpCode, expiryMinutes, platform));
        return Task.CompletedTask;
    }
}

public class PasswordRecoveryFeatureTests : IDisposable
{
    private readonly ServiceProvider _serviceProvider;
    private readonly ApplicationDbContext _dbContext;
    private readonly IIdentityService _identityService;
    private readonly TestEmailService _emailService;
    private readonly UserManager<ApplicationUser> _userManager;

    public PasswordRecoveryFeatureTests()
    {
        var services = new ServiceCollection();
        services.AddLogging();

        var dbName = Guid.NewGuid().ToString();
        services.AddDbContext<ApplicationDbContext>(options =>
            options.UseInMemoryDatabase(dbName));

        services.AddScoped<IApplicationDbContext>(sp => sp.GetRequiredService<ApplicationDbContext>());

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

        services.AddScoped<IIdentityService, IdentityService>();

        services.Configure<JwtOptions>(opt =>
        {
            opt.Issuer = "Mindora";
            opt.Audience = "MindoraApp";
            opt.SecretKey = "MindoraTestSecretKeyMinimum32CharactersLong2026!";
            opt.ExpirationMinutes = 60;
        });
        services.AddScoped<IJwtTokenService, JwtTokenService>();

        _emailService = new TestEmailService();
        services.AddSingleton<IEmailService>(_emailService);

        services.AddHttpContextAccessor();
        services.AddScoped<ICurrentUserService, CurrentUserService>();

        services.AddApplicationServices();

        _serviceProvider = services.BuildServiceProvider();
        _dbContext = _serviceProvider.GetRequiredService<ApplicationDbContext>();
        _identityService = _serviceProvider.GetRequiredService<IIdentityService>();
        _userManager = _serviceProvider.GetRequiredService<UserManager<ApplicationUser>>();
    }

    public void Dispose()
    {
        _dbContext.Dispose();
        _serviceProvider.Dispose();
    }

    private async Task<(Guid UserId, string Email)> CreateTestUserAsync(
        string email = "user@example.com",
        string password = "Password123!")
    {
        var (succeeded, userId, _) = await _identityService.CreateUserAsync(
            email,
            password,
            "Test User",
            UserRole.Parent);

        Assert.True(succeeded);
        return (userId, email);
    }

    private async Task<(Guid UserId, string Email)> CreateTestDoctorAsync(
        string email = "doctor@example.com",
        string password = "Password123!")
    {
        var (succeeded, userId, _) = await _identityService.CreateUserAsync(
            email,
            password,
            "Dr. Test User",
            UserRole.Doctor);

        Assert.True(succeeded);
        return (userId, email);
    }

    [Fact]
    public async Task ForgotPassword_WithRegisteredEmail_CreatesOtpRecordAndCallsEmailService()
    {
        var (_, email) = await CreateTestUserAsync("parent@mindora.com");
        var handler = _serviceProvider.GetRequiredService<ForgotPasswordHandler>();

        var response = await handler.HandleAsync(new ForgotPasswordRequest(email));

        Assert.Equal(ForgotPasswordHandler.GenericResponse, response.Message);
        Assert.Single(_emailService.SentEmails);
        Assert.Equal(email, _emailService.SentEmails[0].ToEmail);
        Assert.Equal(6, _emailService.SentEmails[0].OtpCode.Length);

        var tokenRecord = await _dbContext.PasswordResetTokens.FirstOrDefaultAsync(t => t.Email == email);
        Assert.NotNull(tokenRecord);
        Assert.False(tokenRecord.IsOtpVerified);
        Assert.False(tokenRecord.IsUsed);
    }

    [Fact]
    public async Task ForgotPassword_WithUnknownEmail_ReturnsGenericResponse_DoesNotSendEmail()
    {
        var handler = _serviceProvider.GetRequiredService<ForgotPasswordHandler>();

        var response = await handler.HandleAsync(new ForgotPasswordRequest("nonexistent@mindora.com"));

        Assert.Equal(ForgotPasswordHandler.GenericResponse, response.Message);
        Assert.Empty(_emailService.SentEmails);
    }

    [Fact]
    public async Task ForgotPassword_WithinCooldownPeriod_ThrowsBadRequestException()
    {
        var (_, email) = await CreateTestUserAsync("cooldown@mindora.com");
        var handler = _serviceProvider.GetRequiredService<ForgotPasswordHandler>();

        await handler.HandleAsync(new ForgotPasswordRequest(email));

        // Rapid second attempt within 60s
        await Assert.ThrowsAsync<BadRequestException>(() =>
            handler.HandleAsync(new ForgotPasswordRequest(email)));
    }

    [Fact]
    public async Task ForgotPassword_InvalidatesPreviousPendingOtp()
    {
        var (userId, email) = await CreateTestUserAsync("replace@mindora.com");

        // Simulate an older active token created 2 minutes ago
        var oldOtp = "111222";
        var oldRecord = PasswordResetToken.Create(
            userId,
            email,
            oldOtp,
            TimeSpan.FromMinutes(10),
            DateTime.UtcNow.AddMinutes(-2));
        _dbContext.Add(oldRecord);
        await _dbContext.SaveChangesAsync();

        var handler = _serviceProvider.GetRequiredService<ForgotPasswordHandler>();
        await handler.HandleAsync(new ForgotPasswordRequest(email));

        // Old record should now be marked as used/invalidated
        var refreshedOld = await _dbContext.PasswordResetTokens.FindAsync(oldRecord.Id);
        Assert.NotNull(refreshedOld);
        Assert.True(refreshedOld.IsUsed);
    }

    [Fact]
    public async Task VerifyOtp_WithValidOtp_ReturnsResetToken()
    {
        var (_, email) = await CreateTestUserAsync("verify@mindora.com");
        var forgotHandler = _serviceProvider.GetRequiredService<ForgotPasswordHandler>();
        await forgotHandler.HandleAsync(new ForgotPasswordRequest(email));

        var generatedOtp = _emailService.SentEmails[0].OtpCode;
        var verifyHandler = _serviceProvider.GetRequiredService<VerifyOtpHandler>();

        var verifyResponse = await verifyHandler.HandleAsync(new VerifyOtpRequest(email, generatedOtp));

        Assert.NotNull(verifyResponse.ResetToken);
        Assert.NotEmpty(verifyResponse.ResetToken);

        var tokenRecord = await _dbContext.PasswordResetTokens.FirstOrDefaultAsync(t => t.Email == email);
        Assert.NotNull(tokenRecord);
        Assert.True(tokenRecord.IsOtpVerified);
        Assert.NotNull(tokenRecord.ResetTokenHash);
    }

    [Fact]
    public async Task VerifyOtp_WithInvalidOtp_IncrementsAttemptsAndThrowsBadRequestException()
    {
        var (_, email) = await CreateTestUserAsync("wrongotp@mindora.com");
        var forgotHandler = _serviceProvider.GetRequiredService<ForgotPasswordHandler>();
        await forgotHandler.HandleAsync(new ForgotPasswordRequest(email));

        var verifyHandler = _serviceProvider.GetRequiredService<VerifyOtpHandler>();

        var ex = await Assert.ThrowsAsync<BadRequestException>(() =>
            verifyHandler.HandleAsync(new VerifyOtpRequest(email, "999999")));

        Assert.Contains("غير صحيح", ex.Message);

        var tokenRecord = await _dbContext.PasswordResetTokens.FirstOrDefaultAsync(t => t.Email == email);
        Assert.NotNull(tokenRecord);
        Assert.Equal(1, tokenRecord.OtpAttempts);
        Assert.False(tokenRecord.IsOtpVerified);
    }

    [Fact]
    public async Task VerifyOtp_WhenAttemptsExceeded_BlocksVerification()
    {
        var (userId, email) = await CreateTestUserAsync("maxattempts@mindora.com");

        var record = PasswordResetToken.Create(userId, email, "123456", TimeSpan.FromMinutes(10));
        // Simulate 5 prior failed attempts
        for (int i = 0; i < 5; i++)
        {
            record.VerifyOtp("000000", DateTime.UtcNow);
        }
        _dbContext.Add(record);
        await _dbContext.SaveChangesAsync();

        var verifyHandler = _serviceProvider.GetRequiredService<VerifyOtpHandler>();

        var ex = await Assert.ThrowsAsync<BadRequestException>(() =>
            verifyHandler.HandleAsync(new VerifyOtpRequest(email, "123456")));

        Assert.Contains("تم تجاوز الحد الأقصى للمحاولات", ex.Message);
    }

    [Fact]
    public async Task VerifyOtp_WhenExpired_ThrowsBadRequestException()
    {
        var (userId, email) = await CreateTestUserAsync("expired@mindora.com");

        // Expired token created 20 minutes ago with 10 minutes validity
        var record = PasswordResetToken.Create(
            userId,
            email,
            "123456",
            TimeSpan.FromMinutes(10),
            DateTime.UtcNow.AddMinutes(-20));
        _dbContext.Add(record);
        await _dbContext.SaveChangesAsync();

        var verifyHandler = _serviceProvider.GetRequiredService<VerifyOtpHandler>();

        var ex = await Assert.ThrowsAsync<BadRequestException>(() =>
            verifyHandler.HandleAsync(new VerifyOtpRequest(email, "123456")));

        Assert.Contains("صلاحية", ex.Message);
    }

    [Fact]
    public async Task ResetPassword_WithValidResetToken_UpdatesPasswordAndInvalidatesTokens()
    {
        var (userId, email) = await CreateTestUserAsync("reset@mindora.com", "OldPassword1!");
        var forgotHandler = _serviceProvider.GetRequiredService<ForgotPasswordHandler>();
        await forgotHandler.HandleAsync(new ForgotPasswordRequest(email));

        var generatedOtp = _emailService.SentEmails[0].OtpCode;
        var verifyHandler = _serviceProvider.GetRequiredService<VerifyOtpHandler>();
        var verifyResponse = await verifyHandler.HandleAsync(new VerifyOtpRequest(email, generatedOtp));

        var resetHandler = _serviceProvider.GetRequiredService<ResetPasswordHandler>();
        var newPassword = "BrandNewPassword2026!";
        var resetResponse = await resetHandler.HandleAsync(new ResetPasswordRequest(
            verifyResponse.ResetToken,
            newPassword,
            newPassword));

        Assert.Contains("بنجاح", resetResponse.Message);

        // Verify that authentication succeeds with the new password
        var (authSuccess, authUserId, _, _, _, _) = await _identityService.AuthenticateAsync(
            email,
            newPassword);
        Assert.True(authSuccess);
        Assert.Equal(userId, authUserId);

        // Verify old password fails
        var (oldAuthSuccess, _, _, _, _, _) = await _identityService.AuthenticateAsync(
            email,
            "OldPassword1!");
        Assert.False(oldAuthSuccess);

        // Token record should be marked used
        var tokenRecord = await _dbContext.PasswordResetTokens.FirstOrDefaultAsync(t => t.Email == email);
        Assert.NotNull(tokenRecord);
        Assert.True(tokenRecord.IsUsed);
    }

    [Fact]
    public async Task ResetPassword_CannotBeReused()
    {
        var (_, email) = await CreateTestUserAsync("singleuse@mindora.com");
        var forgotHandler = _serviceProvider.GetRequiredService<ForgotPasswordHandler>();
        await forgotHandler.HandleAsync(new ForgotPasswordRequest(email));

        var generatedOtp = _emailService.SentEmails[0].OtpCode;
        var verifyHandler = _serviceProvider.GetRequiredService<VerifyOtpHandler>();
        var verifyResponse = await verifyHandler.HandleAsync(new VerifyOtpRequest(email, generatedOtp));

        var resetHandler = _serviceProvider.GetRequiredService<ResetPasswordHandler>();
        await resetHandler.HandleAsync(new ResetPasswordRequest(
            verifyResponse.ResetToken,
            "NewPass123!",
            "NewPass123!"));

        // Reusing same resetToken must fail
        await Assert.ThrowsAsync<BadRequestException>(() =>
            resetHandler.HandleAsync(new ResetPasswordRequest(
                verifyResponse.ResetToken,
                "AnotherPass123!",
                "AnotherPass123!")));
    }

    [Fact]
    public async Task ChangePassword_WithValidCredentials_Succeeds()
    {
        var (userId, email) = await CreateTestUserAsync("changepass@mindora.com", "CurrentPass123!");

        // Set HttpContext with authenticated claims
        var httpContext = new DefaultHttpContext();
        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, userId.ToString()),
            new Claim(ClaimTypes.Email, email),
            new Claim(ClaimTypes.Role, UserRole.Parent.ToString())
        };
        httpContext.User = new ClaimsPrincipal(new ClaimsIdentity(claims, "TestAuth"));

        var httpAccessor = _serviceProvider.GetRequiredService<IHttpContextAccessor>();
        httpAccessor.HttpContext = httpContext;

        var handler = _serviceProvider.GetRequiredService<ChangePasswordHandler>();
        var response = await handler.HandleAsync(new ChangePasswordRequest(
            "CurrentPass123!",
            "UpdatedPass999!",
            "UpdatedPass999!"));

        Assert.Contains("بنجاح", response.Message);

        var (authSuccess, _, _, _, _, _) = await _identityService.AuthenticateAsync(
            email,
            "UpdatedPass999!");
        Assert.True(authSuccess);
    }

    [Fact]
    public async Task ChangePassword_WithIncorrectCurrentPassword_ThrowsBadRequestException()
    {
        var (userId, email) = await CreateTestUserAsync("wrongcurrent@mindora.com", "CorrectPass1!");

        var httpContext = new DefaultHttpContext();
        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, userId.ToString()),
            new Claim(ClaimTypes.Email, email),
            new Claim(ClaimTypes.Role, UserRole.Parent.ToString())
        };
        httpContext.User = new ClaimsPrincipal(new ClaimsIdentity(claims, "TestAuth"));

        var httpAccessor = _serviceProvider.GetRequiredService<IHttpContextAccessor>();
        httpAccessor.HttpContext = httpContext;

        var handler = _serviceProvider.GetRequiredService<ChangePasswordHandler>();

        await Assert.ThrowsAsync<BadRequestException>(() =>
            handler.HandleAsync(new ChangePasswordRequest(
                "WrongPassword!",
                "NewSecretPass1!",
                "NewSecretPass1!")));
    }

    [Fact]
    public async Task ChangePassword_WhenUnauthenticated_ThrowsUnauthorizedException()
    {
        var httpAccessor = _serviceProvider.GetRequiredService<IHttpContextAccessor>();
        httpAccessor.HttpContext = new DefaultHttpContext(); // No user claims

        var handler = _serviceProvider.GetRequiredService<ChangePasswordHandler>();

        await Assert.ThrowsAsync<UnauthorizedException>(() =>
            handler.HandleAsync(new ChangePasswordRequest(
                "CurrentPass1!",
                "NewSecretPass1!",
                "NewSecretPass1!")));
    }

    [Fact]
    public async Task ForgotPassword_ParentEmail_FromDashboard_ReturnsWrongPlatform_NoOtpSent()
    {
        // 6. Parent email from Dashboard -> WrongPlatform, no OTP sent
        var (_, email) = await CreateTestUserAsync("parent.dash@mindora.com");
        var handler = _serviceProvider.GetRequiredService<ForgotPasswordHandler>();

        var response = await handler.HandleAsync(new ForgotPasswordRequest(email, "DoctorDashboard"));

        Assert.Equal(ForgotPasswordStatus.WrongPlatform, response.Status);
        Assert.Contains("SAWA APP", response.Message);
        Assert.Empty(_emailService.SentEmails);

        var tokenRecord = await _dbContext.PasswordResetTokens.FirstOrDefaultAsync(t => t.Email == email);
        Assert.Null(tokenRecord);
    }

    [Fact]
    public async Task ForgotPassword_DoctorEmail_FromDashboard_OtpFlowAllowed()
    {
        // 7. Doctor email from Dashboard -> OTP flow allowed
        var (_, email) = await CreateTestDoctorAsync("doctor.dash@mindora.com");
        var handler = _serviceProvider.GetRequiredService<ForgotPasswordHandler>();

        var response = await handler.HandleAsync(new ForgotPasswordRequest(email, "DoctorDashboard"));

        Assert.Equal(ForgotPasswordStatus.ContinueReset, response.Status);
        Assert.Equal(ForgotPasswordHandler.GenericResponse, response.Message);
        Assert.Single(_emailService.SentEmails);
        Assert.Equal(email, _emailService.SentEmails[0].ToEmail);

        var tokenRecord = await _dbContext.PasswordResetTokens.FirstOrDefaultAsync(t => t.Email == email);
        Assert.NotNull(tokenRecord);
        Assert.False(tokenRecord.IsUsed);
    }

    [Fact]
    public async Task ForgotPassword_DoctorEmail_FromSawa_ReturnsWrongPlatform_NoOtpSent()
    {
        // 8. Doctor email from SAWA -> WrongPlatform, no OTP sent
        var (_, email) = await CreateTestDoctorAsync("doctor.sawa@mindora.com");
        var handler = _serviceProvider.GetRequiredService<ForgotPasswordHandler>();

        var response = await handler.HandleAsync(new ForgotPasswordRequest(email, "SawaApp"));

        Assert.Equal(ForgotPasswordStatus.WrongPlatform, response.Status);
        Assert.Contains("لوحة تحكم الطبيب", response.Message);
        Assert.Empty(_emailService.SentEmails);

        var tokenRecord = await _dbContext.PasswordResetTokens.FirstOrDefaultAsync(t => t.Email == email);
        Assert.Null(tokenRecord);
    }

    [Fact]
    public async Task ForgotPassword_ParentEmail_FromSawa_OtpFlowAllowed()
    {
        // 9. Parent email from SAWA -> OTP flow allowed
        var (_, email) = await CreateTestUserAsync("parent.sawa@mindora.com");
        var handler = _serviceProvider.GetRequiredService<ForgotPasswordHandler>();

        var response = await handler.HandleAsync(new ForgotPasswordRequest(email, "SawaApp"));

        Assert.Equal(ForgotPasswordStatus.ContinueReset, response.Status);
        Assert.Equal(ForgotPasswordHandler.GenericResponse, response.Message);
        Assert.Single(_emailService.SentEmails);
        Assert.Equal(email, _emailService.SentEmails[0].ToEmail);

        var tokenRecord = await _dbContext.PasswordResetTokens.FirstOrDefaultAsync(t => t.Email == email);
        Assert.NotNull(tokenRecord);
        Assert.False(tokenRecord.IsUsed);
    }

    [Fact]
    public async Task ForgotPassword_UnknownEmail_ReturnsGenericAntiEnumerationResponse()
    {
        // 10. Unknown email -> generic anti-enumeration response/behavior
        var handler = _serviceProvider.GetRequiredService<ForgotPasswordHandler>();

        var response = await handler.HandleAsync(new ForgotPasswordRequest("totallyunknown@mindora.com", "DoctorDashboard"));

        Assert.Equal(ForgotPasswordStatus.ContinueReset, response.Status);
        Assert.Equal(ForgotPasswordHandler.GenericResponse, response.Message);
        Assert.Empty(_emailService.SentEmails);
    }

    [Fact]
    public async Task ForgotPassword_WrongPlatform_DoesNotCreateUsableResetToken()
    {
        // 11. Wrong-platform request must NOT create a usable reset token
        var (_, email) = await CreateTestUserAsync("wrongtoken@mindora.com");
        var handler = _serviceProvider.GetRequiredService<ForgotPasswordHandler>();

        await handler.HandleAsync(new ForgotPasswordRequest(email, "DoctorDashboard"));

        var tokens = await _dbContext.PasswordResetTokens.Where(t => t.Email == email).ToListAsync();
        Assert.Empty(tokens);
    }

    [Fact]
    public async Task ForgotPassword_WrongPlatform_DoesNotSendOtpEmail()
    {
        // 12. Wrong-platform request must NOT send an OTP email
        var (_, parentEmail) = await CreateTestUserAsync("parent.noemail@mindora.com");
        var (_, doctorEmail) = await CreateTestDoctorAsync("doctor.noemail@mindora.com");
        var handler = _serviceProvider.GetRequiredService<ForgotPasswordHandler>();

        await handler.HandleAsync(new ForgotPasswordRequest(parentEmail, "DoctorDashboard"));
        await handler.HandleAsync(new ForgotPasswordRequest(doctorEmail, "SawaApp"));

        Assert.Empty(_emailService.SentEmails);
    }

    [Fact]
    public async Task PasswordRecovery_ValidResetFlow_SucceedsOnCorrectPlatform()
    {
        // 13. Valid reset flow succeeds on the correct platform
        // SAWA Parent flow:
        var (parentUserId, parentEmail) = await CreateTestUserAsync("flow.parent@mindora.com", "OldParentPass1!");
        var forgotHandler = _serviceProvider.GetRequiredService<ForgotPasswordHandler>();
        var verifyHandler = _serviceProvider.GetRequiredService<VerifyOtpHandler>();
        var resetHandler = _serviceProvider.GetRequiredService<ResetPasswordHandler>();

        await forgotHandler.HandleAsync(new ForgotPasswordRequest(parentEmail, "SawaApp"));
        var parentOtp = _emailService.SentEmails.Last().OtpCode;

        var verifyParentRes = await verifyHandler.HandleAsync(new VerifyOtpRequest(parentEmail, parentOtp, "SawaApp"));
        Assert.NotNull(verifyParentRes.ResetToken);

        var resetParentRes = await resetHandler.HandleAsync(new ResetPasswordRequest(
            verifyParentRes.ResetToken,
            "NewParentPass99!",
            "NewParentPass99!",
            "SawaApp"));
        Assert.Contains("بنجاح", resetParentRes.Message);

        var (parentAuthSuccess, _, _, _, parentRole, _) = await _identityService.AuthenticateAsync(parentEmail, "NewParentPass99!");
        Assert.True(parentAuthSuccess);
        Assert.Equal(UserRole.Parent, parentRole);

        // Doctor Dashboard flow:
        var (doctorUserId, doctorEmail) = await CreateTestDoctorAsync("flow.doctor@mindora.com", "OldDoctorPass1!");
        await forgotHandler.HandleAsync(new ForgotPasswordRequest(doctorEmail, "DoctorDashboard"));
        var doctorOtp = _emailService.SentEmails.Last().OtpCode;

        var verifyDoctorRes = await verifyHandler.HandleAsync(new VerifyOtpRequest(doctorEmail, doctorOtp, "DoctorDashboard"));
        Assert.NotNull(verifyDoctorRes.ResetToken);

        var resetDoctorRes = await resetHandler.HandleAsync(new ResetPasswordRequest(
            verifyDoctorRes.ResetToken,
            "NewDoctorPass99!",
            "NewDoctorPass99!",
            "DoctorDashboard"));
        Assert.Contains("بنجاح", resetDoctorRes.Message);

        var (doctorAuthSuccess, _, _, _, doctorRole, _) = await _identityService.AuthenticateAsync(doctorEmail, "NewDoctorPass99!");
        Assert.True(doctorAuthSuccess);
        Assert.Equal(UserRole.Doctor, doctorRole);
    }

    [Fact]
    public async Task PasswordRecovery_ResetToken_CannotBeReused()
    {
        // 14. Reset token cannot be reused
        var (_, email) = await CreateTestUserAsync("reuse.token@mindora.com", "OriginalPass1!");
        var forgotHandler = _serviceProvider.GetRequiredService<ForgotPasswordHandler>();
        var verifyHandler = _serviceProvider.GetRequiredService<VerifyOtpHandler>();
        var resetHandler = _serviceProvider.GetRequiredService<ResetPasswordHandler>();

        await forgotHandler.HandleAsync(new ForgotPasswordRequest(email, "SawaApp"));
        var otp = _emailService.SentEmails.Last().OtpCode;
        var verifyRes = await verifyHandler.HandleAsync(new VerifyOtpRequest(email, otp, "SawaApp"));

        // First use: succeeds
        await resetHandler.HandleAsync(new ResetPasswordRequest(verifyRes.ResetToken, "FreshPass123!", "FreshPass123!", "SawaApp"));

        // Second use: must fail
        await Assert.ThrowsAsync<BadRequestException>(() =>
            resetHandler.HandleAsync(new ResetPasswordRequest(verifyRes.ResetToken, "AnotherPass456!", "AnotherPass456!", "SawaApp")));
    }

    [Fact]
    public async Task PasswordRecovery_ResetToken_CannotCrossPlatforms()
    {
        // 15. Reset token cannot cross platforms
        var (_, parentEmail) = await CreateTestUserAsync("cross.parent@mindora.com", "ParentPass1!");
        var (_, doctorEmail) = await CreateTestDoctorAsync("cross.doctor@mindora.com", "DoctorPass1!");

        var forgotHandler = _serviceProvider.GetRequiredService<ForgotPasswordHandler>();
        var verifyHandler = _serviceProvider.GetRequiredService<VerifyOtpHandler>();
        var resetHandler = _serviceProvider.GetRequiredService<ResetPasswordHandler>();

        // 1. Parent token attempted on Doctor Dashboard
        await forgotHandler.HandleAsync(new ForgotPasswordRequest(parentEmail, "SawaApp"));
        var parentOtp = _emailService.SentEmails.Last().OtpCode;
        var parentVerifyRes = await verifyHandler.HandleAsync(new VerifyOtpRequest(parentEmail, parentOtp, "SawaApp"));

        var parentCrossEx = await Assert.ThrowsAsync<BadRequestException>(() =>
            resetHandler.HandleAsync(new ResetPasswordRequest(
                parentVerifyRes.ResetToken,
                "HackedPass123!",
                "HackedPass123!",
                "DoctorDashboard")));
        Assert.Contains("لوحة تحكم الطبيب", parentCrossEx.Message);

        // 2. Doctor token attempted on SAWA App
        await forgotHandler.HandleAsync(new ForgotPasswordRequest(doctorEmail, "DoctorDashboard"));
        var doctorOtp = _emailService.SentEmails.Last().OtpCode;
        var doctorVerifyRes = await verifyHandler.HandleAsync(new VerifyOtpRequest(doctorEmail, doctorOtp, "DoctorDashboard"));

        var doctorCrossEx = await Assert.ThrowsAsync<BadRequestException>(() =>
            resetHandler.HandleAsync(new ResetPasswordRequest(
                doctorVerifyRes.ResetToken,
                "HackedPass456!",
                "HackedPass456!",
                "SawaApp")));
        Assert.Contains("تطبيق SAWA", doctorCrossEx.Message);
    }

    [Fact]
    public async Task ChangePassword_WorksForParent()
    {
        // 16. Change Password still works for Parent
        var (userId, email) = await CreateTestUserAsync("changepass.parent@mindora.com", "OldParentPass1!");

        var httpContext = new DefaultHttpContext();
        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, userId.ToString()),
            new Claim(ClaimTypes.Email, email),
            new Claim(ClaimTypes.Role, UserRole.Parent.ToString())
        };
        httpContext.User = new ClaimsPrincipal(new ClaimsIdentity(claims, "TestAuth"));

        var httpAccessor = _serviceProvider.GetRequiredService<IHttpContextAccessor>();
        httpAccessor.HttpContext = httpContext;

        var handler = _serviceProvider.GetRequiredService<ChangePasswordHandler>();
        var response = await handler.HandleAsync(new ChangePasswordRequest(
            "OldParentPass1!",
            "NewParentPass2!",
            "NewParentPass2!"));

        Assert.Contains("بنجاح", response.Message);

        var (authSuccess, _, _, _, role, _) = await _identityService.AuthenticateAsync(email, "NewParentPass2!");
        Assert.True(authSuccess);
        Assert.Equal(UserRole.Parent, role);
    }

    [Fact]
    public async Task ChangePassword_WorksForDoctor()
    {
        // 17. Change Password still works for Doctor
        var (userId, email) = await CreateTestDoctorAsync("changepass.doctor@mindora.com", "OldDoctorPass1!");

        var httpContext = new DefaultHttpContext();
        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, userId.ToString()),
            new Claim(ClaimTypes.Email, email),
            new Claim(ClaimTypes.Role, UserRole.Doctor.ToString())
        };
        httpContext.User = new ClaimsPrincipal(new ClaimsIdentity(claims, "TestAuth"));

        var httpAccessor = _serviceProvider.GetRequiredService<IHttpContextAccessor>();
        httpAccessor.HttpContext = httpContext;

        var handler = _serviceProvider.GetRequiredService<ChangePasswordHandler>();
        var response = await handler.HandleAsync(new ChangePasswordRequest(
            "OldDoctorPass1!",
            "NewDoctorPass2!",
            "NewDoctorPass2!"));

        Assert.Contains("بنجاح", response.Message);

        var (authSuccess, _, _, _, role, _) = await _identityService.AuthenticateAsync(email, "NewDoctorPass2!");
        Assert.True(authSuccess);
        Assert.Equal(UserRole.Doctor, role);
    }

    [Fact]
    public async Task Role_RemainsUnchanged_AfterPasswordResetAndChange()
    {
        // 18. Role remains unchanged after password reset/change
        // Doctor:
        var (docId, docEmail) = await CreateTestDoctorAsync("rolecheck.doctor@mindora.com", "InitialDoc1!");
        var userDocBefore = await _identityService.GetUserByIdAsync(docId);
        Assert.Equal(UserRole.Doctor, userDocBefore!.Value.Role);

        // Reset flow:
        var forgotHandler = _serviceProvider.GetRequiredService<ForgotPasswordHandler>();
        var verifyHandler = _serviceProvider.GetRequiredService<VerifyOtpHandler>();
        var resetHandler = _serviceProvider.GetRequiredService<ResetPasswordHandler>();

        await forgotHandler.HandleAsync(new ForgotPasswordRequest(docEmail, "DoctorDashboard"));
        var otp = _emailService.SentEmails.Last().OtpCode;
        var verifyRes = await verifyHandler.HandleAsync(new VerifyOtpRequest(docEmail, otp, "DoctorDashboard"));
        await resetHandler.HandleAsync(new ResetPasswordRequest(verifyRes.ResetToken, "ResetDocPass1!", "ResetDocPass1!", "DoctorDashboard"));

        var userDocAfterReset = await _identityService.GetUserByIdAsync(docId);
        Assert.Equal(UserRole.Doctor, userDocAfterReset!.Value.Role);

        // Parent:
        var (parentId, parentEmail) = await CreateTestUserAsync("rolecheck.parent@mindora.com", "InitialParent1!");
        var userParentBefore = await _identityService.GetUserByIdAsync(parentId);
        Assert.Equal(UserRole.Parent, userParentBefore!.Value.Role);

        await forgotHandler.HandleAsync(new ForgotPasswordRequest(parentEmail, "SawaApp"));
        var parentOtp = _emailService.SentEmails.Last().OtpCode;
        var parentVerifyRes = await verifyHandler.HandleAsync(new VerifyOtpRequest(parentEmail, parentOtp, "SawaApp"));
        await resetHandler.HandleAsync(new ResetPasswordRequest(parentVerifyRes.ResetToken, "ResetParentPass1!", "ResetParentPass1!", "SawaApp"));

        var userParentAfterReset = await _identityService.GetUserByIdAsync(parentId);
        Assert.Equal(UserRole.Parent, userParentAfterReset!.Value.Role);
    }
}
