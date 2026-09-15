import '../constants/api_endpoints.dart';
import '../errors/api_exception.dart';
import '../models/progress_models.dart';
import '../network/api_client.dart';
import '../storage/secure_storage_service.dart';

/// Dedicated service for parent progress overview, domain analytics, and session history with ASP.NET Core backend.
class ProgressService {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  static final RegExp _guidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  ProgressService({
    ApiClient? apiClient,
    SecureStorageService? storage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _storage = storage ?? SecureStorageService();

  ApiClient get apiClient => _apiClient;
  SecureStorageService get storage => _storage;

  bool _isValidGuid(String id) {
    return _guidRegex.hasMatch(id.trim());
  }

  /// Retrieves the currently active child ID from encrypted secure storage.
  Future<String?> getActiveChildId() async {
    return await _storage.getActiveChildId();
  }

  /// Fetches comprehensive child progress summary via `GET /api/children/{childId}/progress`.
  ///
  /// Returns authoritative server aggregates:
  /// - Total completed sessions
  /// - Total practice minutes
  /// - Overall average score
  /// - Current streak days
  /// - Recent performance trend
  /// - Per-domain breakdown (Movement, Speech, Attention)
  Future<ChildProgressSummaryModel> getChildProgress(String childId) async {
    final cleanChildId = childId.trim();
    if (!_isValidGuid(cleanChildId)) {
      throw const ApiException(
        statusCode: 400,
        message: 'معرف الطفل غير صالح أو فارغ. يرجى تحديد طفل نشط أولاً.',
      );
    }

    final response = await _apiClient.get(
      ApiEndpoints.childProgress(cleanChildId),
    );

    final rawData = response.data;
    if (rawData is Map) {
      return ChildProgressSummaryModel.fromJson(
        Map<String, dynamic>.from(rawData),
      );
    }

    throw const ApiException(
      message: 'تنسيق استجابة غير متوقع من خادم تقدم الطفل.',
    );
  }

  /// Fetches paginated session history via `GET /api/children/{childId}/progress/history`.
  ///
  /// Server contract:
  /// - Ordered ascending by `StartTimeUtc`.
  /// - Page size clamped between 1 and 100.
  /// - Optional domain filter: `Movement` | `Speech` | `Attention`.
  /// - Optional date range filters: `fromDate`, `toDate`.
  Future<List<SessionHistoryPointModel>> getProgressHistory(
    String childId, {
    String? domain,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
    int pageSize = 20,
  }) async {
    final cleanChildId = childId.trim();
    if (!_isValidGuid(cleanChildId)) {
      throw const ApiException(
        statusCode: 400,
        message: 'معرف الطفل غير صالح أو فارغ.',
      );
    }

    if (page < 1) {
      throw const ApiException(
        statusCode: 400,
        message: 'رقم الصفحة يجب أن يكون 1 أو أكثر.',
      );
    }

    final clampedPageSize = pageSize.clamp(1, 100);

    final queryParameters = <String, dynamic>{
      'page': page,
      'pageSize': clampedPageSize,
    };

    if (domain != null && domain.trim().isNotEmpty) {
      queryParameters['domain'] = domain.trim();
    }

    if (fromDate != null) {
      queryParameters['fromDate'] = fromDate.toUtc().toIso8601String();
    }

    if (toDate != null) {
      queryParameters['toDate'] = toDate.toUtc().toIso8601String();
    }

    final response = await _apiClient.get(
      ApiEndpoints.childProgressHistory(cleanChildId),
      queryParameters: queryParameters,
    );

    final rawData = response.data;
    if (rawData is List) {
      return rawData
          .map((item) => SessionHistoryPointModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList();
    }

    return const [];
  }

  /// Fetches child-specific cumulative activity performance via `GET /api/children/{childId}/activities/performance`.
  Future<List<ActivityPerformanceModel>> getActivityPerformance(
    String childId,
  ) async {
    final cleanChildId = childId.trim();
    if (!_isValidGuid(cleanChildId)) {
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
