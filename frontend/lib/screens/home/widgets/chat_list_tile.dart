import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:frontend/models/chat.dart';
import 'package:frontend/models/message.dart';
import 'package:frontend/utils/date_formatter.dart';
import '../../../core/constants/app_colors.dart';

class ChatListTile extends StatelessWidget {
  final ChatModel chat;
  final String currentUserId;
  final VoidCallback onTap;

  const ChatListTile({
    super.key,
    required this.chat,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final otherUser = chat.otherParticipant(currentUserId);
    final lastMessage = chat.lastMessage;
    final isUnread =
        lastMessage != null &&
        !lastMessage.isRead &&
        lastMessage.senderId != currentUserId;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            backgroundImage: otherUser.avatar.isNotEmpty
                ? CachedNetworkImageProvider(otherUser.avatar)
                : null,
            child: otherUser.avatar.isEmpty
                ? Text(
                    otherUser.name.isNotEmpty
                        ? otherUser.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          if (otherUser.isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: AppColors.online,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        otherUser.name,
        style: TextStyle(
          fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
        ),
      ),
      subtitle: Text(
        _previewText(lastMessage),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isUnread ? AppColors.textPrimary : AppColors.textSecondary,
          fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            chat.lastMessage != null
                ? DateFormatter.chatListTimestamp(chat.lastMessage!.createdAt)
                : '',
            style: TextStyle(
              fontSize: 12,
              color: isUnread ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isUnread) ...[
            const SizedBox(height: 6),
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _previewText(MessageModel? lastMessage) {
    if (lastMessage == null) return 'Say hi 👋';

    final prefix = lastMessage.senderId == currentUserId ? 'You: ' : '';

    switch (lastMessage.messageType) {
      case MessageType.image:
        return '$prefix📷 Photo';
      case MessageType.file:
        return '$prefix📎 File';
      case MessageType.emoji:
      case MessageType.text:
        return '$prefix${lastMessage.message}';
    }
  }
}
