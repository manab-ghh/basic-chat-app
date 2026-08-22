import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/services/storage_service.dart';

/// Custom exception type so UI layers can show clean, predictable
/// error messages regardless of what Dio/the backend throws.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final List<Map<String, dynamic>>? errors;

  ApiException(this.message, {this.statusCode, this.errors});

  @override
  String toString() => message;
}

/// Callback invoked when the server reports the session as expired/invalid.
/// The app wires this to force-navigate to the login screen (see app_router.dart).
typedef OnUnauthorized = void Function();

class ApiClient {
  late final Dio dio;
  final StorageService _storageService;
  OnUnauthorized? onUnauthorized;

  ApiClient(this._storageService) {
    dio = Dio(
      BaseOptions(
        baseUrl: resolveApiBaseUrl(),
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          // Let Dio set the multipart boundary; a stale JSON content-type
          // would make avatar uploads fail.
          if (options.data is FormData) {
            options.headers.remove('Content-Type');
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          final response = error.response;

          if (response?.statusCode == 401) {
            final path = error.requestOptions.path;
            final isAuthAttempt =
                path.contains('/auth/login') || path.contains('/auth/register');
            if (!isAuthAttempt) {
              await _storageService.deleteToken();
              onUnauthorized?.call();
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  static String resolveApiBaseUrl() {
    final fromEnv = dotenv.env['BASE_URL'];
    final fallback = fromEnv != null && fromEnv.isNotEmpty
        ? fromEnv
        : 'http://localhost:5001/api';
    return rewriteLocalhostForAndroid(fallback);
  }

  static String resolveSocketUrl() {
    final fromEnv = dotenv.env['SOCKET_URL'];
    final fallback = fromEnv != null && fromEnv.isNotEmpty
        ? fromEnv
        : 'http://localhost:5001';
    return rewriteLocalhostForAndroid(fallback);
  }

  static String rewriteLocalhostForAndroid(String url) {
    if (kIsWeb) return url;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return url
          .replaceAll('localhost', '10.0.2.2')
          .replaceAll('127.0.0.1', '10.0.2.2');
    }
    return url;
  }

  static Map<String, dynamic> asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  static List<dynamic> asList(dynamic data, [String? key]) {
    if (data is List) return data;
    if (data is Map && key != null && data[key] is List) {
      return data[key] as List;
    }
    return const [];
  }

  static Map<String, dynamic> unwrapSocketPayload(dynamic data) {
    final map = asMap(data);
    if (map['data'] is Map) {
      return asMap(map['data']);
    }
    return map;
  }

  ApiException handleError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return ApiException('No internet connection. Please check your network.');
    }

    final data = error.response?.data;
    if (data is Map<String, dynamic> || data is Map) {
      final map = asMap(data);
      final message = map['message'] ?? 'Something went wrong';
      final errors = map['errors'] as List?;
      return ApiException(
        message.toString(),
        statusCode: error.response?.statusCode,
        errors: errors?.map((e) => asMap(e)).toList(),
      );
    }

    return ApiException('Something went wrong. Please try again.');
  }
}
