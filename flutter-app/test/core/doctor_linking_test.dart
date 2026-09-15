import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/core/errors/api_exception.dart';
import 'package:sawa/core/models/doctor_linking_models.dart';
import 'package:sawa/core/services/doctor_linking_service.dart';

void main() {
  group('1. Doctor Code Normalization & Validation', () {
    test('Normalizes valid DR- code with whitespace and lowercase', () {
      final normalized = LinkDoctorRequest.normalizeCode('  dr-4a2b8c1d  ');
      expect(normalized, equals('DR-4A2B8C1D'));
    });

    test('Auto-prepends DR- if 8-char hex code provided without prefix', () {
      final normalized = LinkDoctorRequest.normalizeCode('4a2b8c1d');
      expect(normalized, equals('DR-4A2B8C1D'));
    });

    test('Validates correct referral code formats', () {
      expect(LinkDoctorRequest.isValidCode('DR-4A2B8C1D'), isTrue);
      expect(LinkDoctorRequest.isValidCode('dr-4a2b8c1d'), isTrue);
      expect(LinkDoctorRequest.isValidCode('4A2B8C1D'), isTrue); // Auto-prepended to DR-
      expect(LinkDoctorRequest.isValidCode('DR-TESTCODE'), isTrue);
    });

    test('Rejects invalid referral codes', () {
      expect(LinkDoctorRequest.isValidCode(''), isFalse);
      expect(LinkDoctorRequest.isValidCode('DR-'), isFalse);
      expect(LinkDoctorRequest.isValidCode('ABC'), isFalse); // too short, doesn't match 8-char hex
      expect(LinkDoctorRequest.isValidCode('DR-!@#\$%^&*'), isFalse);
      expect(LinkDoctorRequest.isValidCode('   '), isFalse);
    });

    test('cleanCodePart strips single, lowercase, duplicate, and triplicated DR- prefixes as well as spaces', () {
      expect(LinkDoctorRequest.cleanCodePart('7B6780AA'), equals('7B6780AA'));
      expect(LinkDoctorRequest.cleanCodePart('DR-7B6780AA'), equals('7B6780AA'));
      expect(LinkDoctorRequest.cleanCodePart('dr-7b6780aa'), equals('7B6780AA'));
      expect(LinkDoctorRequest.cleanCodePart('DR-DR-7B6780AA'), equals('7B6780AA'));
      expect(LinkDoctorRequest.cleanCodePart('DR-DR-DR-CODE'), equals('CODE'));
      expect(LinkDoctorRequest.cleanCodePart('  dr- 7b6780aa  '), equals('7B6780AA'));
      expect(LinkDoctorRequest.cleanCodePart(''), equals(''));
      expect(LinkDoctorRequest.cleanCodePart('   '), equals(''));
    });

    test('formatFullCode always generates DR-{codePart} and handles duplicates', () {
      expect(LinkDoctorRequest.formatFullCode('7B6780AA'), equals('DR-7B6780AA'));
      expect(LinkDoctorRequest.formatFullCode('DR-7B6780AA'), equals('DR-7B6780AA'));
      expect(LinkDoctorRequest.formatFullCode('DR-DR-7B6780AA'), equals('DR-7B6780AA'));
      expect(LinkDoctorRequest.formatFullCode('  dr- 7b6780aa  '), equals('DR-7B6780AA'));
      expect(LinkDoctorRequest.formatFullCode(''), equals(''));
    });

    test('isValidCodePart accurately validates clean code part constraints', () {
      expect(LinkDoctorRequest.isValidCodePart('7B6780AA'), isTrue);
      expect(LinkDoctorRequest.isValidCodePart('DR-7B6780AA'), isTrue);
      expect(LinkDoctorRequest.isValidCodePart('DR-DR-7B6780AA'), isTrue);
      expect(LinkDoctorRequest.isValidCodePart('  dr- 7b6780aa  '), isTrue);
      expect(LinkDoctorRequest.isValidCodePart('ABC'), isFalse); // < 4 chars
      expect(LinkDoctorRequest.isValidCodePart('DR-!@#\$%^&*'), isFalse);
      expect(LinkDoctorRequest.isValidCodePart(''), isFalse);
      expect(LinkDoctorRequest.isValidCodePart('   '), isFalse);
    });
  });

  group('2. Request Serialization', () {
    test('Serializes exact JSON with normalized doctorCode key', () {
      final request = LinkDoctorRequest(doctorCode: '  dr-abc12345  ');
      final json = request.toJson();

      expect(json, containsPair('doctorCode', 'DR-ABC12345'));
      expect(json.keys.length, equals(1));
    });

    test('Serializes un-prefixed 8-char code as normalized DR- code', () {
      final request = LinkDoctorRequest(doctorCode: '1a2b3c4d');
      final json = request.toJson();

      expect(json, containsPair('doctorCode', 'DR-1A2B3C4D'));
    });
  });

  group('3. Response Parsing (DoctorAssignmentDto)', () {
    test('Parses camelCase backend DoctorAssignmentDto correctly', () {
      final json = {
        'id': 'a1111111-2222-3333-4444-555555555555',
        'doctorId': 'b2222222-3333-4444-5555-666666666666',
        'childId': 'c3333333-4444-5555-6666-777777777777',
        'assignedAtUtc': '2026-09-10T08:00:00.000Z',
        'isActive': true,
        'specialization': 'Pediatric Speech Therapy',
        'clinicName': 'Hope Center for Children',
        'doctorName': 'Dr. Sara Ahmed',
      };

      final model = DoctorAssignmentModel.fromJson(json);

      expect(model.id, equals('a1111111-2222-3333-4444-555555555555'));
      expect(model.doctorId, equals('b2222222-3333-4444-5555-666666666666'));
      expect(model.childId, equals('c3333333-4444-5555-6666-777777777777'));
      expect(model.isActive, isTrue);
      expect(model.specialization, equals('Pediatric Speech Therapy'));
      expect(model.clinicName, equals('Hope Center for Children'));
      expect(model.doctorName, equals('Dr. Sara Ahmed'));
    });

    test('Parses PascalCase backend response defensively', () {
      final json = {
        'Id': 'a1111111-2222-3333-4444-555555555555',
        'DoctorId': 'b2222222-3333-4444-5555-666666666666',
        'ChildId': 'c3333333-4444-5555-6666-777777777777',
        'AssignedAtUtc': '2026-09-10T08:00:00.000Z',
        'IsActive': true,
        'Specialization': 'Neurology',
        'ClinicName': 'Apex Clinic',
        'DoctorName': 'Dr. Khaled Omar',
      };

      final model = DoctorAssignmentModel.fromJson(json);

      expect(model.id, equals('a1111111-2222-3333-4444-555555555555'));
      expect(model.doctorName, equals('Dr. Khaled Omar'));
      expect(model.clinicName, equals('Apex Clinic'));
      expect(model.specialization, equals('Neurology'));
      expect(model.isActive, isTrue);
    });

    test('Handles nullable optional fields safely', () {
      final json = {
        'id': 'a1111111-2222-3333-4444-555555555555',
        'doctorId': 'b2222222-3333-4444-5555-666666666666',
        'childId': 'c3333333-4444-5555-6666-777777777777',
        'assignedAtUtc': '2026-09-10T08:00:00.000Z',
        'isActive': true,
      };

      final model = DoctorAssignmentModel.fromJson(json);

      expect(model.specialization, isNull);
      expect(model.clinicName, isNull);
      expect(model.doctorName, isNull);
      expect(model.status, equals('Pending'));
    });

    test('Parses explicit status field and createdAtUtc safely', () {
      final json = {
        'id': 'a1111111-2222-3333-4444-555555555555',
        'doctorId': 'b2222222-3333-4444-5555-666666666666',
        'childId': 'c3333333-4444-5555-6666-777777777777',
        'createdAtUtc': '2026-09-14T10:00:00.000Z',
        'isActive': false,
        'status': 'Approved',
      };

      final model = DoctorAssignmentModel.fromJson(json);
      expect(model.status, equals('Approved'));
      expect(model.isActive, isFalse);
    });
  });

  group('4. Active Child ID Guard', () {
    test('Throws ApiException when childId is empty before making request', () async {
      final service = DoctorLinkingService();

      expect(
        () => service.linkDoctorByCode(childId: '', doctorCode: 'DR-TESTCODE'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            equals(400),
          ),
        ),
      );
    });

    test('Throws ApiException when childId is whitespace only', () async {
      final service = DoctorLinkingService();

      expect(
        () => service.linkDoctorByCode(childId: '   ', doctorCode: 'DR-TESTCODE'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            equals(400),
          ),
        ),
      );
    });
  });

  group('5. Strict QR Payload Validation (Correction 1)', () {
    test('Accepts valid direct Doctor Referral Code payload', () {
      expect(
        DoctorLinkingService.extractReferralCodeFromQrPayload('DR-4A2B8C1D'),
        equals('DR-4A2B8C1D'),
      );
      expect(
        DoctorLinkingService.extractReferralCodeFromQrPayload('dr-4a2b8c1d'),
        equals('DR-4A2B8C1D'),
      );
      expect(
        DoctorLinkingService.extractReferralCodeFromQrPayload('4a2b8c1d'),
        equals('DR-4A2B8C1D'),
      );
    });

    test('Strictly REJECTS URLs (no URL extraction allowed per Correction 1)', () {
      const urlWithCode = 'https://mindora.app/doctor/link?code=DR-4A2B8C1D';
      expect(
        DoctorLinkingService.extractReferralCodeFromQrPayload(urlWithCode),
        isNull,
      );

      const urlHttp = 'http://example.com/dr/DR-4A2B8C1D';
      expect(
        DoctorLinkingService.extractReferralCodeFromQrPayload(urlHttp),
        isNull,
      );
    });

    test('Strictly REJECTS JSON payloads (no JSON extraction allowed per Correction 1)', () {
      const jsonPayload = '{"doctorCode": "DR-4A2B8C1D"}';
      expect(
        DoctorLinkingService.extractReferralCodeFromQrPayload(jsonPayload),
        isNull,
      );

      const jsonReferral = '{"referralCode": "DR-9F8E7D6C"}';
      expect(
        DoctorLinkingService.extractReferralCodeFromQrPayload(jsonReferral),
        isNull,
      );
    });

    test('Rejects invalid, arbitrary, or corrupted QR payloads', () {
      expect(DoctorLinkingService.extractReferralCodeFromQrPayload(''), isNull);
      expect(
        DoctorLinkingService.extractReferralCodeFromQrPayload('hello world'),
        isNull,
      );
      expect(
        DoctorLinkingService.extractReferralCodeFromQrPayload('DR-!@#\$%^&*'),
        isNull,
      );
      expect(
        DoctorLinkingService.extractReferralCodeFromQrPayload('   '),
        isNull,
      );
    });
  });

  group('6. Error Mapping Tests', () {
    test('Parses 400 Bad Request ProblemDetails', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/children/123/link-doctor'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/children/123/link-doctor'),
          statusCode: 400,
          data: {
            'errors': {
              'DoctorCode': ['Doctor code is required.']
            }
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final apiException = ApiException.fromDioException(dioException);
      expect(apiException.statusCode, equals(400));
      expect(apiException.firstErrorMessage, equals('Doctor code is required.'));
    });

    test('Parses 401 Unauthorized ProblemDetails', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/children/123/link-doctor'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/children/123/link-doctor'),
          statusCode: 401,
          data: {'detail': 'User is not authenticated.'},
        ),
        type: DioExceptionType.badResponse,
      );

      final apiException = ApiException.fromDioException(dioException);
      expect(apiException.statusCode, equals(401));
      expect(apiException.message, equals('User is not authenticated.'));
    });

    test('Parses 403 Forbidden ProblemDetails', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/children/123/link-doctor'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/children/123/link-doctor'),
          statusCode: 403,
          data: {
            'detail': 'Only parents are permitted to link a doctor to a child.'
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final apiException = ApiException.fromDioException(dioException);
      expect(apiException.statusCode, equals(403));
      expect(
        apiException.message,
        equals('Only parents are permitted to link a doctor to a child.'),
      );
    });

    test('Parses 404 Not Found ProblemDetails for invalid doctor code', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/children/123/link-doctor'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/children/123/link-doctor'),
          statusCode: 404,
          data: {'detail': 'Entity "Doctor" (DR-NONEXISTENT) was not found.'},
        ),
        type: DioExceptionType.badResponse,
      );

      final apiException = ApiException.fromDioException(dioException);
      expect(apiException.statusCode, equals(404));
      expect(
        apiException.message,
        equals('Entity "Doctor" (DR-NONEXISTENT) was not found.'),
      );
    });

    test('Parses 409 Conflict ProblemDetails for already actively assigned doctor', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/children/123/link-doctor'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/children/123/link-doctor'),
          statusCode: 409,
          data: {
            'detail': 'Doctor is already actively assigned to this child.'
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final apiException = ApiException.fromDioException(dioException);
      expect(apiException.statusCode, equals(409));
      expect(
        apiException.message,
        equals('Doctor is already actively assigned to this child.'),
      );
    });

    test('Parses 500 Server Error ProblemDetails', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/children/123/link-doctor'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/children/123/link-doctor'),
          statusCode: 500,
          data: {'title': 'Internal Server Error'},
        ),
        type: DioExceptionType.badResponse,
      );

      final apiException = ApiException.fromDioException(dioException);
      expect(apiException.statusCode, equals(500));
      expect(apiException.message, equals('Internal Server Error'));
    });
  });
}
