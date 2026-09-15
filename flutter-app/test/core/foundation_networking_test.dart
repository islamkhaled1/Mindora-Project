import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:sawa/core/config/env_config.dart';
import 'package:sawa/core/constants/api_endpoints.dart';
import 'package:sawa/core/errors/api_exception.dart';

void main() {
  group('EnvConfig Tests', () {
    tearDown(() {
      // Reset any runtime overrides after each test
      EnvConfig.overrideBaseUrl(null);
    });

    test('defaultPort should be 5222', () {
      expect(EnvConfig.defaultPort, equals(5222));
    });

    test('baseUrl should include default port 5222', () {
      expect(EnvConfig.baseUrl, contains('5222'));
    });

    test('overrideBaseUrl should update baseUrl and strip trailing slash', () {
      EnvConfig.overrideBaseUrl('http://192.168.1.50:5222/');
      expect(EnvConfig.baseUrl, equals('http://192.168.1.50:5222'));

      EnvConfig.overrideBaseUrl('http://api.mindora.com');
      expect(EnvConfig.baseUrl, equals('http://api.mindora.com'));
    });

    test('overrideBaseUrl with null should restore default', () {
      EnvConfig.overrideBaseUrl('http://custom-host:8080');
      expect(EnvConfig.baseUrl, equals('http://custom-host:8080'));

      EnvConfig.overrideBaseUrl(null);
      expect(EnvConfig.baseUrl, contains('5222'));
    });
  });

  group('ApiEndpoints Route Mapping Tests', () {
    test('Auth routes should match ASP.NET Core controllers', () {
      expect(ApiEndpoints.login, equals('/api/auth/login'));
      expect(ApiEndpoints.registerParent, equals('/api/auth/register-parent'));
      expect(ApiEndpoints.registerDoctor, equals('/api/auth/register-doctor'));
      expect(ApiEndpoints.getMe, equals('/api/auth/me'));
    });

    test('Children routes should generate valid GUID URLs', () {
      expect(ApiEndpoints.children, equals('/api/children'));
      expect(
        ApiEndpoints.childById('a1c4efcf-190b-4046-8414-d2b006b2407c'),
        equals('/api/children/a1c4efcf-190b-4046-8414-d2b006b2407c'),
      );
      expect(
        ApiEndpoints.linkDoctorByCode('a1c4efcf-190b-4046-8414-d2b006b2407c'),
        equals('/api/children/a1c4efcf-190b-4046-8414-d2b006b2407c/link-doctor'),
      );
      expect(
        ApiEndpoints.baselineAssessment('a1c4efcf-190b-4046-8414-d2b006b2407c'),
        equals('/api/children/a1c4efcf-190b-4046-8414-d2b006b2407c/baseline-assessment'),
      );
    });

    test('Session and Progress routes should generate valid URLs', () {
      expect(ApiEndpoints.sessions, equals('/api/sessions'));
      expect(
        ApiEndpoints.sessionMetrics('sess-123'),
        equals('/api/sessions/sess-123/metrics'),
      );
      expect(
        ApiEndpoints.completeSession('sess-123'),
        equals('/api/sessions/sess-123/complete'),
      );
      expect(
        ApiEndpoints.childProgress('child-456'),
        equals('/api/children/child-456/progress'),
      );
    });
  });

  group('ApiException Tests', () {
    test('fromDioException should handle connection timeouts with Arabic message', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );

      final apiException = ApiException.fromDioException(dioException);
      expect(apiException.isNetworkError, isTrue);
      expect(apiException.message, contains('انتهت مهلة الاتصال'));
    });

    test('fromDioException should handle 401 Unauthorized', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/children'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/api/children'),
          statusCode: 401,
        ),
      );

      final apiException = ApiException.fromDioException(dioException);
      expect(apiException.statusCode, equals(401));
      expect(apiException.message, contains('انتهت صلاحية الجلسة'));
    });

    test('fromDioException should parse ASP.NET Core ProblemDetails errors dictionary', () {
      final problemDetailsPayload = {
        'type': 'https://tools.ietf.org/html/rfc7231#section-6.5.1',
        'title': 'One or more validation errors occurred.',
        'status': 400,
        'errors': {
          'Email': ['The Email field is not a valid e-mail address.'],
          'Password': ['Passwords must be at least 6 characters.']
        }
      };

      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/auth/login'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          statusCode: 400,
          data: problemDetailsPayload,
        ),
      );

      final apiException = ApiException.fromDioException(dioException);
      expect(apiException.statusCode, equals(400));
      expect(apiException.errors, isNotNull);
      expect(apiException.errors!['Email']!.first, contains('not a valid e-mail'));
      expect(apiException.firstErrorMessage, equals('The Email field is not a valid e-mail address.'));
    });

    test('fromDioException should parse ProblemDetails detail field', () {
      final problemDetailsPayload = {
        'title': 'Conflict',
        'status': 409,
        'detail': 'An account with this email already exists.',
      };

      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/auth/register-parent'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/api/auth/register-parent'),
          statusCode: 409,
          data: problemDetailsPayload,
        ),
      );

      final apiException = ApiException.fromDioException(dioException);
      expect(apiException.statusCode, equals(409));
      expect(apiException.detail, equals('An account with this email already exists.'));
      expect(apiException.message, equals('An account with this email already exists.'));
    });
  });
}
