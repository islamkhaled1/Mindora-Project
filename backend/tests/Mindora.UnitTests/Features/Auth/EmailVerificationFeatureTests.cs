using FluentValidation;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Mindora.Application;
using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Features.Auth.Login;
using Mindora.Application.Features.Auth.RegisterDoctor;
using Mindora.Application.Features.Auth.RegisterParent;
using Mindora.Application.Features.Auth.ResetPassword;
using Mindora.Application.Features.Auth.SendVerificationOtp;
using Mindora.Application.Features.Auth.VerifyEmail;
using Mindora.Application.Features.Auth.VerifyOtp;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;
using Mindora.Infrastructure.Identity;
using Mindora.Infrastructure.Persistence;
using Mindora.Infrastructure.Services;
using Xunit;

namespace Mindora.UnitTests.Features.Auth;

public class EmailVerificationFeatureTests : IDisposable
{
    private readonly ServiceProvider _serviceProvider;
    private readonly ApplicationDbContext _dbContext;
    private readonly IIdentityService _identityService;
    private readonly TestEmailService _emailService;
    private readonly UserManager<ApplicationUser> _userManager;

    public EmailVerificationFeatureTests()
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

    // 1. Parent registration -> EmailConfirmed=false
    [Fact]
    public async Task Scenario01_ParentRegistration_SetsEmailConfirmedFalse()
    {
        var handler = _serviceProvider.GetRequiredService<RegisterParentHandler>();
        var request = new RegisterParentRequest("parent_test1@example.com", "Password123!", "Test Parent", "+1234567890");

        var response = await handler.HandleAsync(request);

        Assert.True(response.RequiresEmailVerification);
        Assert.Null(response.Token);

        var user = await _userManager.FindByEmailAsync("parent_test1@example.com");
        Assert.NotNull(user);
        Assert.False(user.EmailConfirmed);
    }

    // 2. Doctor registration -> EmailConfirmed=false
    [Fact]
    public async Task Scenario02_DoctorRegistration_SetsEmailConfirmedFalse()
    {
        var handler = _serviceProvider.GetRequiredService<RegisterDoctorHandler>();
        var request = new RegisterDoctorRequest("doctor_test2@example.com", "Password123!", "Dr. Test", "+1234567891", "Pediatrics", "LIC12345");

        var response = await handler.HandleAsync(request);

        Assert.True(response.RequiresEmailVerification);
        Assert.Null(response.Token);

        var user = await _userManager.FindByEmailAsync("doctor_test2@example.com");
        Assert.NotNull(user);
        Assert.False(user.EmailConfirmed);
    }

    // 3. Verification OTP generated on registration
    [Fact]
    public async Task Scenario03_VerificationOtp_Generated_OnRegistration()
    {
        var handler = _serviceProvider.GetRequiredService<RegisterParentHandler>();
        var request = new RegisterParentRequest("parent_test3@example.com", "Password123!", "Test Parent", "+1234567890");

        await handler.HandleAsync(request);

        var user = await _userManager.FindByEmailAsync("parent_test3@example.com");
        var token = await _dbContext.EmailVerificationTokens
            .FirstOrDefaultAsync(t => t.UserId == user!.Id && t.Platform == ClientPlatform.SawaApp);

        Assert.NotNull(token);
        Assert.True(token.IsActive);
        Assert.False(token.IsVerified);
        Assert.Single(_emailService.SentVerificationEmails);
        Assert.Equal("parent_test3@example.com", _emailService.SentVerificationEmails[0].ToEmail);
    }

    // 4. OTP hashed before storage
    [Fact]
    public async Task Scenario04_VerificationOtp_HashedBeforeStorage()
    {
        var handler = _serviceProvider.GetRequiredService<RegisterParentHandler>();
        var request = new RegisterParentRequest("parent_test4@example.com", "Password123!", "Test Parent", "+1234567890");

        await handler.HandleAsync(request);

        var user = await _userManager.FindByEmailAsync("parent_test4@example.com");
        var token = await _dbContext.EmailVerificationTokens.FirstAsync(t => t.UserId == user!.Id);
        var sentOtp = _emailService.SentVerificationEmails[0].OtpCode;

        Assert.NotNull(token.OtpHash);
        Assert.NotEqual(sentOtp, token.OtpHash);
        Assert.Equal(64, token.OtpHash.Length); // SHA-256 hex string is 64 characters
    }

    // 5. OTP expires
    [Fact]
    public async Task Scenario05_VerificationOtp_Expires_AfterExpiryTime()
    {
        var token = EmailVerificationToken.Create(Guid.NewGuid(), "test5@example.com", ClientPlatform.SawaApp, "123456");
        var expiredTime = DateTime.UtcNow.AddMinutes(11);

        var (succeeded, errorMessage) = token.VerifyOtp("123456", expiredTime);

        Assert.False(succeeded);
        Assert.False(token.IsActive);
        Assert.Contains("انتهت صلاحية", errorMessage);
    }

    // 6. Wrong OTP rejected
    [Fact]
    public async Task Scenario06_WrongOtp_Rejected()
    {
        var handler = _serviceProvider.GetRequiredService<RegisterParentHandler>();
        await handler.HandleAsync(new RegisterParentRequest("parent_test6@example.com", "Password123!", "Test Parent", "+1234567890"));

        var verifyHandler = _serviceProvider.GetRequiredService<VerifyEmailHandler>();
        var request = new VerifyEmailRequest("parent_test6@example.com", "000000", "SawaApp");

        var ex = await Assert.ThrowsAsync<BadRequestException>(() => verifyHandler.HandleAsync(request));
        Assert.Contains("غير صحيح", ex.Message);
    }

    // 7. Attempt count increments
    [Fact]
    public async Task Scenario07_AttemptCount_Increments_OnWrongOtp()
    {
        var handler = _serviceProvider.GetRequiredService<RegisterParentHandler>();
        await handler.HandleAsync(new RegisterParentRequest("parent_test7@example.com", "Password123!", "Test Parent", "+1234567890"));

        var verifyHandler = _serviceProvider.GetRequiredService<VerifyEmailHandler>();
        var request = new VerifyEmailRequest("parent_test7@example.com", "000000", "SawaApp");

        await Assert.ThrowsAsync<BadRequestException>(() => verifyHandler.HandleAsync(request));

        var user = await _userManager.FindByEmailAsync("parent_test7@example.com");
        var token = await _dbContext.EmailVerificationTokens.FirstAsync(t => t.UserId == user!.Id);
        Assert.Equal(1, token.AttemptCount);
    }

    // 8. 5th/final invalid attempt invalidates OTP
    [Fact]
    public async Task Scenario08_FifthInvalidAttempt_InvalidatesOtp()
    {
        var handler = _serviceProvider.GetRequiredService<RegisterParentHandler>();
        await handler.HandleAsync(new RegisterParentRequest("parent_test8@example.com", "Password123!", "Test Parent", "+1234567890"));

        var verifyHandler = _serviceProvider.GetRequiredService<VerifyEmailHandler>();
        var request = new VerifyEmailRequest("parent_test8@example.com", "000000", "SawaApp");

        for (int i = 0; i < 5; i++)
        {
            await Assert.ThrowsAsync<BadRequestException>(() => verifyHandler.HandleAsync(request));
        }

        var user = await _userManager.FindByEmailAsync("parent_test8@example.com");
        var token = await _dbContext.EmailVerificationTokens.FirstAsync(t => t.UserId == user!.Id);
        Assert.False(token.IsActive);
        Assert.Equal(5, token.AttemptCount);

        // Next attempt with correct OTP is now blocked because token is inactive
        var sentOtp = _emailService.SentVerificationEmails[0].OtpCode;
        var ex = await Assert.ThrowsAsync<BadRequestException>(() =>
            verifyHandler.HandleAsync(new VerifyEmailRequest("parent_test8@example.com", sentOtp, "SawaApp")));
        Assert.Contains("لم يتم العثور على رمز تحقق فعال", ex.Message);
    }

    // 9. OTP cannot be reused
    [Fact]
    public async Task Scenario09_Otp_CannotBeReused_AfterSuccessfulVerification()
    {
        var handler = _serviceProvider.GetRequiredService<RegisterParentHandler>();
        await handler.HandleAsync(new RegisterParentRequest("parent_test9@example.com", "Password123!", "Test Parent", "+1234567890"));

        var sentOtp = _emailService.SentVerificationEmails[0].OtpCode;
        var verifyHandler = _serviceProvider.GetRequiredService<VerifyEmailHandler>();

        var firstResponse = await verifyHandler.HandleAsync(new VerifyEmailRequest("parent_test9@example.com", sentOtp, "SawaApp"));
        Assert.True(firstResponse.Succeeded);

        var user = await _userManager.FindByEmailAsync("parent_test9@example.com");
        var token = await _dbContext.EmailVerificationTokens.FirstAsync(t => t.UserId == user!.Id);
        Assert.False(token.IsActive);
        Assert.True(token.IsVerified);

        // Reusing the same OTP returns already verified without error, but active token cannot be re-verified
        var secondResponse = await verifyHandler.HandleAsync(new VerifyEmailRequest("parent_test9@example.com", sentOtp, "SawaApp"));
        Assert.True(secondResponse.Succeeded);
        Assert.Contains("مؤكد بالفعل", secondResponse.Message);
    }

    // 10. Resend cooldown enforced
    [Fact]
    public async Task Scenario10_ResendCooldown_Enforced()
    {
        var handler = _serviceProvider.GetRequiredService<RegisterParentHandler>();
        await handler.HandleAsync(new RegisterParentRequest("parent_test10@example.com", "Password123!", "Test Parent", "+1234567890"));

        var sendOtpHandler = _serviceProvider.GetRequiredService<SendVerificationOtpHandler>();
        var request = new SendVerificationOtpRequest("parent_test10@example.com", "SawaApp");

        var ex = await Assert.ThrowsAsync<BadRequestException>(() => sendOtpHandler.HandleAsync(request));
        Assert.Contains("يرجى الانتظار", ex.Message);
    }

    // 11. New OTP invalidates old OTP
    [Fact]
    public async Task Scenario11_NewOtp_InvalidatesOldOtp()
    {
        var handler = _serviceProvider.GetRequiredService<RegisterParentHandler>();
        await handler.HandleAsync(new RegisterParentRequest("parent_test11@example.com", "Password123!", "Test Parent", "+1234567890"));

        var user = await _userManager.FindByEmailAsync("parent_test11@example.com");
        var initialToken = await _dbContext.EmailVerificationTokens.FirstAsync(t => t.UserId == user!.Id);
        var initialOtp = _emailService.SentVerificationEmails[0].OtpCode;

        // Simulate 61 seconds passing
        typeof(EmailVerificationToken).GetProperty("LastRequestedAtUtc")!
            .SetValue(initialToken, DateTime.UtcNow.AddSeconds(-65));
        await _dbContext.SaveChangesAsync();

        var sendOtpHandler = _serviceProvider.GetRequiredService<SendVerificationOtpHandler>();
        await sendOtpHandler.HandleAsync(new SendVerificationOtpRequest("parent_test11@example.com", "SawaApp"));

        // Initial token is now inactive
        Assert.False(initialToken.IsActive);

        // Attempting to verify with old OTP fails
        var verifyHandler = _serviceProvider.GetRequiredService<VerifyEmailHandler>();
        var ex = await Assert.ThrowsAsync<BadRequestException>(() =>
            verifyHandler.HandleAsync(new VerifyEmailRequest("parent_test11@example.com", initialOtp, "SawaApp")));
        Assert.Contains("غير صحيح", ex.Message);

        // Attempting with new OTP succeeds
        var newOtp = _emailService.SentVerificationEmails[1].OtpCode;
        var verifyResponse = await verifyHandler.HandleAsync(new VerifyEmailRequest("parent_test11@example.com", newOtp, "SawaApp"));
        Assert.True(verifyResponse.Succeeded);
    }

    // 12. Correct OTP -> EmailConfirmed=true
    [Fact]
    public async Task Scenario12_CorrectOtp_SetsEmailConfirmedTrue()
    {
        var handler = _serviceProvider.GetRequiredService<RegisterParentHandler>();
        await handler.HandleAsync(new RegisterParentRequest("parent_test12@example.com", "Password123!", "Test Parent", "+1234567890"));

        var sentOtp = _emailService.SentVerificationEmails[0].OtpCode;
        var verifyHandler = _serviceProvider.GetRequiredService<VerifyEmailHandler>();

        await verifyHandler.HandleAsync(new VerifyEmailRequest("parent_test12@example.com", sentOtp, "SawaApp"));

        var user = await _userManager.FindByEmailAsync("parent_test12@example.com");
        Assert.True(user!.EmailConfirmed);
    }

    // 13. SAWA Parent verification succeeds and issues JWT
    [Fact]
    public async Task Scenario13_SawaParent_VerificationSucceeds_AndIssuesJwt()
    {
        var handler = _serviceProvider.GetRequiredService<RegisterParentHandler>();
        await handler.HandleAsync(new RegisterParentRequest("parent_test13@example.com", "Password123!", "Test Parent", "+1234567890"));

        var sentOtp = _emailService.SentVerificationEmails[0].OtpCode;
        var verifyHandler = _serviceProvider.GetRequiredService<VerifyEmailHandler>();

        var response = await verifyHandler.HandleAsync(new VerifyEmailRequest("parent_test13@example.com", sentOtp, "SawaApp"));

        Assert.True(response.Succeeded);
        Assert.NotNull(response.Token);
        Assert.NotNull(response.User);
        Assert.Equal("Parent", response.User.Role);
    }

    // 14. Dashboard Doctor verification succeeds without direct JWT
    [Fact]
    public async Task Scenario14_DashboardDoctor_VerificationSucceeds_WithoutDirectJwt()
    {
        var handler = _serviceProvider.GetRequiredService<RegisterDoctorHandler>();
        await handler.HandleAsync(new RegisterDoctorRequest("doctor_test14@example.com", "Password123!", "Dr. Test", "+1234567891", "Pediatrics", "LIC12345"));

        var sentOtp = _emailService.SentVerificationEmails[0].OtpCode;
        var verifyHandler = _serviceProvider.GetRequiredService<VerifyEmailHandler>();

        var response = await verifyHandler.HandleAsync(new VerifyEmailRequest("doctor_test14@example.com", sentOtp, "DoctorDashboard"));

        Assert.True(response.Succeeded);
        Assert.Null(response.Token); // Doctor goes to login page instead of receiving token directly
        Assert.NotNull(response.User);
        Assert.Equal("Doctor", response.User.Role);
    }

    // 15. Doctor verification via SAWA blocked
    [Fact]
    public async Task Scenario15_DoctorVerification_ViaSawa_BlockedWithForbidden()
    {
        var handler = _serviceProvider.GetRequiredService<RegisterDoctorHandler>();
        await handler.HandleAsync(new RegisterDoctorRequest("doctor_test15@example.com", "Password123!", "Dr. Test", "+1234567891", "Pediatrics", "LIC12345"));

        var sentOtp = _emailService.SentVerificationEmails[0].OtpCode;
        var verifyHandler = _serviceProvider.GetRequiredService<VerifyEmailHandler>();

        var ex = await Assert.ThrowsAsync<ForbiddenException>(() =>
            verifyHandler.HandleAsync(new VerifyEmailRequest("doctor_test15@example.com", sentOtp, "SawaApp")));
        Assert.Contains("لا يمكن تأكيد حساب الطبيب عبر تطبيق SAWA", ex.Message);
    }

    // 16. Parent verification via Dashboard blocked
    [Fact]
    public async Task Scenario16_ParentVerification_ViaDashboard_BlockedWithForbidden()
    {
        var handler = _serviceProvider.GetRequiredService<RegisterParentHandler>();
        await handler.HandleAsync(new RegisterParentRequest("parent_test16@example.com", "Password123!", "Test Parent", "+1234567890"));

        var sentOtp = _emailService.SentVerificationEmails[0].OtpCode;
        var verifyHandler = _serviceProvider.GetRequiredService<VerifyEmailHandler>();

        var ex = await Assert.ThrowsAsync<ForbiddenException>(() =>
            verifyHandler.HandleAsync(new VerifyEmailRequest("parent_test16@example.com", sentOtp, "DoctorDashboard")));
        Assert.Contains("لا يمكن تأكيد حساب ولي الأمر عبر لوحة تحكم الطبيب", ex.Message);
    }

    // 17. Verification OTP cannot reset password
    [Fact]
    public async Task Scenario17_VerificationOtp_CannotResetPassword()
    {
        var handler = _serviceProvider.GetRequiredService<RegisterParentHandler>();
        await handler.HandleAsync(new RegisterParentRequest("parent_test17@example.com", "Password123!", "Test Parent", "+1234567890"));

        var verificationOtp = _emailService.SentVerificationEmails[0].OtpCode;
        var verifyOtpHandler = _serviceProvider.GetRequiredService<VerifyOtpHandler>();

        // VerifyOtpHandler checks PasswordResetToken, NOT EmailVerificationToken
        var ex = await Assert.ThrowsAsync<BadRequestException>(() =>
            verifyOtpHandler.HandleAsync(new VerifyOtpRequest("parent_test17@example.com", verificationOtp, "SawaApp")));
        Assert.Contains("غير صالح أو منتهي الصلاحية", ex.Message);
    }

    // 18. Password reset OTP cannot verify email
    [Fact]
    public async Task Scenario18_PasswordResetOtp_CannotVerifyEmail()
    {
        // First create user
        var (createSuccess, userId, _) = await _identityService.CreateUserAsync("parent_test18@example.com", "Password123!", "Test Parent", UserRole.Parent);
        Assert.True(createSuccess);

        // Generate password reset token
        var resetToken = PasswordResetToken.Create(userId, "parent_test18@example.com", "888888");
        _dbContext.Add(resetToken);
        await _dbContext.SaveChangesAsync();

        // Attempt to verify email using reset OTP
        var verifyHandler = _serviceProvider.GetRequiredService<VerifyEmailHandler>();
        var ex = await Assert.ThrowsAsync<BadRequestException>(() =>
            verifyHandler.HandleAsync(new VerifyEmailRequest("parent_test18@example.com", "888888", "SawaApp")));
        Assert.Contains("لم يتم العثور على رمز تحقق فعال", ex.Message);
    }

    // 19. Unverified login -> 403 EmailNotConfirmedException
    [Fact]
    public async Task Scenario19_UnverifiedLogin_ThrowsEmailNotConfirmedException()
    {
        var handler = _serviceProvider.GetRequiredService<RegisterParentHandler>();
        await handler.HandleAsync(new RegisterParentRequest("parent_test19@example.com", "Password123!", "Test Parent", "+1234567890"));

        var loginHandler = _serviceProvider.GetRequiredService<LoginHandler>();
        var loginRequest = new LoginRequest("parent_test19@example.com", "Password123!");

        var ex = await Assert.ThrowsAsync<EmailNotConfirmedException>(() => loginHandler.HandleAsync(loginRequest));
        Assert.Equal("parent_test19@example.com", ex.Email);
    }

    // 20. Verified login -> success
    [Fact]
    public async Task Scenario20_VerifiedLogin_Succeeds()
    {
        var handler = _serviceProvider.GetRequiredService<RegisterParentHandler>();
        await handler.HandleAsync(new RegisterParentRequest("parent_test20@example.com", "Password123!", "Test Parent", "+1234567890"));

        var sentOtp = _emailService.SentVerificationEmails[0].OtpCode;
        var verifyHandler = _serviceProvider.GetRequiredService<VerifyEmailHandler>();
        await verifyHandler.HandleAsync(new VerifyEmailRequest("parent_test20@example.com", sentOtp, "SawaApp"));

        var loginHandler = _serviceProvider.GetRequiredService<LoginHandler>();
        var loginResponse = await loginHandler.HandleAsync(new LoginRequest("parent_test20@example.com", "Password123!"));

        Assert.NotNull(loginResponse.Token);
        Assert.Equal("parent_test20@example.com", loginResponse.User.Email);
    }

    // 21. Google Parent does not require verification OTP
    [Fact]
    public async Task Scenario21_GoogleParent_DoesNotRequireVerificationOtp()
    {
        var (success, userId, _) = await _identityService.CreateUserAsync(
            "google_parent@example.com",
            Guid.NewGuid().ToString("N") + "Aa1!",
            "Google User",
            UserRole.Parent);
        Assert.True(success);

        // Confirm email as Google authentication does
        await _identityService.ConfirmEmailAsync(userId);

        var isConfirmed = await _identityService.IsEmailConfirmedAsync("google_parent@example.com");
        Assert.True(isConfirmed);

        // No verification token created
        var tokens = await _dbContext.EmailVerificationTokens.Where(t => t.UserId == userId).ToListAsync();
        Assert.Empty(tokens);
    }

    // 22. Verification never creates duplicate user
    [Fact]
    public async Task Scenario22_VerificationNeverCreatesDuplicateUser()
    {
        var handler = _serviceProvider.GetRequiredService<RegisterParentHandler>();
        await handler.HandleAsync(new RegisterParentRequest("parent_test22@example.com", "Password123!", "Test Parent", "+1234567890"));

        var sentOtp = _emailService.SentVerificationEmails[0].OtpCode;
        var verifyHandler = _serviceProvider.GetRequiredService<VerifyEmailHandler>();
        await verifyHandler.HandleAsync(new VerifyEmailRequest("parent_test22@example.com", sentOtp, "SawaApp"));

        var users = await _userManager.Users.Where(u => u.Email == "parent_test22@example.com").ToListAsync();
        Assert.Single(users);
    }

    // 23. Existing platform-aware registration conflicts remain correct
    [Fact]
    public async Task Scenario23_PlatformAwareRegistrationConflicts_RemainCorrect()
    {
        var parentHandler = _serviceProvider.GetRequiredService<RegisterParentHandler>();
        await parentHandler.HandleAsync(new RegisterParentRequest("cross_test23@example.com", "Password123!", "Test Parent", "+1234567890"));

        var doctorHandler = _serviceProvider.GetRequiredService<RegisterDoctorHandler>();
        var ex = await Assert.ThrowsAsync<ConflictException>(() =>
            doctorHandler.HandleAsync(new RegisterDoctorRequest("cross_test23@example.com", "Password123!", "Dr. Cross", "+1234567891", "Pediatrics", "LIC12345")));

        Assert.Contains("هذا البريد الإلكتروني مسجل بالفعل على SAWA APP", ex.Message);
    }

    // 24. Brevo verification email method is invoked
    [Fact]
    public async Task Scenario24_BrevoVerificationEmailMethod_IsInvoked()
    {
        var handler = _serviceProvider.GetRequiredService<RegisterParentHandler>();
        await handler.HandleAsync(new RegisterParentRequest("parent_test24@example.com", "Password123!", "Test Parent", "+1234567890"));

        Assert.Single(_emailService.SentVerificationEmails);
        Assert.Equal("parent_test24@example.com", _emailService.SentVerificationEmails[0].ToEmail);
        Assert.Equal(ClientPlatform.SawaApp, _emailService.SentVerificationEmails[0].Platform);
        Assert.Equal(6, _emailService.SentVerificationEmails[0].OtpCode.Length);
    }

    // 25. Email sending failure does not mark EmailConfirmed=true
    [Fact]
    public async Task Scenario25_EmailSendingFailure_DoesNotMarkEmailConfirmedTrue()
    {
        // Use a service provider with failing email service
        var services = new ServiceCollection();
        services.AddLogging();
        services.AddDbContext<ApplicationDbContext>(opt => opt.UseInMemoryDatabase(Guid.NewGuid().ToString()));
        services.AddScoped<IApplicationDbContext>(sp => sp.GetRequiredService<ApplicationDbContext>());
        services.AddIdentity<ApplicationUser, IdentityRole<Guid>>()
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

        var failingEmailService = new FailingEmailService();
        services.AddSingleton<IEmailService>(failingEmailService);
        services.AddHttpContextAccessor();
        services.AddScoped<ICurrentUserService, CurrentUserService>();
        services.AddApplicationServices();

        using var sp = services.BuildServiceProvider();
        var handler = sp.GetRequiredService<RegisterParentHandler>();
        var userManager = sp.GetRequiredService<UserManager<ApplicationUser>>();

        var ex = await Assert.ThrowsAsync<BadRequestException>(() =>
            handler.HandleAsync(new RegisterParentRequest("fail_test25@example.com", "Password123!", "Test", "+1234567890")));
        Assert.Contains("تعذر إرسال رمز التحقق", ex.Message);

        var user = await userManager.FindByEmailAsync("fail_test25@example.com");
        Assert.NotNull(user);
        Assert.False(user.EmailConfirmed);
    }

    // 26. No more than one active verification OTP exists
    [Fact]
    public async Task Scenario26_NoMoreThanOneActiveVerificationOtp_Exists()
    {
        var handler = _serviceProvider.GetRequiredService<RegisterParentHandler>();
        await handler.HandleAsync(new RegisterParentRequest("parent_test26@example.com", "Password123!", "Test Parent", "+1234567890"));

        var user = await _userManager.FindByEmailAsync("parent_test26@example.com");
        var token = await _dbContext.EmailVerificationTokens.FirstAsync(t => t.UserId == user!.Id);

        // Bypass cooldown to test invalidation logic
        typeof(EmailVerificationToken).GetProperty("LastRequestedAtUtc")!
            .SetValue(token, DateTime.UtcNow.AddSeconds(-65));
        await _dbContext.SaveChangesAsync();

        var sendOtpHandler = _serviceProvider.GetRequiredService<SendVerificationOtpHandler>();
        await sendOtpHandler.HandleAsync(new SendVerificationOtpRequest("parent_test26@example.com", "SawaApp"));

        var activeCount = await _dbContext.EmailVerificationTokens
            .CountAsync(t => t.UserId == user!.Id && t.Platform == ClientPlatform.SawaApp && t.IsActive);
        Assert.Equal(1, activeCount);
    }

    // 27. Resend after cooldown works
    [Fact]
    public async Task Scenario27_ResendAfterCooldown_Works()
    {
        var handler = _serviceProvider.GetRequiredService<RegisterParentHandler>();
        await handler.HandleAsync(new RegisterParentRequest("parent_test27@example.com", "Password123!", "Test Parent", "+1234567890"));

        var user = await _userManager.FindByEmailAsync("parent_test27@example.com");
        var token = await _dbContext.EmailVerificationTokens.FirstAsync(t => t.UserId == user!.Id);

        typeof(EmailVerificationToken).GetProperty("LastRequestedAtUtc")!
            .SetValue(token, DateTime.UtcNow.AddSeconds(-65));
        await _dbContext.SaveChangesAsync();

        var sendOtpHandler = _serviceProvider.GetRequiredService<SendVerificationOtpHandler>();
        var response = await sendOtpHandler.HandleAsync(new SendVerificationOtpRequest("parent_test27@example.com", "SawaApp"));

        Assert.True(response.Succeeded);
        Assert.Equal(2, _emailService.SentVerificationEmails.Count);
    }

    // 28. Platform mismatch is enforced server-side
    [Fact]
    public async Task Scenario28_PlatformMismatch_EnforcedServerSide()
    {
        var parentHandler = _serviceProvider.GetRequiredService<RegisterParentHandler>();
        await parentHandler.HandleAsync(new RegisterParentRequest("parent_test28@example.com", "Password123!", "Test Parent", "+1234567890"));

        var sendOtpHandler = _serviceProvider.GetRequiredService<SendVerificationOtpHandler>();
        var ex = await Assert.ThrowsAsync<ForbiddenException>(() =>
            sendOtpHandler.HandleAsync(new SendVerificationOtpRequest("parent_test28@example.com", "DoctorDashboard")));

        Assert.Contains("لا يمكن تأكيد حساب ولي الأمر عبر لوحة تحكم الطبيب", ex.Message);
    }

    private class FailingEmailService : IEmailService
    {
        public Task SendPasswordResetOtpAsync(string toEmail, string otpCode, int expiryMinutes, CancellationToken cancellationToken = default)
            => throw new InvalidOperationException("SMTP connection failed.");

        public Task SendEmailVerificationOtpAsync(string toEmail, string otpCode, int expiryMinutes, ClientPlatform platform, CancellationToken cancellationToken = default)
            => throw new InvalidOperationException("SMTP connection failed.");
    }
}
