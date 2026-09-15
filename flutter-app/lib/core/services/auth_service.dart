import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../models/auth_requests.dart';
import '../models/auth_response_model.dart';
import '../network/api_client.dart';
import '../storage/secure_storage_service.dart';

/// Service handling authentication operations with the ASP.NET Core backend.
class AuthService {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  AuthService({
    ApiClient? apiClient,
    SecureStorageService? storage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _storage = storage ?? SecureStorageService();

  SecureStorageService get storage => _storage;
  ApiClient get apiClient => _apiClient;

  /// Authenticates a parent user with email and password.
  /// Persists JWT and session info upon success.
  Future<AuthResponseModel> login(LoginRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      data: request.toJson(),
      options: Options(extra: {'skipAuth': true}),
    );

    final authResponse = AuthResponseModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );

    if (authResponse.hasToken) {
      await _storage.saveAuthToken(
        token: authResponse.token,
        expiresAtUtc: authResponse.expiresAtUtc?.toIso8601String(),
      );
      await _storage.saveUserInfo(
        userId: authResponse.user.id,
        email: authResponse.user.email,
        role: authResponse.user.role,
      );
    }

    return authResponse;
  }

  /// Authenticates a parent user with a verified Google ID Token.
  /// Server validates token and returns standard Mindora JWT.
  Future<AuthResponseModel> loginWithGoogle(String idToken) async {
    final response = await _apiClient.post(
      ApiEndpoints.googleLogin,
      data: {'idToken': idToken},
      options: Options(extra: {'skipAuth': true}),
    );

    final authResponse = AuthResponseModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );

    if (authResponse.hasToken) {
      await _storage.saveAuthToken(
        token: authResponse.token,
        expiresAtUtc: authResponse.expiresAtUtc?.toIso8601String(),
      );
      await _storage.saveUserInfo(
        userId: authResponse.user.id,
        email: authResponse.user.email,
        role: authResponse.user.role,
      );
    }

    return authResponse;
  }

  /// Registers a new parent account.
  /// Persists JWT and session info if returned directly, or signals verification requirement.
  Future<AuthResponseModel> registerParent(RegisterParentRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.registerParent,
      data: request.toJson(),
      options: Options(extra: {'skipAuth': true}),
    );

    final authResponse = AuthResponseModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );

    if (authResponse.hasToken) {
      await _storage.saveAuthToken(
        token: authResponse.token,
        expiresAtUtc: authResponse.expiresAtUtc?.toIso8601String(),
      );
      await _storage.saveUserInfo(
        userId: authResponse.user.id,
        email: authResponse.user.email,
        role: authResponse.user.role,
      );
    }

    return authResponse;
  }

  /// Fetches the currently authenticated user's profile and verifies token validity.
  Future<CurrentUserModel> getMe() async {
    final response = await _apiClient.get(ApiEndpoints.getMe);

    final currentUser = CurrentUserModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );

    await _storage.saveUserInfo(
      userId: currentUser.userId,
      email: currentUser.email,
      role: currentUser.role,
    );

    return currentUser;
  }

  /// Clears stored authentication credentials and active child context.
  Future<void> logout() async {
    await _storage.clearAuth();
  }

  /// Checks if an authentication token exists in secure storage.
  Future<bool> isAuthenticated() async {
    return await _storage.hasValidToken();
  }

  /// Initiates password recovery by requesting an OTP sent to the registered email.
  Future<ForgotPasswordResponseModel> forgotPassword(String email) async {
    final response = await _apiClient.post(
      ApiEndpoints.forgotPassword,
      data: {
        'email': email.trim(),
        'platform': 'SawaApp',
      },
      options: Options(extra: {'skipAuth': true}),
    );

    final data = Map<String, dynamic>.from(response.data as Map);
    return ForgotPasswordResponseModel.fromJson(data);
  }

  /// Verifies the 6-digit OTP received via email and receives a short-lived single-use reset token.
  Future<String> verifyOtp(String email, String otp) async {
    final response = await _apiClient.post(
      ApiEndpoints.verifyOtp,
      data: {
        'email': email.trim(),
        'otp': otp.trim(),
        'platform': 'SawaApp',
      },
      options: Options(extra: {'skipAuth': true}),
    );

    final data = Map<String, dynamic>.from(response.data as Map);
    return (data['resetToken'] ?? data['ResetToken'] ?? '').toString();
  }

  /// Sets a new password using the verified single-use reset token.
  Future<String> resetPassword({
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.resetPassword,
      data: {
        'resetToken': resetToken.trim(),
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
        'platform': 'SawaApp',
      },
      options: Options(extra: {'skipAuth': true}),
    );

    final data = Map<String, dynamic>.from(response.data as Map);
    return (data['message'] ?? data['Message'] ?? 'تم تحديث كلمة المرور بنجاح').toString();
  }

  /// Changes the password for the currently authenticated user.
  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.changePassword,
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );

    final data = Map<String, dynamic>.from(response.data as Map);
    return (data['message'] ?? data['Message'] ?? 'تم تغيير كلمة المرور بنجاح').toString();
  }

  /// Requests a new 6-digit email verification OTP for Parent registration.
  Future<String> sendVerificationOtp(String email, {String platform = 'SawaApp'}) async {
    final response = await _apiClient.post(
      ApiEndpoints.sendVerificationOtp,
      data: {
        'email': email.trim(),
        'platform': platform,
      },
      options: Options(extra: {'skipAuth': true}),
    );

    final data = Map<String, dynamic>.from(response.data as Map);
    return (data['message'] ?? data['Message'] ?? 'تم إرسال رمز التحقق بنجاح إلى بريدك الإلكتروني.').toString();
  }

  /// Verifies the 6-digit OTP to confirm account email and receive authenticated JWT for Parent.
  Future<AuthResponseModel> verifyEmail(String email, String otp, {String platform = 'SawaApp'}) async {
    final response = await _apiClient.post(
      ApiEndpoints.verifyEmail,
      data: {
        'email': email.trim(),
        'otp': otp.trim(),
        'platform': platform,
      },
      options: Options(extra: {'skipAuth': true}),
    );

    final authResponse = AuthResponseModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );

    if (authResponse.hasToken) {
      await _storage.saveAuthToken(
        token: authResponse.token,
        expiresAtUtc: authResponse.expiresAtUtc?.toIso8601String(),
      );
      await _storage.saveUserInfo(
        userId: authResponse.user.id,
        email: authResponse.user.email,
        role: authResponse.user.role,
      );
    }

    return authResponse;
  }
}
