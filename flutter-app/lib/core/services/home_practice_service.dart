import '../constants/api_endpoints.dart';
import '../errors/api_exception.dart';
import '../models/home_practice_models.dart';
import '../network/api_client.dart';
import '../storage/secure_storage_service.dart';

/// Service for the GET /api/children/{childId}/home-practice-recommendation endpoint.
///
/// Graceful degradation contract:
/// - Returns null if the child has no assessment yet (404 from backend)
/// - Returns null if the endpoint is unreachable or returns an unexpected error
/// - NEVER throws an exception to the caller — logs the error internally
/// - The caller (HomePracticePlanScreen) must handle null by showing the fallback UI
class HomePracticeService {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  HomePracticeService({
    ApiClient? apiClient,
    SecureStorageService? storage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _storage = storage ?? SecureStorageService();

  /// Fetches the preliminary home-practice recommendation for the given child.
  ///
  /// Returns null on any error (404 = no assessment, network error, auth error).
  /// Never throws — caller must handle null gracefully.
  Future<HomePracticeRecommendationModel?> getRecommendation(
      String childId) async {
    if (childId.trim().isEmpty) return null;

    try {
      final response = await _apiClient.get(
        ApiEndpoints.homePracticeRecommendation(childId.trim()),
      );

      final rawData = response.data;
      if (rawData is Map) {
        return HomePracticeRecommendationModel.fromJson(
            Map<String, dynamic>.from(rawData));
      }
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        // Child has no assessment yet — expected state, not an error
        return null;
      }
      // Other API errors (401, 403, 500) — log and return null for graceful fallback
      // ignore: avoid_print
      print('[HomePracticeService] API error: ${e.statusCode} — ${e.firstErrorMessage}');
      return null;
    } catch (e) {
      // Network or unexpected errors — log and return null
      // ignore: avoid_print
      print('[HomePracticeService] Unexpected error: $e');
      return null;
    }
  }

  Future<String?> getActiveChildId() async {
    return await _storage.getActiveChildId();
  }
}
