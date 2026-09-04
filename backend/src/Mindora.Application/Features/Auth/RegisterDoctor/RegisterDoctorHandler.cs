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
    private readonly IJwtTokenService _jwtTokenService;
    private readonly IValidator<RegisterDoctorRequest> _validator;

    public RegisterDoctorHandler(
        IIdentityService identityService,
        IApplicationDbContext dbContext,
        IJwtTokenService jwtTokenService,
        IValidator<RegisterDoctorRequest> validator)
    {
        _identityService = identityService;
        _dbContext = dbContext;
        _jwtTokenService = jwtTokenService;
        _validator = validator;
    }

    public async Task<AuthResponseDto> HandleAsync(RegisterDoctorRequest request, CancellationToken cancellationToken = default)
    {
        await _validator.ValidateAndThrowAppAsync(request, cancellationToken);

        if (await _identityService.UserExistsAsync(request.Email, cancellationToken))
        {
            throw new ConflictException("A user with this email address already exists.");
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

        var profile = DoctorProfile.Create(
            userId,
            request.Specialization,
            request.ClinicName,
            request.LicenseNumber);

        _dbContext.Add(profile);
        await _dbContext.SaveChangesAsync(cancellationToken);

        var tokenResult = _jwtTokenService.GenerateToken(
            userId,
            request.Email,
            request.FullName,
            UserRole.Doctor,
            profile.Id);

        return new AuthResponseDto(
            tokenResult.Token,
            tokenResult.ExpiresAtUtc,
            new AuthUserDto(userId, request.Email, request.FullName, UserRole.Doctor.ToString(), profile.Id));
    }
}
