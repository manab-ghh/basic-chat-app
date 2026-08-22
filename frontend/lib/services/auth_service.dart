import 'package:dio/dio.dart';
import 'package:frontend/core/api/api_client.dart';
import 'package:frontend/core/api/api_endpoints.dart';
import 'package:frontend/models/user.dart';

/// Handles raw REST calls for authentication. Returns plain data —
/// no business logic here, that lives in the provider/repository layer.
class AuthService {
  final ApiClient _apiClient;
  AuthService(this._apiClient);

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.register,
        data: {'name': name, 'email': email, 'password': password},
      );
      final data = Map<String, dynamic>.from(response.data['data'] as Map);
      return {
        'user': UserModel.fromJson(Map<String, dynamic>.from(data['user'] as Map)),
        'token': data['token'] as String,
      };
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );
      final data = Map<String, dynamic>.from(response.data['data'] as Map);
      return {
        'user': UserModel.fromJson(Map<String, dynamic>.from(data['user'] as Map)),
        'token': data['token'] as String,
      };
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.me);
      return UserModel.fromJson(
        Map<String, dynamic>.from(response.data['data']['user'] as Map),
      );
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.post(ApiEndpoints.logout);
    } on DioException catch (e) {
      // Logout failing server-side shouldn't block local logout
      throw _apiClient.handleError(e);
    }
  }
}
