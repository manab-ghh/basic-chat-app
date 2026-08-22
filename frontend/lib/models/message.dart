import 'package:equatable/equatable.dart';

enum MessageType { text, emoji, image, file }

MessageType messageTypeFromString(String? value) {
  switch (value) {
    case 'emoji':
      return MessageType.emoji;
    case 'image':
      return MessageType.image;
    case 'file':
      return MessageType.file;
    default:
      return MessageType.text;
  }
}

String messageTypeToString(MessageType type) => type.name;

class MessageModel extends Equatable {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String receiverId;
  final String message;
  final MessageType messageType;
  final String fileUrl;
  final String fileName;
  final bool delivered;
  final bool isRead;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.receiverId,
    required this.message,
    required this.messageType,
    required this.fileUrl,
    required this.fileName,
    required this.delivered,
    required this.isRead,
    required this.createdAt,
  });

  static String _idOf(dynamic value) {
    if (value == null) return '';
    if (value is Map) {
      return _idOf(value['_id'] ?? value['id']);
    }
    return value.toString();
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final payload = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    final sender = payload['sender'];
    final receiver = payload['receiver'];

    return MessageModel(
      id: _idOf(payload['_id'] ?? payload['id']),
      chatId: _idOf(payload['chatId'] ?? json['chatId']),
      senderId: _idOf(sender),
      senderName: sender is Map ? (sender['name'] ?? '').toString() : '',
      senderAvatar: sender is Map ? (sender['avatar'] ?? '').toString() : '',
      receiverId: _idOf(receiver),
      message: (payload['message'] ?? '').toString(),
      messageType: messageTypeFromString(
        (payload['messageType'] ?? json['messageType'])?.toString(),
      ),
      fileUrl: (payload['fileUrl'] ?? '').toString(),
      fileName: (payload['fileName'] ?? '').toString(),
      delivered: payload['delivered'] == true,
      isRead: payload['isRead'] == true,
      createdAt:
          DateTime.tryParse((payload['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  MessageModel copyWith({bool? delivered, bool? isRead}) {
    return MessageModel(
      id: id,
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      receiverId: receiverId,
      message: message,
      messageType: messageType,
      fileUrl: fileUrl,
      fileName: fileName,
      delivered: delivered ?? this.delivered,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    chatId,
    senderId,
    message,
    delivered,
    isRead,
    createdAt,
  ];
}
