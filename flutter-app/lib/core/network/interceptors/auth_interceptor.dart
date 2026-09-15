import 'package:dio/dio.dart';
import '../../storage/secure_storage_service.dart';

typedef UnauthorizedCallback = void Function();

/// Dio Interceptor that automatically attaches the JWT Bearer token to outgoing requests
/// and handles 401 Unauthorized responses by clearing auth storage and notifying listeners.
///
/// Ensures tokens and sensitive authentication values are never printed or logged.
class AuthInterceptor extends Interceptor {
  final SecureStorageService _storage;

  AuthInterceptor({required SecureStorageService storage}) : _storage = storage;

  /// Global listeners notified when a 401 Unauthorized occurs.
  static final Set<UnauthorizedCallback> _unauthorizedListeners = {};

  /// Registers a callback to be invoked on 401 Unauthorized.
  /// Returns a function to unsubscribe the listener.
  static void Function() onUnauthorized(UnauthorizedCallback callback) {
    _unauthorizedListeners.add(callback);
    return () => _unauthorizedListeners.remove(callback);
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Check if the request explicitly requested to skip authentication (e.g. login, register)
    final bool skipAuth = options.extra['skipAuth'] == true;

    if (!skipAuth) {
      final token = await _storage.getAuthToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    if (!options.headers.containsKey('Accept')) {
      options.headers['Accept'] = 'application/json';
    }

    if (!options.headers.containsKey('Content-Type') && options.data is! FormData) {
      options.headers['Content-Type'] = 'application/json';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Clear stored auth credentials upon session expiry
      await _storage.clearAuth();

      // Notify all registered listeners
      for (final listener in _unauthorizedListeners) {
        try {
          listener();
        } catch (_) {
          // Prevent listener exceptions from breaking the interceptor chain
        }
      }
    }

    handler.next(err);
  }
}
