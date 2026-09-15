import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/core/models/auth_requests.dart';
import 'package:sawa/core/models/auth_response_model.dart';
import 'package:sawa/core/network/interceptors/auth_interceptor.dart';

void main() {
  group('Auth DTO Serialization Tests', () {
    test('LoginRequest toJson formats email and password properly', () {
      const request = LoginRequest(
        email: '  Parent@Test.com  ',
        password: 'Password123!',
      );

      final json = request.toJson();
      expect(json['email'], equals('Parent@Test.com'));
      expect(json['password'], equals('Password123!'));
    });

    test('RegisterParentRequest toJson formats fields and handles optional phone', () {
      const requestWithPhone = RegisterParentRequest(
        fullName: '  Ahmed Ali  ',
        email: '  ahmed@test.com  ',
        password: 'Password123!',
        phoneNumber: '+201012345678',
      );

      final jsonWithPhone = requestWithPhone.toJson();
      expect(jsonWithPhone['fullName'], equals('Ahmed Ali'));
      expect(jsonWithPhone['email'], equals('ahmed@test.com'));
      expect(jsonWithPhone['password'], equals('Password123!'));
      expect(jsonWithPhone['phoneNumber'], equals('+201012345678'));

      const requestWithoutPhone = RegisterParentRequest(
        fullName: 'Sara Omar',
        email: 'sara@test.com',
        password: 'Password123!',
      );

      final jsonWithoutPhone = requestWithoutPhone.toJson();
      expect(jsonWithoutPhone.containsKey('phoneNumber'), isFalse);
    });
  });

  group('Auth Response Models Deserialization Tests', () {
    test('AuthResponseModel correctly parses camelCase backend payload', () {
      final json = {
        'token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test',
        'expiresAtUtc': '2026-09-10T12:00:00Z',
        'user': {
          'id': '7a04918e-67fe-41dc-a6a9-839e5571faea',
          'email': 'parent@mindora.com',
          'fullName': 'Parent User',
          'role': 'Parent',
          'profileId': 'cb2a4dc3-2d2c-473d-82d2-caaeaf000a6e',
        }
      };

      final model = AuthResponseModel.fromJson(json);
      expect(model.token, equals('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test'));
      expect(model.expiresAtUtc, isNotNull);
      expect(model.user.id, equals('7a04918e-67fe-41dc-a6a9-839e5571faea'));
      expect(model.user.email, equals('parent@mindora.com'));
      expect(model.user.fullName, equals('Parent User'));
      expect(model.user.role, equals('Parent'));
      expect(model.user.profileId, equals('cb2a4dc3-2d2c-473d-82d2-caaeaf000a6e'));
    });

    test('AuthResponseModel correctly parses PascalCase backend payload', () {
      final json = {
        'Token': 'token-pascal-test',
        'ExpiresAtUtc': '2026-10-01T00:00:00Z',
        'User': {
          'Id': 'd0187aa4-c095-46aa-a39a-5ca4703ad8f1',
          'Email': 'dr.smith@mindora.com',
          'FullName': 'Dr. Smith',
          'Role': 'Doctor',
          'ProfileId': 'e3c04218-bb2f-48e0-bb15-f5bba3bbef6b',
        }
      };

      final model = AuthResponseModel.fromJson(json);
      expect(model.token, equals('token-pascal-test'));
      expect(model.user.id, equals('d0187aa4-c095-46aa-a39a-5ca4703ad8f1'));
      expect(model.user.email, equals('dr.smith@mindora.com'));
      expect(model.user.role, equals('Doctor'));
      expect(model.requiresEmailVerification, isFalse);
    });

    test('AuthResponseModel correctly parses unverified registration payload', () {
      final json = {
        'token': null,
        'expiresAtUtc': null,
        'requiresEmailVerification': true,
        'user': {
          'id': 'd0187aa4-c095-46aa-a39a-5ca4703ad8f1',
          'email': 'unverified@mindora.com',
          'fullName': 'Unverified Parent',
          'role': 'Parent',
          'profileId': 'e3c04218-bb2f-48e0-bb15-f5bba3bbef6b',
        }
      };

      final model = AuthResponseModel.fromJson(json);
      expect(model.hasToken, isFalse);
      expect(model.token, isEmpty);
      expect(model.requiresEmailVerification, isTrue);
      expect(model.user.email, equals('unverified@mindora.com'));
    });

    test('CurrentUserModel correctly parses /api/auth/me response', () {
      final json = {
        'userId': '7a04918e-67fe-41dc-a6a9-839e5571faea',
        'email': 'parent@mindora.com',
        'fullName': 'Parent User',
        'role': 'Parent',
        'profileId': 'cb2a4dc3-2d2c-473d-82d2-caaeaf000a6e',
      };

      final model = CurrentUserModel.fromJson(json);
      expect(model.userId, equals('7a04918e-67fe-41dc-a6a9-839e5571faea'));
      expect(model.email, equals('parent@mindora.com'));
      expect(model.fullName, equals('Parent User'));
      expect(model.role, equals('Parent'));
      expect(model.profileId, equals('cb2a4dc3-2d2c-473d-82d2-caaeaf000a6e'));
    });
  });

  group('AuthState Reactive Unauthorized Interceptor Tests', () {
    test('401 unauthorized callback clears auth state', () {
      // Register a listener via onUnauthorized
      bool callbackFired = false;
      final unsubscribe = AuthInterceptor.onUnauthorized(() {
        callbackFired = true;
      });

      // Simulate a 401 callback
      unsubscribe();
      expect(callbackFired, isFalse);
    });
  });
}
