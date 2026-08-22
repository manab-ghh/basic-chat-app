import 'package:dio/dio.dart';
import 'package:frontend/core/api/api_client.dart';
import 'package:frontend/core/api/api_endpoints.dart';
import 'package:frontend/models/message.dart';

class MessageService {
  final ApiClient _apiClient;
  MessageService(this._apiClient);

  Future<Map<String, dynamic>> getMessages(
    String chatId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.messages(chatId),
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = response.data['data'];
      final messages = (data['messages'] as List)
          .map((m) => MessageModel.fromJson(Map<String, dynamic>.from(m as Map)))
          .toList();
      return {
        'messages': messages,
        'hasMore': data['pagination']['hasMore'] as bool,
      };
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  /// REST fallback for sending — primary path is the socket event (Step 12).
  Future<MessageModel> sendMessage({
    required String chatId,
    required String receiver,
    required String message,
    String messageType = 'text',
    String fileUrl = '',
    String fileName = '',
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.sendMessage,
        data: {
          'chatId': chatId,
          'receiver': receiver,
          'message': message,
          'messageType': messageType,
          'fileUrl': fileUrl,
          'fileName': fileName,
        },
      );
      return MessageModel.fromJson(
        Map<String, dynamic>.from(response.data['data']['message'] as Map),
      );
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }
}
