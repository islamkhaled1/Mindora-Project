using FluentValidation;
using Mindora.Application.Common.Exceptions;
using Mindora.Application.Common.Interfaces;
using Mindora.Application.Common.Validation;

namespace Mindora.Application.Features.Auth.ChangePassword;

public class ChangePasswordHandler
{
    private readonly IIdentityService _identityService;
    private readonly ICurrentUserService _currentUserService;
    private readonly IValidator<ChangePasswordRequest> _validator;

    public ChangePasswordHandler(
        IIdentityService identityService,
        ICurrentUserService currentUserService,
        IValidator<ChangePasswordRequest> validator)
    {
        _identityService = identityService;
        _currentUserService = currentUserService;
        _validator = validator;
    }

    public async Task<ChangePasswordResponseDto> HandleAsync(
        ChangePasswordRequest request,
        CancellationToken cancellationToken = default)
    {
        await _validator.ValidateAndThrowAppAsync(request, cancellationToken);

        var currentUserId = _currentUserService.UserId;
        if (!currentUserId.HasValue || currentUserId.Value == Guid.Empty)
        {
            throw new UnauthorizedException("المستخدم غير مصرح له بتنفيذ هذه العملية.");
        }

        var (succeeded, errors) = await _identityService.ChangePasswordAsync(
            currentUserId.Value,
            request.CurrentPassword,
            request.NewPassword,
            cancellationToken);

        if (!succeeded)
        {
            var firstError = errors.FirstOrDefault() ?? "كلمة المرور الحالية غير صحيحة أو كلمة المرور الجديدة لا تستوفي الشروط.";
            throw new BadRequestException(firstError);
        }

        return new ChangePasswordResponseDto("تم تغيير كلمة المرور بنجاح.");
    }
}
