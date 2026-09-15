import '../constants/api_endpoints.dart';
import '../errors/api_exception.dart';
import '../models/activity_models.dart';
import '../network/api_client.dart';
import '../storage/secure_storage_service.dart';

/// Dedicated service for activity catalog and performance queries with ASP.NET Core backend.
class ActivityService {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  ActivityService({
    ApiClient? apiClient,
    SecureStorageService? storage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _storage = storage ?? SecureStorageService();

  ApiClient get apiClient => _apiClient;
  SecureStorageService get storage => _storage;

  /// Retrieves the currently active child ID from encrypted secure storage.
  Future<String?> getActiveChildId() async {
    return await _storage.getActiveChildId();
  }

  /// Fetches activities from `GET /api/activities` with optional server-side filtering.
  ///
  /// Query parameters:
  /// - [domain]: `Movement` | `Speech` | `Attention`
  /// - [difficulty]: `Beginner` | `Intermediate` | `Advanced`
  Future<List<ActivityModel>> getActivities({
    String? domain,
    String? difficulty,
  }) async {
    final queryParameters = <String, dynamic>{};

    if (domain != null && domain.trim().isNotEmpty) {
      queryParameters['domain'] = domain.trim();
    }
    if (difficulty != null && difficulty.trim().isNotEmpty) {
      queryParameters['difficulty'] = difficulty.trim();
    }

    final response = await _apiClient.get(
      ApiEndpoints.activities,
      queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
    );

    final rawData = response.data;
    if (rawData is List) {
      return rawData
          .map((item) => ActivityModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList();
    }

    return const [];
  }

  /// Fetches a single activity details by ID via `GET /api/activities/{activityId}`.
  Future<ActivityModel> getActivityById(String activityId) async {
    final cleanId = activityId.trim();
    if (cleanId.isEmpty) {
      throw const ApiException(
        statusCode: 400,
        message: 'معرف النشاط غير صالح أو فارغ.',
      );
    }

    final response = await _apiClient.get(ApiEndpoints.activityById(cleanId));
    final rawData = response.data;
    if (rawData is Map) {
      return ActivityModel.fromJson(
        Map<String, dynamic>.from(rawData),
      );
    }

    throw const ApiException(
      message: 'تنسيق استجابة غير متوقع من خادم الأنشطة.',
    );
  }

  /// Fetches child-specific activity performance via `GET /api/children/{childId}/activities/performance`.
  Future<List<ActivityPerformanceModel>> getChildActivityPerformance(
    String childId,
  ) async {
    final cleanChildId = childId.trim();
    if (cleanChildId.isEmpty) {
      throw const ApiException(
        statusCode: 400,
        message: 'معرف الطفل غير صالح أو فارغ.',
      );
    }

    final response = await _apiClient.get(
      ApiEndpoints.childActivityPerformance(cleanChildId),
    );

    final rawData = response.data;
    if (rawData is List) {
      return rawData
          .map((item) => ActivityPerformanceModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList();
    }

    return const [];
  }
}
