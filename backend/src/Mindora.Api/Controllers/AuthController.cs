using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Mindora.Application.Features.Auth.GetCurrentUser;
using Mindora.Application.Features.Auth.Login;
using Mindora.Application.Features.Auth.Models;
using Mindora.Application.Features.Auth.RegisterDoctor;
using Mindora.Application.Features.Auth.RegisterParent;

namespace Mindora.Api.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    [HttpPost("register-parent")]
    [ProducesResponseType(typeof(AuthResponseDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> RegisterParent(
        [FromBody] RegisterParentRequest request,
        [FromServices] RegisterParentHandler handler,
        CancellationToken cancellationToken)
    {
        var response = await handler.HandleAsync(request, cancellationToken);
        return StatusCode(StatusCodes.Status201Created, response);
    }

    [HttpPost("register-doctor")]
    [ProducesResponseType(typeof(AuthResponseDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> RegisterDoctor(
        [FromBody] RegisterDoctorRequest request,
        [FromServices] RegisterDoctorHandler handler,
        CancellationToken cancellationToken)
    {
        var response = await handler.HandleAsync(request, cancellationToken);
        return StatusCode(StatusCodes.Status201Created, response);
    }

    [HttpPost("login")]
    [ProducesResponseType(typeof(AuthResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> Login(
        [FromBody] LoginRequest request,
        [FromServices] LoginHandler handler,
        CancellationToken cancellationToken)
    {
        var response = await handler.HandleAsync(request, cancellationToken);
        return Ok(response);
    }

    [HttpPost("google")]
    [ProducesResponseType(typeof(AuthResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> GoogleLogin(
        [FromBody] GoogleLoginRequest request,
        [FromServices] GoogleLoginHandler handler,
        CancellationToken cancellationToken)
    {
        var response = await handler.HandleAsync(request, cancellationToken);
        return Ok(response);
    }

    [Authorize]
    [HttpGet("me")]
    [ProducesResponseType(typeof(CurrentUserDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetCurrentUser(
        [FromServices] GetCurrentUserHandler handler,
        CancellationToken cancellationToken)
    {
        var response = await handler.HandleAsync(cancellationToken);
        return Ok(response);
    }

    [HttpPost("forgot-password")]
    [ProducesResponseType(typeof(Mindora.Application.Features.Auth.ForgotPassword.ForgotPasswordResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> ForgotPassword(
        [FromBody] Mindora.Application.Features.Auth.ForgotPassword.ForgotPasswordRequest request,
        [FromServices] Mindora.Application.Features.Auth.ForgotPassword.ForgotPasswordHandler handler,
        [FromHeader(Name = "X-Client-Platform")] string? headerPlatform,
        CancellationToken cancellationToken)
    {
        var effectiveRequest = string.IsNullOrWhiteSpace(request.Platform) && !string.IsNullOrWhiteSpace(headerPlatform)
            ? request with { Platform = headerPlatform }
            : request;
        var response = await handler.HandleAsync(effectiveRequest, cancellationToken);
        return Ok(response);
    }

    [HttpPost("verify-otp")]
    [ProducesResponseType(typeof(Mindora.Application.Features.Auth.VerifyOtp.VerifyOtpResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> VerifyOtp(
        [FromBody] Mindora.Application.Features.Auth.VerifyOtp.VerifyOtpRequest request,
        [FromServices] Mindora.Application.Features.Auth.VerifyOtp.VerifyOtpHandler handler,
        [FromHeader(Name = "X-Client-Platform")] string? headerPlatform,
        CancellationToken cancellationToken)
    {
        var effectiveRequest = string.IsNullOrWhiteSpace(request.Platform) && !string.IsNullOrWhiteSpace(headerPlatform)
            ? request with { Platform = headerPlatform }
            : request;
        var response = await handler.HandleAsync(effectiveRequest, cancellationToken);
        return Ok(response);
    }

    [HttpPost("reset-password")]
    [ProducesResponseType(typeof(Mindora.Application.Features.Auth.ResetPassword.ResetPasswordResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> ResetPassword(
        [FromBody] Mindora.Application.Features.Auth.ResetPassword.ResetPasswordRequest request,
        [FromServices] Mindora.Application.Features.Auth.ResetPassword.ResetPasswordHandler handler,
        [FromHeader(Name = "X-Client-Platform")] string? headerPlatform,
        CancellationToken cancellationToken)
    {
        var effectiveRequest = string.IsNullOrWhiteSpace(request.Platform) && !string.IsNullOrWhiteSpace(headerPlatform)
            ? request with { Platform = headerPlatform }
            : request;
        var response = await handler.HandleAsync(effectiveRequest, cancellationToken);
        return Ok(response);
    }

    [Authorize]
    [HttpPost("change-password")]
    [ProducesResponseType(typeof(Mindora.Application.Features.Auth.ChangePassword.ChangePasswordResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> ChangePassword(
        [FromBody] Mindora.Application.Features.Auth.ChangePassword.ChangePasswordRequest request,
        [FromServices] Mindora.Application.Features.Auth.ChangePassword.ChangePasswordHandler handler,
        CancellationToken cancellationToken)
    {
        var response = await handler.HandleAsync(request, cancellationToken);
        return Ok(response);
    }

    [HttpPost("send-verification-otp")]
    [ProducesResponseType(typeof(Mindora.Application.Features.Auth.SendVerificationOtp.SendVerificationOtpResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> SendVerificationOtp(
        [FromBody] Mindora.Application.Features.Auth.SendVerificationOtp.SendVerificationOtpRequest request,
        [FromServices] Mindora.Application.Features.Auth.SendVerificationOtp.SendVerificationOtpHandler handler,
        [FromHeader(Name = "X-Client-Platform")] string? headerPlatform,
        CancellationToken cancellationToken)
    {
        var effectiveRequest = string.IsNullOrWhiteSpace(request.Platform) && !string.IsNullOrWhiteSpace(headerPlatform)
            ? request with { Platform = headerPlatform }
            : request;
        var response = await handler.HandleAsync(effectiveRequest, cancellationToken);
        return Ok(response);
    }

    [HttpPost("verify-email")]
    [ProducesResponseType(typeof(Mindora.Application.Features.Auth.VerifyEmail.VerifyEmailResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> VerifyEmail(
        [FromBody] Mindora.Application.Features.Auth.VerifyEmail.VerifyEmailRequest request,
        [FromServices] Mindora.Application.Features.Auth.VerifyEmail.VerifyEmailHandler handler,
        [FromHeader(Name = "X-Client-Platform")] string? headerPlatform,
        CancellationToken cancellationToken)
    {
        var effectiveRequest = string.IsNullOrWhiteSpace(request.Platform) && !string.IsNullOrWhiteSpace(headerPlatform)
            ? request with { Platform = headerPlatform }
            : request;
        var response = await handler.HandleAsync(effectiveRequest, cancellationToken);
        return Ok(response);
    }
}
