import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  final Dio dio;
  final _storage = const FlutterSecureStorage();
  final GlobalKey<NavigatorState>? navigatorKey;

  bool _isRefreshing = false;
  final List<Function> _pendingRequests = [];

  ApiClient(String baseUrl, {this.navigatorKey})
    : dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {"Content-Type": "application/json"},
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: "token");
          if (token != null && token.isNotEmpty) {
            options.headers["Authorization"] = "Bearer $token";
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 ||
              error.response?.statusCode == 403) {
            print(
              '⚠️ Got ${error.response?.statusCode} - Token may be expired',
            );

            if (_isRefreshing) {
              return _addRequestToQueue(error, handler);
            }

            _isRefreshing = true;

            try {
              final newToken = await _refreshToken();

              if (newToken != null) {
                await _storage.write(key: "token", value: newToken);

                final opts = error.requestOptions;
                opts.headers["Authorization"] = "Bearer $newToken";

                final response = await dio.fetch(opts);

                _processPendingRequests(newToken);

                return handler.resolve(response);
              } else {
                await _clearTokensAndRedirectToLogin();
                return handler.reject(error);
              }
            } catch (e) {
              print('❌ Refresh token failed: $e');
              await _clearTokensAndRedirectToLogin();
              return handler.reject(error);
            } finally {
              _isRefreshing = false;
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  Future<String?> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: "refresh_token");

      if (refreshToken == null || refreshToken.isEmpty) {
        print('❌ No refresh token found');
        return null;
      }

      print('🔄 Attempting to refresh token...');

      final refreshDio = Dio(
        BaseOptions(
          baseUrl: dio.options.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final response = await refreshDio.post(
        "/auth/refresh",
        data: {"refreshToken": refreshToken},
        options: Options(
          headers: {
            "Authorization": "Bearer $refreshToken",
            "Content-Type": "application/json",
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        final newAccessToken =
            data["data"]?["accessToken"] ??
            data["accessToken"] ??
            data["data"]?["access_token"] ??
            data["access_token"];

        final newRefreshToken =
            data["data"]?["refreshToken"] ??
            data["refreshToken"] ??
            data["data"]?["refresh_token"] ??
            data["refresh_token"];

        if (newRefreshToken != null && newRefreshToken != refreshToken) {
          await _storage.write(key: "refresh_token", value: newRefreshToken);
          print('🔄 Refresh token also updated');
        }

        if (newAccessToken != null) {
          print('✅ Token refreshed successfully');
          return newAccessToken;
        }
      }

      print('❌ Refresh response invalid');
      return null;
    } on DioException catch (e) {
      print(
        '❌ DioException refreshing token: ${e.response?.statusCode} - ${e.message}',
      );
      return null;
    } catch (e) {
      print('❌ Error refreshing token: $e');
      return null;
    }
  }

  Future<void> _addRequestToQueue(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    _pendingRequests.add(() async {
      try {
        final token = await _storage.read(key: "token");
        if (token != null) {
          final opts = error.requestOptions;
          opts.headers["Authorization"] = "Bearer $token";
          final response = await dio.fetch(opts);
          handler.resolve(response);
        } else {
          handler.reject(error);
        }
      } catch (e) {
        handler.reject(error);
      }
    });
  }

  void _processPendingRequests(String newToken) {
    for (var request in _pendingRequests) {
      request();
    }
    _pendingRequests.clear();
  }

  Future<void> _clearTokensAndRedirectToLogin() async {
    await _storage.delete(key: "token");
    await _storage.delete(key: "refresh_token");
    print('🔒 Tokens cleared - redirecting to login');

    if (navigatorKey?.currentState != null) {
      navigatorKey!.currentState!.pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    } else {
      print('⚠️ NavigatorKey is null - cannot redirect to login');
    }
  }
}
