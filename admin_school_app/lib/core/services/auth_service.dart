import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import 'secure_storage_service.dart';

/// Service for handling authentication operations in Admin App
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Logout the current user
  /// Clears local storage and optionally notifies the server
  Future<bool> logout({bool notifyServer = true}) async {
    try {
      if (notifyServer) {
        await _notifyServerLogout();
      }
    } catch (e) {
      debugPrint('Server logout notification failed: $e');

    }


    await SecureStorageService.clearAll();

    return true;
  }

  Future<void> _notifyServerLogout() async {
    final accessToken = await SecureStorageService.getToken();
    final refreshToken = await SecureStorageService.getRefreshToken();

    if (accessToken == null) return;

    final dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));

    await dio.post(
      '/auth/logout',
      data: refreshToken != null ? {'refresh_token': refreshToken} : null,
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );
  }

  /// Check if user is currently logged in
  Future<bool> isLoggedIn() async {
    return await SecureStorageService.isLoggedIn();
  }

  /// Get current user role
  Future<String?> getCurrentRole() async {
    return await SecureStorageService.getRole();
  }

  /// Get current user ID
  Future<String?> getCurrentUserId() async {
    return await SecureStorageService.getUserId();
  }
}
