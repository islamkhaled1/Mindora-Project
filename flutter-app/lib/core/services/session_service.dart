import '../constants/api_endpoints.dart';
import '../errors/api_exception.dart';
import '../models/session_models.dart';
import '../network/api_client.dart';
import '../storage/secure_storage_service.dart';

/// Dedicated service for managing the rehabilitation activity session lifecycle with ASP.NET Core backend.
class SessionService {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  static final RegExp _guidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  SessionService({
    ApiClient? apiClient,
    SecureStorageService? storage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _storage = storage ?? SecureStorageService();

  ApiClient get apiClient => _apiClient;
  SecureStorageService get storage => _storage;

  bool _isValidGuid(String id) {
    return _guidRegex.hasMatch(id.trim());
  }

  /// Starts an activity session via `POST /api/sessions`.
  ///
  /// Strictly requires valid [childId] and [activityId] GUIDs.
  /// Automatically persists the returned session ID into secure storage for recovery.
  Future<SessionModel> startSession(StartSessionRequest request) async {
    final cleanChildId = request.childId.trim();
    final cleanActivityId = request.activityId.trim();

    if (!_isValidGuid(cleanChildId)) {
      throw const ApiException(
        statusCode: 400,
        message: 'معرف الطفل غير صالح أو فارغ. يرجى تحديد طفل نشط أولاً.',
      );
    }

    if (!_isValidGuid(cleanActivityId)) {
      throw const ApiException(
        statusCode: 400,
        message: 'معرف النشاط غير صالح أو فارغ.',
      );
    }

    final response = await _apiClient.post(
      ApiEndpoints.sessions,
      data: request.toJson(),
    );

    final rawData = response.data;
    if (rawData is Map) {
      final session = SessionModel.fromJson(Map<String, dynamic>.from(rawData));
      await _storage.saveActiveSessionId(session.id);
      return session;
    }

    throw const ApiException(
      message: 'تنسيق استجابة غير متوقع من خادم الجلسات.',
    );
  }

  /// Records intermediate telemetry performance metrics via `POST /api/sessions/{sessionId}/metrics`.
  Future<List<PerformanceMetricModel>> recordMetrics({
    required String sessionId,
    required List<MetricInputModel> metrics,
  }) async {
    final cleanSessionId = sessionId.trim();
    if (!_isValidGuid(cleanSessionId)) {
      throw const ApiException(
        statusCode: 400,
        message: 'معرف الجلسة غير صالح أو فارغ.',
      );
    }

    if (metrics.isEmpty) {
      throw const ApiException(
        statusCode: 400,
        message: 'يجب تقديم مقياس أداء واحد على الأقل.',
      );
    }

    final response = await _apiClient.post(
      ApiEndpoints.sessionMetrics(cleanSessionId),
      data: RecordMetricsRequest(metrics: metrics).toJson(),
    );

    final rawData = response.data;
    if (rawData is List) {
      return rawData
          .map((m) => PerformanceMetricModel.fromJson(Map<String, dynamic>.from(m as Map)))
          .toList();
    }

    return const [];
  }

  /// Completes the session via `POST /api/sessions/{sessionId}/complete`.
  ///
  /// Triggers authoritative server-side AI performance analysis and difficulty adaptation recommendation.
  /// Handles duplicate completion idempotently.
  /// Automatically clears active session ID from secure storage upon completion.
  Future<CompletedSessionModel> completeSession({
    required String sessionId,
    required CompleteSessionRequest request,
  }) async {
    final cleanSessionId = sessionId.trim();
    if (!_isValidGuid(cleanSessionId)) {
      throw const ApiException(
        statusCode: 400,
        message: 'معرف الجلسة غير صالح أو فارغ.',
      );
    }

    if (request.actualDurationSeconds < 0) {
      throw const ApiException(
        statusCode: 400,
        message: 'مدة الجلسة الفعلية لا يمكن أن تكون سالبة.',
      );
    }

    final response = await _apiClient.post(
      ApiEndpoints.completeSession(cleanSessionId),
      data: request.toJson(),
    );

    final rawData = response.data;
    if (rawData is Map) {
      final completedSession = CompletedSessionModel.fromJson(Map<String, dynamic>.from(rawData));
      await _storage.clearActiveSessionId();
      return completedSession;
    }

    throw const ApiException(
      message: 'تنسيق استجابة غير متوقع من خادم اكتمال الجلسة.',
    );
  }

  /// Records post-session parent sentiment feedback via `POST /api/sessions/{sessionId}/feedback`.
  Future<CompletedSessionModel> recordFeedback({
    required String sessionId,
    required RecordFeedbackRequest request,
  }) async {
    final cleanSessionId = sessionId.trim();
    if (!_isValidGuid(cleanSessionId)) {
      throw const ApiException(
        statusCode: 400,
        message: 'معرف الجلسة غير صالح أو فارغ.',
      );
    }

    final response = await _apiClient.post(
      ApiEndpoints.sessionFeedback(cleanSessionId),
      data: request.toJson(),
    );

    final rawData = response.data;
    if (rawData is Map) {
      return CompletedSessionModel.fromJson(Map<String, dynamic>.from(rawData));
    }

    throw const ApiException(
      message: 'تنسيق استجابة غير متوقع من خادم تقييم الجلسة.',
    );
  }

  /// Cancels an active session via `POST /api/sessions/{sessionId}/abandon`.
  ///
  /// Automatically clears active session ID from secure storage.
  Future<SessionModel> abandonSession(String sessionId) async {
    final cleanSessionId = sessionId.trim();
    if (!_isValidGuid(cleanSessionId)) {
      throw const ApiException(
        statusCode: 400,
        message: 'معرف الجلسة غير صالح أو فارغ.',
      );
    }

    final response = await _apiClient.post(
      ApiEndpoints.abandonSession(cleanSessionId),
    );

    final rawData = response.data;
    if (rawData is Map) {
      final session = SessionModel.fromJson(Map<String, dynamic>.from(rawData));
      await _storage.clearActiveSessionId();
      return session;
    }

    throw const ApiException(
      message: 'تنسيق استجابة غير متوقع من خادم إلغاء الجلسة.',
    );
  }

  /// Fetches complete session details by ID via `GET /api/sessions/{sessionId}`.
  Future<SessionDetailsModel> getSessionById(String sessionId) async {
    final cleanSessionId = sessionId.trim();
    if (!_isValidGuid(cleanSessionId)) {
      throw const ApiException(
        statusCode: 400,
        message: 'معرف الجلسة غير صالح أو فارغ.',
      );
    }

    final response = await _apiClient.get(
      ApiEndpoints.sessionById(cleanSessionId),
    );

    final rawData = response.data;
    if (rawData is Map) {
      return SessionDetailsModel.fromJson(Map<String, dynamic>.from(rawData));
    }

    throw const ApiException(
      message: 'تنسيق استجابة غير متوقع من خادم تفاصيل الجلسة.',
    );
  }
}
