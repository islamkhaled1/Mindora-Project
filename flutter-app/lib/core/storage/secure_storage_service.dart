import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for managing encrypted local storage for authentication session data
/// and the active child GUID context.
///
/// Strictly limited to tokens, essential session identifiers, and active child ID.
/// Does NOT log or expose credentials or tokens.
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  // Storage Keys
  static const String _keyAccessToken = 'sawa_access_token';
  static const String _keyExpiresAtUtc = 'sawa_expires_at_utc';
  static const String _keyUserId = 'sawa_user_id';
  static const String _keyUserEmail = 'sawa_user_email';
  static const String _keyUserRole = 'sawa_user_role';
  static const String _keyActiveChildId = 'sawa_active_child_id';
  static const String _keyActiveSessionId = 'sawa_active_session_id';

  /// Saves the authenticated user's JWT access token and expiration.
  Future<void> saveAuthToken({
    required String token,
    String? expiresAtUtc,
  }) async {
    await _storage.write(key: _keyAccessToken, value: token);
    if (expiresAtUtc != null) {
      await _storage.write(key: _keyExpiresAtUtc, value: expiresAtUtc);
    }
  }

  /// Retrieves the stored JWT access token, or `null` if none exists.
  Future<String?> getAuthToken() async {
    try {
      return await _storage.read(key: _keyAccessToken);
    } catch (_) {
      return null;
    }
  }

  /// Saves basic session user metadata.
  Future<void> saveUserInfo({
    required String userId,
    required String email,
    required String role,
  }) async {
    await _storage.write(key: _keyUserId, value: userId);
    await _storage.write(key: _keyUserEmail, value: email);
    await _storage.write(key: _keyUserRole, value: role);
  }

  /// Retrieves the stored user ID.
  Future<String?> getUserId() async {
    return await _storage.read(key: _keyUserId);
  }

  /// Retrieves the stored user email.
  Future<String?> getUserEmail() async {
    return await _storage.read(key: _keyUserEmail);
  }

  /// Retrieves the stored user role ('Parent' or 'Doctor').
  Future<String?> getUserRole() async {
    return await _storage.read(key: _keyUserRole);
  }

  /// Persists the selected active child's server GUID.
  Future<void> saveActiveChildId(String childId) async {
    await _storage.write(key: _keyActiveChildId, value: childId);
  }

  /// Retrieves the active child's server GUID.
  Future<String?> getActiveChildId() async {
    return await _storage.read(key: _keyActiveChildId);
  }

  /// Clears the active child context.
  Future<void> clearActiveChildId() async {
    await _storage.delete(key: _keyActiveChildId);
  }

  /// Persists the active session's server GUID for recovery.
  Future<void> saveActiveSessionId(String sessionId) async {
    await _storage.write(key: _keyActiveSessionId, value: sessionId);
  }

  /// Retrieves the active session's server GUID.
  Future<String?> getActiveSessionId() async {
    return await _storage.read(key: _keyActiveSessionId);
  }

  /// Clears the active session context upon completion or abandonment.
  Future<void> clearActiveSessionId() async {
    await _storage.delete(key: _keyActiveSessionId);
  }

  /// Checks whether an authentication token is currently present.
  Future<bool> hasValidToken() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }

  /// Clears all authentication session data on logout or 401 unauthorized.
  Future<void> clearAuth() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyExpiresAtUtc);
    await _storage.delete(key: _keyUserId);
    await _storage.delete(key: _keyUserEmail);
    await _storage.delete(key: _keyUserRole);
    await _storage.delete(key: _keyActiveChildId);
    await _storage.delete(key: _keyActiveSessionId);
  }
}
