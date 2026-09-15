import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/core/constants/api_endpoints.dart';
import 'package:sawa/core/models/auth_requests.dart';
import 'package:sawa/core/network/api_client.dart';
import 'package:sawa/core/services/auth_service.dart';
import 'package:sawa/core/state/auth_state.dart';
import 'package:sawa/core/storage/secure_storage_service.dart';

class _MockHttpClientAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;

  _MockHttpClientAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

class _MockSecureStorageService extends SecureStorageService {
  final Map<String, String> _inMemory = {};

  @override
  Future<void> saveAuthToken({required String token, String? expiresAtUtc}) async {
    _inMemory['auth_token'] = token;
    if (expiresAtUtc != null) _inMemory['token_expiry'] = expiresAtUtc;
  }

  @override
  Future<void> saveUserInfo({
    required String userId,
    required String email,
    required String role,
  }) async {
    _inMemory['user_id'] = userId;
    _inMemory['user_email'] = email;
    _inMemory['user_role'] = role;
  }

  @override
  Future<String?> getAuthToken() async => _inMemory['auth_token'];

  @override
  Future<bool> hasValidToken() async => _inMemory.containsKey('auth_token');

  @override
  Future<void> clearAuth() async {
    _inMemory.clear();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Email Verification Tests for SAWA Flutter App', () {
    test('sendVerificationOtp calls POST /api/auth/send-verification-otp with SawaApp platform', () async {
      RequestOptions? capturedOptions;

      final dio = Dio(BaseOptions(baseUrl: 'http://test'));
      dio.httpClientAdapter = _MockHttpClientAdapter((options) async {
        capturedOptions = options;
        return ResponseBody.fromString(
          jsonEncode({
            'succeeded': true,
            'message': 'تم إرسال رمز التحقق بنجاح إلى بريدك الإلكتروني.',
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final apiClient = ApiClient(dio: dio);
      final storage = _MockSecureStorageService();
      final authService = AuthService(apiClient: apiClient, storage: storage);

      final result = await authService.sendVerificationOtp('parent@example.com');

      expect(result, contains('تم إرسال رمز التحقق بنجاح'));
      expect(capturedOptions, isNotNull);
      expect(capturedOptions!.path, equals(ApiEndpoints.sendVerificationOtp));
      expect(capturedOptions!.data['email'], equals('parent@example.com'));
      expect(capturedOptions!.data['platform'], equals('SawaApp'));
    });

    test('verifyEmail calls POST /api/auth/verify-email and persists JWT on success', () async {
      RequestOptions? capturedOptions;

      final dio = Dio(BaseOptions(baseUrl: 'http://test'));
      dio.httpClientAdapter = _MockHttpClientAdapter((options) async {
        capturedOptions = options;
        return ResponseBody.fromString(
          jsonEncode({
            'succeeded': true,
            'message': 'تم تأكيد البريد الإلكتروني بنجاح.',
            'token': 'jwt-verified-parent-token-12345',
            'expiresAtUtc': '2026-09-20T12:00:00Z',
            'user': {
              'id': '11111111-2222-3333-4444-555555555555',
              'email': 'parent@example.com',
              'fullName': 'Test Parent',
              'role': 'Parent',
              'profileId': '66666666-7777-8888-9999-000000000000',
            },
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final apiClient = ApiClient(dio: dio);
      final storage = _MockSecureStorageService();
      final authService = AuthService(apiClient: apiClient, storage: storage);

      final response = await authService.verifyEmail('parent@example.com', '123456');

      expect(response.hasToken, isTrue);
      expect(response.token, equals('jwt-verified-parent-token-12345'));
      expect(response.user.role, equals('Parent'));

      expect(await storage.getAuthToken(), equals('jwt-verified-parent-token-12345'));
      expect(await storage.hasValidToken(), isTrue);

      expect(capturedOptions, isNotNull);
      expect(capturedOptions!.path, equals(ApiEndpoints.verifyEmail));
      expect(capturedOptions!.data['email'], equals('parent@example.com'));
      expect(capturedOptions!.data['otp'], equals('123456'));
      expect(capturedOptions!.data['platform'], equals('SawaApp'));
    });

    test('AuthState registerParent with requiresEmailVerification does not authenticate user immediately', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test'));
      dio.httpClientAdapter = _MockHttpClientAdapter((options) async {
        return ResponseBody.fromString(
          jsonEncode({
            'token': null,
            'expiresAtUtc': null,
            'requiresEmailVerification': true,
            'user': {
              'id': '11111111-2222-3333-4444-555555555555',
              'email': 'newparent@example.com',
              'fullName': 'New Parent',
              'role': 'Parent',
              'profileId': '66666666-7777-8888-9999-000000000000',
            },
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final apiClient = ApiClient(dio: dio);
      final storage = _MockSecureStorageService();
      final authService = AuthService(apiClient: apiClient, storage: storage);
      final authState = AuthState(authService: authService);

      const request = RegisterParentRequest(
        fullName: 'New Parent',
        email: 'newparent@example.com',
        password: 'Password123!',
      );

      final response = await authState.registerParent(request);

      expect(response.requiresEmailVerification, isTrue);
      expect(response.hasToken, isFalse);
      expect(authState.isAuthenticated, isFalse);
      expect(authState.currentUser, isNull);
    });

    test('AuthState verifyEmail establishes authenticated session upon success', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test'));
      dio.httpClientAdapter = _MockHttpClientAdapter((options) async {
        return ResponseBody.fromString(
          jsonEncode({
            'succeeded': true,
            'message': 'تم تأكيد البريد الإلكتروني بنجاح.',
            'token': 'jwt-verified-token',
            'expiresAtUtc': '2026-09-20T12:00:00Z',
            'user': {
              'id': '11111111-2222-3333-4444-555555555555',
              'email': 'newparent@example.com',
              'fullName': 'New Parent',
              'role': 'Parent',
              'profileId': '66666666-7777-8888-9999-000000000000',
            },
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final apiClient = ApiClient(dio: dio);
      final storage = _MockSecureStorageService();
      final authService = AuthService(apiClient: apiClient, storage: storage);
      final authState = AuthState(authService: authService);

      final response = await authState.verifyEmail('newparent@example.com', '654321');

      expect(response.hasToken, isTrue);
      expect(authState.isAuthenticated, isTrue);
      expect(authState.currentUser, isNotNull);
      expect(authState.currentUser!.email, equals('newparent@example.com'));
      expect(authState.currentUser!.role, equals('Parent'));
    });
  });
}
