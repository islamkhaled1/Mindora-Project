import '../constants/api_endpoints.dart';
import '../models/child_model.dart';
import '../models/child_requests.dart';
import '../network/api_client.dart';
import '../storage/secure_storage_service.dart';

/// Service handling child profile operations with the ASP.NET Core backend.
class ChildrenService {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  ChildrenService({
    ApiClient? apiClient,
    SecureStorageService? storage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _storage = storage ?? SecureStorageService();

  SecureStorageService get storage => _storage;
  ApiClient get apiClient => _apiClient;

  /// Registers a new child profile under the authenticated parent.
  /// Automatically persists the returned child GUID as the active child in secure storage.
  Future<ChildModel> createChild(CreateChildRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.children,
      data: request.toJson(),
    );

    final child = ChildModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );

    if (child.id.isNotEmpty) {
      await _storage.saveActiveChildId(child.id);
    }

    return child;
  }

  /// Retrieves the currently selected active child GUID from local secure storage.
  Future<String?> getActiveChildId() async {
    return await _storage.getActiveChildId();
  }

  /// Fetches a child profile by ID.
  Future<ChildModel> getChildById(String childId) async {
    final response = await _apiClient.get(ApiEndpoints.childById(childId));
    return ChildModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  /// Fetches all children profiles for the current authenticated parent.
  Future<List<ChildModel>> getChildren() async {
    final response = await _apiClient.get(ApiEndpoints.children);
    if (response.data is List) {
      return (response.data as List)
          .map((item) => ChildModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }
    return [];
  }
}

