using FluentValidation;
using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Common.Validation;
using Mindora.Application.Features.Auth.Models;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Auth.RegisterDoctor;

public class RegisterDoctorHandler
{
    private readonly IIdentityService _identityService;
    private readonly IApplicationDbContext _dbContext;
    private readonly IEmailService? _emailService;
    private readonly IValidator<RegisterDoctorRequest> _validator;

    public RegisterDoctorHandler(
        IIdentityService identityService,
        IApplicationDbContext dbContext,
        IValidator<RegisterDoctorRequest> validator,
        IEmailService? emailService = null)
    {
        _identityService = identityService;
        _dbContext = dbContext;
        _validator = validator;
        _emailService = emailService;
    }

    public async Task<AuthResponseDto> HandleAsync(RegisterDoctorRequest request, CancellationToken cancellationToken = default)
    {
        await _validator.ValidateAndThrowAppAsync(request, cancellationToken);

        var trimmedEmail = request.Email.Trim();
        request = request with { Email = trimmedEmail };

        var existingUser = await _identityService.GetUserByEmailAsync(trimmedEmail, cancellationToken);
        if (existingUser != null)
        {
            if (existingUser.Value.Role == UserRole.Parent)
            {
                throw new ConflictException("هذا البريد الإلكتروني مسجل بالفعل على SAWA APP.");
            }
            if (existingUser.Value.Role == UserRole.Doctor)
            {
                throw new ConflictException("هذا البريد الإلكتروني مسجل بالفعل على لوحة تحكم الطبيب.");
            }
            throw new ConflictException("هذا البريد الإلكتروني مسجل بالفعل في المنصة، يرجى تسجيل الدخول أو استخدام بريد آخر.");
        }

        if (await _identityService.UserExistsAsync(trimmedEmail, cancellationToken))
        {
            throw new ConflictException("هذا البريد الإلكتروني مسجل بالفعل في المنصة، يرجى تسجيل الدخول أو استخدام بريد آخر.");
        }

        var (succeeded, userId, errors) = await _identityService.CreateUserAsync(
            request.Email,
            request.Password,
            request.FullName,
            UserRole.Doctor,
            cancellationToken);

        if (!succeeded)
        {
            throw new Mindora.Application.Common.Exceptions.ValidationException("Registration", string.Join(" ", errors));
        }

        DoctorGender? parsedGender = null;
        if (!string.IsNullOrWhiteSpace(request.Gender) &&
            Enum.TryParse<DoctorGender>(request.Gender.Trim(), true, out var genderVal))
        {
            parsedGender = genderVal;
        }

        var profile = DoctorProfile.Create(
            userId,
            request.Specialization,
            request.ClinicName,
            request.LicenseNumber,
            gender: parsedGender);

        _dbContext.Add(profile);

        // Generate and persist verification OTP
        var otp = EmailVerificationToken.GenerateOtp();
        var verificationToken = EmailVerificationToken.Create(
            userId,
            request.Email,
            ClientPlatform.DoctorDashboard,
            otp);

        _dbContext.Add(verificationToken);
        await _dbContext.SaveChangesAsync(cancellationToken);

        // Send OTP email via Brevo SMTP
        if (_emailService != null)
        {
            try
            {
                await _emailService.SendEmailVerificationOtpAsync(
                    request.Email,
                    otp,
                    EmailVerificationToken.DefaultOtpValidityMinutes,
                    ClientPlatform.DoctorDashboard,
                    cancellationToken);
            }
            catch (Exception)
            {
                throw new BadRequestException("تم إنشاء الحساب ولكن تعذر إرسال رمز التحقق حالياً. يرجى طلب إعادة إرسال الرمز.");
            }
        }

        return new AuthResponseDto(
            Token: null,
            ExpiresAtUtc: null,
            User: new AuthUserDto(userId, request.Email, request.FullName, UserRole.Doctor.ToString(), profile.Id),
            RequiresEmailVerification: true,
            Message: "تم إنشاء الحساب بنجاح. يرجى تأكيد البريد الإلكتروني عبر رمز التحقق (OTP) المرسل إليك.");
    }
}
