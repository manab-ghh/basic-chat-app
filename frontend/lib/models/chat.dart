import 'package:equatable/equatable.dart';
import 'package:frontend/models/message.dart';
import 'package:frontend/models/user.dart';

class ChatModel extends Equatable {
  final String id;
  final List<UserModel> participants;
  final MessageModel? lastMessage;
  final DateTime updatedAt;

  const ChatModel({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.updatedAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      participants: (json['participants'] as List? ?? []).map((p) {
        if (p is Map) {
          return UserModel.fromJson(Map<String, dynamic>.from(p));
        }
        return UserModel(
          id: p.toString(),
          name: 'Unknown',
          email: '',
          avatar: '',
          isOnline: false,
        );
      }).toList(),
      lastMessage: json['lastMessage'] is Map
          ? MessageModel.fromJson(
              Map<String, dynamic>.from(json['lastMessage'] as Map),
            )
          : null,
      updatedAt:
          DateTime.tryParse(
            (json['updatedAt'] ?? json['lastMessageAt'] ?? '').toString(),
          ) ??
          DateTime.now(),
    );
  }

  /// Returns the "other" participant relative to the currently logged-in user —
  /// used everywhere in the UI since chats are always displayed 1-to-1.
  UserModel otherParticipant(String currentUserId) {
    return participants.firstWhere(
      (p) => p.id != currentUserId,
      orElse: () => participants.isNotEmpty
          ? participants.first
          : const UserModel(
              id: '',
              name: 'Unknown',
              email: '',
              avatar: '',
              isOnline: false,
            ),
    );
  }

  @override
  List<Object?> get props => [id, participants, lastMessage, updatedAt];
}
