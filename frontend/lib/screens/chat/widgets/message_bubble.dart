import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:frontend/models/message.dart';
import 'package:frontend/utils/date_formatter.dart';
import '../../../core/constants/app_colors.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const MessageBubble({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.bubbleSent : AppColors.bubbleReceived,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isMe ? 14 : 2),
            bottomRight: Radius.circular(isMe ? 2 : 14),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildContent(),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormatter.messageTimestamp(message.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead
                        ? Icons.done_all
                        : (message.delivered ? Icons.done_all : Icons.done),
                    size: 15,
                    color: message.isRead
                        ? Colors.blue
                        : AppColors.textSecondary,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (message.messageType) {
      case MessageType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: message.fileUrl,
            width: 220,
            fit: BoxFit.cover,
            placeholder: (context, url) => const SizedBox(
              width: 220,
              height: 160,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            errorWidget: (context, url, error) => const SizedBox(
              width: 220,
              height: 160,
              child: Icon(Icons.broken_image_outlined),
            ),
          ),
        );
      case MessageType.file:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file_outlined, size: 22),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message.fileName.isNotEmpty ? message.fileName : 'File',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      case MessageType.emoji:
        return Text(message.message, style: const TextStyle(fontSize: 32));
      case MessageType.text:
        return Text(message.message, style: const TextStyle(fontSize: 15.5));
    }
  }
}
