import 'package:flutter/foundation.dart';
import '../errors/api_exception.dart';
import '../models/auth_requests.dart';
import '../models/auth_response_model.dart';
import '../network/interceptors/auth_interceptor.dart';
import '../services/auth_service.dart';

/// Lightweight application-level authentication state using built-in ChangeNotifier.
///
/// Manages current user session, authentication status, loading flags,
/// and reactive logout upon 401 Unauthorized responses.
class AuthState extends ChangeNotifier {
  static AuthState? _instance;

  /// Global singleton accessor for lightweight access across screens.
  static AuthState get instance => _instance ??= AuthState();

  final AuthService _authService;
  void Function()? _unauthorizedSubscription;

  CurrentUserModel? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;

  AuthState({AuthService? authService})
      : _authService = authService ?? AuthService() {
    // Automatically reset auth state when any request receives 401 Unauthorized
    _unauthorizedSubscription = AuthInterceptor.onUnauthorized(() {
      _isAuthenticated = false;
      _currentUser = null;
      notifyListeners();
    });
  }

  CurrentUserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AuthService get authService => _authService;

  /// Initializes auth state on startup by validating any existing JWT session.
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final hasToken = await _authService.isAuthenticated();
      if (hasToken) {
        _currentUser = await _authService.getMe();
        _isAuthenticated = true;
      } else {
        _isAuthenticated = false;
        _currentUser = null;
      }
    } catch (_) {
      // In case token is invalid, expired, or network is unavailable
      _isAuthenticated = false;
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logs in a parent user and establishes session state.
  Future<AuthResponseModel> login(LoginRequest request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.login(request);
      if (response.hasToken) {
        _currentUser = CurrentUserModel(
          userId: response.user.id,
          email: response.user.email,
          fullName: response.user.fullName,
          role: response.user.role,
          profileId: response.user.profileId,
        );
        _isAuthenticated = true;
      }
      _isLoading = false;
      notifyListeners();
      return response;
    } on ApiException catch (e) {
      _errorMessage = e.firstErrorMessage;
      _isLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Logs in a parent user using a verified Google ID token.
  Future<AuthResponseModel> loginWithGoogle(String idToken) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.loginWithGoogle(idToken);
      if (response.hasToken) {
        _currentUser = CurrentUserModel(
          userId: response.user.id,
          email: response.user.email,
          fullName: response.user.fullName,
          role: response.user.role,
          profileId: response.user.profileId,
        );
        _isAuthenticated = true;
      }
      _isLoading = false;
      notifyListeners();
      return response;
    } on ApiException catch (e) {
      _errorMessage = e.firstErrorMessage;
      _isLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Registers a new parent and establishes session state if verified immediately,
  /// or returns verification requirement.
  Future<AuthResponseModel> registerParent(RegisterParentRequest request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.registerParent(request);
      if (response.requiresEmailVerification) {
        _isAuthenticated = false;
        _currentUser = null;
      } else if (response.hasToken) {
        _currentUser = CurrentUserModel(
          userId: response.user.id,
          email: response.user.email,
          fullName: response.user.fullName,
          role: response.user.role,
          profileId: response.user.profileId,
        );
        _isAuthenticated = true;
      }
      _isLoading = false;
      notifyListeners();
      return response;
    } on ApiException catch (e) {
      _errorMessage = e.firstErrorMessage;
      _isLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Verifies email OTP, establishes authenticated session, and updates state.
  Future<AuthResponseModel> verifyEmail(String email, String otp) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.verifyEmail(email, otp);
      if (response.hasToken) {
        _currentUser = CurrentUserModel(
          userId: response.user.id,
          email: response.user.email,
          fullName: response.user.fullName,
          role: response.user.role,
          profileId: response.user.profileId,
        );
        _isAuthenticated = true;
      }
      _isLoading = false;
      notifyListeners();
      return response;
    } on ApiException catch (e) {
      _errorMessage = e.firstErrorMessage;
      _isLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Requests a new email verification OTP.
  Future<String> sendVerificationOtp(String email) async {
    return await _authService.sendVerificationOtp(email);
  }

  /// Logs out the user and clears all local auth session state.
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
    } finally {
      _currentUser = null;
      _isAuthenticated = false;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _unauthorizedSubscription?.call();
    super.dispose();
  }
}
