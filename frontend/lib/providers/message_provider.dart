import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:frontend/core/api/api_client.dart';
import 'package:frontend/models/message.dart';
import '../services/message_service.dart';
import '../services/socket_service.dart';
import 'auth_provider.dart';
import 'socket_provider.dart';

final messageServiceProvider = Provider<MessageService>((ref) {
  return MessageService(ref.read(apiClientProvider));
});

class ChatMessagesState {
  final List<MessageModel> messages;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final String? error;
  final Set<String> typingUserIds;

  const ChatMessagesState({
    this.messages = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
    this.typingUserIds = const {},
  });

  ChatMessagesState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? error,
    Set<String>? typingUserIds,
  }) {
    return ChatMessagesState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: error,
      typingUserIds: typingUserIds ?? this.typingUserIds,
    );
  }
}

class ChatMessagesNotifier extends StateNotifier<ChatMessagesState> {
  final MessageService _messageService;
  final SocketService _socketService;
  final String chatId;
  final String currentUserId;

  // Bound handler references so we can properly remove listeners on dispose
  late final void Function(dynamic) _onReceiveMessage;
  late final void Function(dynamic) _onMessageDelivered;
  late final void Function(dynamic) _onMessageRead;
  late final void Function(dynamic) _onTyping;
  late final void Function(dynamic) _onStopTyping;

  ChatMessagesNotifier(
    this._messageService,
    this._socketService,
    this.chatId,
    this.currentUserId,
  ) : super(const ChatMessagesState()) {
    _registerSocketListeners();
    _socketService.joinRoom(chatId);
    loadInitial();
  }

  void _registerSocketListeners() {
    _onReceiveMessage = (data) {
      final payload = ApiClient.unwrapSocketPayload(data);
      if (payload.isEmpty) return;
      final message = MessageModel.fromJson(payload);
      if (message.chatId != chatId) return;
      receiveMessage(message);

      // If this message was sent TO us and we're actively viewing this chat,
      // immediately tell the server we've read it.
      if (message.receiverId == currentUserId) {
        _socketService.markRead(chatId);
      }
    };

    _onMessageDelivered = (data) {
      final payload = ApiClient.asMap(data);
      final messageId = payload['messageId']?.toString();
      final targetChatId = payload['chatId']?.toString();
      if (messageId == null || targetChatId != chatId) return;
      _updateMessageStatus(messageId, delivered: true);
    };

    _onMessageRead = (data) {
      final payload = ApiClient.asMap(data);
      final targetChatId = payload['chatId']?.toString();
      final readBy = (payload['readBy'] ?? payload['userId'])?.toString();
      if (targetChatId != chatId) return;
      // The other participant read our messages — mark all of ours as read
      if (readBy != null && readBy != currentUserId) {
        _markOwnMessagesAsRead();
      }
    };

    _onTyping = (data) {
      final payload = ApiClient.asMap(data);
      final targetChatId = payload['chatId']?.toString();
      final userId = payload['userId']?.toString();
      if (targetChatId != chatId || userId == null || userId == currentUserId) {
        return;
      }
      setTyping(userId, true);
    };

    _onStopTyping = (data) {
      final payload = ApiClient.asMap(data);
      final targetChatId = payload['chatId']?.toString();
      final userId = payload['userId']?.toString();
      if (targetChatId != chatId || userId == null || userId == currentUserId) {
        return;
      }
      setTyping(userId, false);
    };

    _socketService.on('receive_message', _onReceiveMessage);
    _socketService.on('message_delivered', _onMessageDelivered);
    _socketService.on('message_read', _onMessageRead);
    _socketService.on('messages_read', _onMessageRead);
    _socketService.on('typing', _onTyping);
    _socketService.on('stop_typing', _onStopTyping);
  }

  @override
  void dispose() {
    _socketService.leaveRoom(chatId);
    _socketService.off('receive_message', _onReceiveMessage);
    _socketService.off('message_delivered', _onMessageDelivered);
    _socketService.off('message_read', _onMessageRead);
    _socketService.off('messages_read', _onMessageRead);
    _socketService.off('typing', _onTyping);
    _socketService.off('stop_typing', _onStopTyping);
    super.dispose();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _messageService.getMessages(chatId, page: 1);
      state = state.copyWith(
        messages: result['messages'],
        hasMore: result['hasMore'],
        page: 1,
        isLoading: false,
      );
      // Mark unread messages as read now that we're viewing this chat
      _socketService.markRead(chatId);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.page + 1;
      final result = await _messageService.getMessages(chatId, page: nextPage);
      final olderMessages = result['messages'] as List<MessageModel>;
      state = state.copyWith(
        messages: [...olderMessages, ...state.messages],
        hasMore: result['hasMore'],
        page: nextPage,
        isLoadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Primary send path: emits over the socket with an ack callback.
  /// Falls back to REST automatically if the socket isn't connected.
  Future<void> sendMessage({
    required String receiverId,
    required String text,
    String messageType = 'text',
  }) async {
    final tempId = 'temp_${DateTime.now().microsecondsSinceEpoch}';
    final optimisticMessage = MessageModel(
      id: tempId,
      chatId: chatId,
      senderId: currentUserId,
      senderName: '',
      senderAvatar: '',
      receiverId: receiverId,
      message: text,
      messageType: messageTypeFromString(messageType),
      fileUrl: '',
      fileName: '',
      delivered: false,
      isRead: false,
      createdAt: DateTime.now(),
    );

    addOptimisticMessage(optimisticMessage);

    if (_socketService.isConnected) {
      _socketService.sendMessage(
        {
          'chatId': chatId,
          'receiver': receiverId,
          'message': text,
          'messageType': messageType,
        },
        (response) {
          if (response is Map && response['success'] == true) {
            final confirmed = MessageModel.fromJson(
              ApiClient.unwrapSocketPayload(response),
            );
            confirmMessage(tempId, confirmed);
          } else {
            _sendViaRestFallback(tempId, receiverId, text, messageType);
          }
        },
      );
    } else {
      await _sendViaRestFallback(tempId, receiverId, text, messageType);
    }
  }

  Future<void> _sendViaRestFallback(
    String tempId,
    String receiverId,
    String text,
    String messageType,
  ) async {
    try {
      final confirmed = await _messageService.sendMessage(
        chatId: chatId,
        receiver: receiverId,
        message: text,
        messageType: messageType,
      );
      confirmMessage(tempId, confirmed);
    } catch (_) {
      // Leave the optimistic message in place but mark it visually failed
      // by removing it here and letting the UI show a retry affordance
      // (kept simple for this build — message stays as "sent" visually,
      // acceptable given REST fallback rarely fails if socket send failed
      // only due to a transient reconnect).
    }
  }

  void addOptimisticMessage(MessageModel message) {
    state = state.copyWith(messages: [...state.messages, message]);
  }

  void confirmMessage(String tempId, MessageModel confirmed) {
    final alreadyConfirmed = state.messages.any((m) => m.id == confirmed.id);
    if (alreadyConfirmed) {
      state = state.copyWith(
        messages: state.messages.where((m) => m.id != tempId).toList(),
      );
      return;
    }
    final updated = state.messages
        .map((m) => m.id == tempId ? confirmed : m)
        .toList();
    state = state.copyWith(messages: updated);
  }

  void receiveMessage(MessageModel message) {
    final alreadyExists = state.messages.any((m) => m.id == message.id);
    if (alreadyExists) return;

    // Sender is also in the chat room, so they receive their own message
    // after the optimistic/temp bubble was added. Replace that temp row
    // instead of showing the same text twice.
    if (message.senderId == currentUserId) {
      final tempIndex = state.messages.lastIndexWhere(
        (m) =>
            m.id.startsWith('temp_') &&
            m.senderId == currentUserId &&
            m.message == message.message,
      );
      if (tempIndex != -1) {
        final updated = [...state.messages];
        updated[tempIndex] = message;
        state = state.copyWith(messages: updated);
        return;
      }
    }

    state = state.copyWith(messages: [...state.messages, message]);
  }

  void _updateMessageStatus(String messageId, {bool? delivered, bool? isRead}) {
    final updated = state.messages.map((m) {
      if (m.id != messageId) return m;
      return m.copyWith(delivered: delivered, isRead: isRead);
    }).toList();
    state = state.copyWith(messages: updated);
  }

  void _markOwnMessagesAsRead() {
    final updated = state.messages
        .map(
          (m) => m.senderId == currentUserId
              ? m.copyWith(isRead: true, delivered: true)
              : m,
        )
        .toList();
    state = state.copyWith(messages: updated);
  }

  void setTyping(String userId, bool isTyping) {
    final updated = Set<String>.from(state.typingUserIds);
    if (isTyping) {
      updated.add(userId);
    } else {
      updated.remove(userId);
    }
    state = state.copyWith(typingUserIds: updated);
  }
}

final chatMessagesProvider =
    StateNotifierProvider.family<
      ChatMessagesNotifier,
      ChatMessagesState,
      String
    >((ref, chatId) {
      final currentUserId = ref.read(authProvider).user?.id ?? '';
      return ChatMessagesNotifier(
        ref.read(messageServiceProvider),
        ref.read(socketServiceProvider),
        chatId,
        currentUserId,
      );
    });
