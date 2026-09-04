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
    private readonly IJwtTokenService _jwtTokenService;
    private readonly IValidator<RegisterParentRequest> _validator;

    public RegisterParentHandler(
        IIdentityService identityService,
        IApplicationDbContext dbContext,
        IJwtTokenService jwtTokenService,
        IValidator<RegisterParentRequest> validator)
    {
        _identityService = identityService;
        _dbContext = dbContext;
        _jwtTokenService = jwtTokenService;
        _validator = validator;
    }

    public async Task<AuthResponseDto> HandleAsync(RegisterParentRequest request, CancellationToken cancellationToken = default)
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
            UserRole.Parent,
            cancellationToken);

        if (!succeeded)
        {
            throw new Mindora.Application.Common.Exceptions.ValidationException("Registration", string.Join(" ", errors));
        }

        var profile = ParentProfile.Create(userId, request.PhoneNumber);
        _dbContext.Add(profile);
        await _dbContext.SaveChangesAsync(cancellationToken);

        var tokenResult = _jwtTokenService.GenerateToken(
            userId,
            request.Email,
            request.FullName,
            UserRole.Parent,
            profile.Id);

        return new AuthResponseDto(
            tokenResult.Token,
            tokenResult.ExpiresAtUtc,
            new AuthUserDto(userId, request.Email, request.FullName, UserRole.Parent.ToString(), profile.Id));
    }
}
