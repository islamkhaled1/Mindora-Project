using FluentValidation;
using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Common.Validation;
using Mindora.Application.Features.Auth.Models;
using Mindora.Domain.Entities;
using Mindora.Domain.Enums;

namespace Mindora.Application.Features.Auth.RegisterParent;

public class RegisterParentHandler
{
    private readonly IIdentityService _identityService;
    private readonly IApplicationDbContext _dbContext;
    private readonly IEmailService? _emailService;
    private readonly IValidator<RegisterParentRequest> _validator;

    public RegisterParentHandler(
        IIdentityService identityService,
        IApplicationDbContext dbContext,
        IValidator<RegisterParentRequest> validator,
        IEmailService? emailService = null)
    {
        _identityService = identityService;
        _dbContext = dbContext;
        _validator = validator;
        _emailService = emailService;
    }

    public async Task<AuthResponseDto> HandleAsync(RegisterParentRequest request, CancellationToken cancellationToken = default)
    {
        await _validator.ValidateAndThrowAppAsync(request, cancellationToken);

        var existingUser = await _identityService.GetUserByEmailAsync(request.Email, cancellationToken);
        if (existingUser != null)
        {
            if (existingUser.Value.Role == UserRole.Doctor)
            {
                throw new ConflictException("هذا البريد الإلكتروني مسجل بالفعل على لوحة تحكم الطبيب.");
            }
            if (existingUser.Value.Role == UserRole.Parent)
            {
                throw new ConflictException("هذا البريد الإلكتروني مسجل بالفعل على SAWA APP.");
            }
            throw new ConflictException("A user with this email address already exists.");
        }

        var (succeeded, userId, errors) = await _identityService.CreateUserAsync(
            request.Email,
            request.Password,
            request.FullName,
            UserRole.Parent,
            cancellationToken);

        if (!succeeded)
        {
            throw new Mindora.Application.Common.Exceptions.ValidationException("Registration", string.Join(" ", errors));
        }

        var profile = ParentProfile.Create(userId, request.PhoneNumber);
        _dbContext.Add(profile);

        // Generate and persist verification OTP
        var otp = EmailVerificationToken.GenerateOtp();
        var verificationToken = EmailVerificationToken.Create(
            userId,
            request.Email,
            ClientPlatform.SawaApp,
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
                    ClientPlatform.SawaApp,
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
            User: new AuthUserDto(userId, request.Email, request.FullName, UserRole.Parent.ToString(), profile.Id),
            RequiresEmailVerification: true,
            Message: "تم إنشاء الحساب بنجاح. يرجى تأكيد البريد الإلكتروني عبر رمز التحقق (OTP) المرسل إليك.");
    }
}
