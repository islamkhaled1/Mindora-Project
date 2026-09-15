import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/env_config.dart';
import '../errors/api_exception.dart';
import '../storage/secure_storage_service.dart';
import 'interceptors/auth_interceptor.dart';

/// Centralized HTTP client wrapping Dio for all API interactions in Sawa.
///
/// Features:
/// - Environment-aware base URL resolution (Android Emulator, iOS, LAN, etc.)
/// - Automatic Bearer token authentication via [AuthInterceptor]
/// - Automatic 401 handling and session teardown
/// - Standardized [ApiException] conversion with RFC 7807 ProblemDetails parsing
/// - Safe debug logging that excludes sensitive headers and authentication secrets
class ApiClient {
  final Dio _dio;
  final SecureStorageService _storage;

  ApiClient({
    Dio? dio,
    SecureStorageService? storage,
  })  : _storage = storage ?? SecureStorageService(),
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: EnvConfig.baseUrl,
                connectTimeout: EnvConfig.connectTimeout,
                receiveTimeout: EnvConfig.receiveTimeout,
                sendTimeout: EnvConfig.sendTimeout,
                headers: {
                  'Accept': 'application/json',
                  'X-Client-Platform': 'SawaApp',
                },
              ),
            ) {
    _dio.interceptors.add(AuthInterceptor(storage: _storage));

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestBody: false, // Never log request bodies to protect passwords/PII
          requestHeader: false, // Never log headers to protect Bearer JWTs
          responseBody: false, // Avoid dumping large or sensitive response payloads
          responseHeader: false,
          error: true,
        ),
      );
    }
  }

  /// Direct access to underlying Dio instance if needed for advanced configurations.
  Dio get dio => _dio;

  /// Access to the secure storage service.
  SecureStorageService get storage => _storage;

  /// Updates the base URL at runtime (e.g. when connecting to a custom LAN IP).
  void updateBaseUrl(String newUrl) {
    EnvConfig.overrideBaseUrl(newUrl);
    _dio.options.baseUrl = EnvConfig.baseUrl;
  }

  /// Standard HTTP GET request.
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Standard HTTP POST request.
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Standard HTTP PUT request.
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Standard HTTP DELETE request.
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
