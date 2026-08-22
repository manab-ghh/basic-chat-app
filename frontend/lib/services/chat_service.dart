import 'package:dio/dio.dart';
import 'package:frontend/core/api/api_client.dart';
import 'package:frontend/core/api/api_endpoints.dart';
import 'package:frontend/models/chat.dart';

class ChatService {
  final ApiClient _apiClient;
  ChatService(this._apiClient);

  Future<List<ChatModel>> getChats() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.chats);
      final chats = response.data['data']['chats'] as List;
      return chats
          .map((c) => ChatModel.fromJson(Map<String, dynamic>.from(c as Map)))
          .toList();
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  Future<ChatModel> createOrGetChat(String otherUserId) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.chats,
        data: {'userId': otherUserId},
      );
      return ChatModel.fromJson(
        Map<String, dynamic>.from(response.data['data']['chat'] as Map),
      );
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }
}
