import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  /// Formats a message/chat timestamp WhatsApp-style:
  /// today -> "14:32", yesterday -> "Yesterday", this week -> "Mon",
  /// older -> "12/03/2025"
  static String chatListTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final difference = today.difference(date).inDays;

    if (difference == 0) return DateFormat.Hm().format(dateTime);
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return DateFormat.E().format(dateTime);
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  static String messageTimestamp(DateTime dateTime) =>
      DateFormat.Hm().format(dateTime);

  /// "last seen" style text for a user's presence.
  static String lastSeen(DateTime? lastSeenAt, {required bool isOnline}) {
    if (isOnline) return 'Online';
    if (lastSeenAt == null) return '';

    final now = DateTime.now();
    final diff = now.difference(lastSeenAt);

    if (diff.inMinutes < 1) return 'Last seen just now';
    if (diff.inMinutes < 60) return 'Last seen ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Last seen ${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Last seen yesterday';
    if (diff.inDays < 7) return 'Last seen ${diff.inDays}d ago';
    return 'Last seen ${DateFormat('dd/MM/yyyy').format(lastSeenAt)}';
  }
}
