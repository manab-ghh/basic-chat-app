import 'package:dio/dio.dart';
import 'package:frontend/core/api/api_client.dart';
import 'package:frontend/core/api/api_endpoints.dart';
import 'package:frontend/models/user.dart';

class UserService {
  final ApiClient _apiClient;
  UserService(this._apiClient);

  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.users);
      final users = response.data['data']['users'] as List;
      return users
          .map((u) => UserModel.fromJson(Map<String, dynamic>.from(u as Map)))
          .toList();
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.searchUsers,
        queryParameters: {'q': query},
      );
      final users = response.data['data']['users'] as List;
      return users
          .map((u) => UserModel.fromJson(Map<String, dynamic>.from(u as Map)))
          .toList();
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  Future<UserModel> updateProfile({String? name, String? avatar}) async {
    try {
      final payload = <String, dynamic>{};
      if (name != null) payload['name'] = name;
      if (avatar != null) payload['avatar'] = avatar;

      final response = await _apiClient.dio.put(
        ApiEndpoints.updateProfile,
        data: payload,
      );
      return UserModel.fromJson(
        Map<String, dynamic>.from(response.data['data']['user'] as Map),
      );
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  Future<UserModel> uploadAvatar(String path) async {
    try {
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(path),
      });
      final response = await _apiClient.dio.post(
        ApiEndpoints.uploadAvatar,
        data: formData,
      );
      return UserModel.fromJson(
        ApiClient.asMap(response.data['data']['user']),
      );
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }
}
