import '../constants/api_endpoints.dart';
import '../errors/api_exception.dart';
import '../models/doctor_linking_models.dart';
import '../network/api_client.dart';
import '../storage/secure_storage_service.dart';

/// Dedicated service handling child-to-doctor linking via referral code.
///
/// Communicates with ASP.NET Core endpoint:
/// POST /api/children/{childId}/link-doctor
class DoctorLinkingService {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  DoctorLinkingService({
    ApiClient? apiClient,
    SecureStorageService? storage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _storage = storage ?? SecureStorageService();

  SecureStorageService get storage => _storage;
  ApiClient get apiClient => _apiClient;

  /// Retrieves the currently active child ID from local encrypted storage.
  Future<String?> getActiveChildId() async {
    return await _storage.getActiveChildId();
  }

  /// Links the given child to a doctor using the doctor's unique referral code.
  ///
  /// Sends normalized referral code: `DR-XXXXXXXX`.
  /// Returns the confirmed [DoctorAssignmentModel] on success.
  /// Throws [ApiException] on error (400, 401, 403, 404, 409, 500, network).
  Future<DoctorAssignmentModel> linkDoctorByCode({
    required String childId,
    required String doctorCode,
  }) async {
    final cleanChildId = childId.trim();
    if (cleanChildId.isEmpty) {
      throw const ApiException(
        statusCode: 400,
        message: 'معرف الطفل غير صالح أو غير موجود. يرجى اختيار طفل أولاً.',
      );
    }

    final request = LinkDoctorRequest(doctorCode: doctorCode);
    if (request.doctorCode.trim().isEmpty) {
      throw const ApiException(
        statusCode: 400,
        message: 'يرجى إدخال رمز الطبيب.',
      );
    }

    final response = await _apiClient.post(
      ApiEndpoints.linkDoctorByCode(cleanChildId),
      data: request.toJson(),
    );

    final rawData = response.data;
    if (rawData is Map) {
      return DoctorAssignmentModel.fromJson(Map<String, dynamic>.from(rawData));
    }

    throw const ApiException(
      message: 'تنسيق استجابة غير متوقع من الخادم.',
    );
  }

  /// Validates and extracts a Doctor Referral Code from a raw QR payload.
  ///
  /// STRICT CONTRACT:
  /// Accepts ONLY a payload that directly matches the verified Doctor Referral Code format.
  /// Does NOT parse arbitrary URLs, JSON, or embedded metadata.
  ///
  /// Returns normalized code (e.g. "DR-XXXXXXXX") if the payload matches the referral code format,
  /// or `null` if the payload does not match.
  static String? extractReferralCodeFromQrPayload(String rawPayload) {
    final payload = rawPayload.trim();
    if (payload.isEmpty) return null;

    // Reject URLs, JSON, XML, or multi-line strings
    if (payload.startsWith('http://') ||
        payload.startsWith('https://') ||
        payload.startsWith('{') ||
        payload.startsWith('[') ||
        payload.startsWith('<') ||
        payload.contains('\n') ||
        payload.contains(' ') ||
        payload.contains('?')) {
      return null;
    }

    // Direct Doctor Referral Code validation
    if (LinkDoctorRequest.isValidCode(payload)) {
      return LinkDoctorRequest.normalizeCode(payload);
    }

    return null;
  }
}
