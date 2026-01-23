import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' as getx;
import '../config/app_config.dart';
import '../services/secure_storage_service.dart';
import '../../features/auth/presentation/pages/login_page.dart';

class DioClient {
  static Dio? _instance;
  static bool _isRefreshing = false;
  static final List<Function(String)> _pendingRequests = [];

  static Future<Dio> getInstance() async {
    if (_instance == null) {
      _instance = Dio(
        BaseOptions(
          baseUrl: AppConfig.baseUrl,
          connectTimeout: AppConfig.connectTimeout,
          receiveTimeout: AppConfig.receiveTimeout,
        ),
      );

      _instance!.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {

            final noAuthPaths = ['/auth/login', '/auth/check-email', '/auth/refresh', '/password/send-code', '/password/reset'];
            if (noAuthPaths.any((path) => options.path.contains(path))) {
              options.headers['Content-Type'] = 'application/json';
              return handler.next(options);
            }

            final token = await SecureStorageService.getToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
              options.headers['Content-Type'] = 'application/json';
              debugPrint('>>> Request: ${options.method} ${options.path}');
            } else {
              debugPrint('>>> No token available for: ${options.path}');
              return handler.reject(
                DioException(
                  requestOptions: options,
                  error: 'No token available',
                  type: DioExceptionType.cancel,
                ),
              );
            }
            return handler.next(options);
          },
          onError: (error, handler) async {
            debugPrint('>>> Error: ${error.response?.statusCode} on ${error.requestOptions.path}');


            if (error.response?.statusCode == 401) {

              final noRefreshPaths = ['/auth/login', '/auth/check-email', '/auth/refresh'];
              if (noRefreshPaths.any((path) => error.requestOptions.path.contains(path))) {
                return handler.next(error);
              }


              if (_isRefreshing) {
                try {
                  final completer = Completer<Response>();
                  _pendingRequests.add((newToken) async {
                    error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
                    try {
                      final response = await _instance!.fetch(error.requestOptions);
                      completer.complete(response);
                    } catch (e) {
                      completer.completeError(e);
                    }
                  });
                  final response = await completer.future;
                  return handler.resolve(response);
                } catch (e) {
                  return handler.next(error);
                }
              }

              final refreshed = await _tryRefreshToken();
              if (refreshed) {

                final token = await SecureStorageService.getToken();
                error.requestOptions.headers['Authorization'] = 'Bearer $token';
                try {
                  final response = await _instance!.fetch(error.requestOptions);
                  return handler.resolve(response);
                } catch (e) {
                  return handler.next(error);
                }
              } else {

                debugPrint('>>> Token refresh failed, redirecting to login');
                await _handleAuthFailure();
              }
            }
            return handler.next(error);
          },
        ),
      );
    }
    return _instance!;
  }

  static Future<bool> _tryRefreshToken() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;

    try {
      final refreshToken = await SecureStorageService.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('>>> No refresh token available');
        _isRefreshing = false;
        return false;
      }

      debugPrint('>>> Attempting token refresh...');
      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
      ));

      final response = await dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['access_token'];
        final newRefreshToken = response.data['refresh_token'];
        final role = await SecureStorageService.getRole();
        final userId = await SecureStorageService.getUserId();

        await SecureStorageService.saveToken(newAccessToken, role ?? '', userId ?? '');
        await SecureStorageService.saveRefreshToken(newRefreshToken);

        debugPrint('>>> Token refresh successful');


        for (var callback in _pendingRequests) {
          callback(newAccessToken);
        }
        _pendingRequests.clear();

        _isRefreshing = false;
        return true;
      }
    } catch (e) {
      debugPrint('>>> Token refresh failed: $e');
    }

    _pendingRequests.clear();
    _isRefreshing = false;
    return false;
  }

  static Future<void> _handleAuthFailure() async {

    await SecureStorageService.clearAll();
    reset();


    getx.Get.snackbar(
      'Sesiune expirată',
      'Te rugăm să te autentifici din nou',
      snackPosition: getx.SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );


    getx.Get.offAll(() => const LoginPage());
  }

  static void reset() {
    _instance = null;
    _isRefreshing = false;
    _pendingRequests.clear();
  }

  static String get baseUrl => AppConfig.baseUrl;
}
