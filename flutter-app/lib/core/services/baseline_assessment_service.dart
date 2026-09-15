import '../constants/api_endpoints.dart';
import '../errors/api_exception.dart';
import '../models/baseline_assessment_models.dart';
import '../network/api_client.dart';
import '../storage/secure_storage_service.dart';

/// Dedicated service for Baseline Assessment operations with ASP.NET Core backend.
///
/// Communicates with:
/// - POST `/api/children/{childId}/baseline-assessment`
/// - GET `/api/children/{childId}/baseline-assessment`
class BaselineAssessmentService {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  BaselineAssessmentService({
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

  /// Submits the calculated baseline assessment scores for the given child.
  ///
  /// Calls `POST /api/children/{childId}/baseline-assessment`
  /// Returns the saved [BaselineAssessmentModel] from the server response.
  Future<BaselineAssessmentModel> recordBaselineAssessment({
    required String childId,
    required RecordBaselineAssessmentRequest request,
  }) async {
    final cleanChildId = childId.trim();
    if (cleanChildId.isEmpty) {
      throw const ApiException(
        statusCode: 400,
        message: 'معرف الطفل غير صالح أو غير موجود. يرجى تحديد طفل أولاً.',
      );
    }

    final response = await _apiClient.post(
      ApiEndpoints.baselineAssessment(cleanChildId),
      data: request.toJson(),
    );

    final rawData = response.data;
    if (rawData is Map) {
      return BaselineAssessmentModel.fromJson(
        Map<String, dynamic>.from(rawData),
      );
    }

    throw const ApiException(
      message: 'تنسيق استجابة غير متوقع من خادم التقييم.',
    );
  }

  /// Fetches the latest baseline assessment recorded for the child, or `null` if none.
  Future<BaselineAssessmentModel?> getLatestBaselineAssessment(
    String childId,
  ) async {
    final cleanChildId = childId.trim();
    if (cleanChildId.isEmpty) return null;

    try {
      final response = await _apiClient.get(
        ApiEndpoints.baselineAssessment(cleanChildId),
      );
      final rawData = response.data;
      if (rawData is Map) {
        return BaselineAssessmentModel.fromJson(
          Map<String, dynamic>.from(rawData),
        );
      }
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }
}
