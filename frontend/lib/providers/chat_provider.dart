import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:frontend/models/chat.dart';
import 'package:frontend/models/message.dart';
import '../services/chat_service.dart';
import 'auth_provider.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(ref.read(apiClientProvider));
});

class ChatListNotifier extends StateNotifier<AsyncValue<List<ChatModel>>> {
  final ChatService _chatService;
  ChatListNotifier(this._chatService) : super(const AsyncValue.data([]));

  Future<void> loadChats() async {
    state = const AsyncValue.loading();
    try {
      final chats = await _chatService.getChats();
      state = AsyncValue.data(chats);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() {
    state = const AsyncValue.data([]);
  }

  Future<void> refresh() async {
    try {
      final chats = await _chatService.getChats();
      state = AsyncValue.data(chats);
    } catch (_) {}
  }

  Future<ChatModel> openOrCreateChat(String otherUserId) async {
    final chat = await _chatService.createOrGetChat(otherUserId);

    state.whenData((chats) {
      final exists = chats.any((c) => c.id == chat.id);
      if (!exists) {
        state = AsyncValue.data([chat, ...chats]);
      }
    });

    return chat;
  }

  void updateChatWithMessage(String chatId, MessageModel message) {
    state.whenData((chats) {
      final index = chats.indexWhere((c) => c.id == chatId);
      if (index == -1) {
        return;
      }

      final updatedChat = ChatModel(
        id: chats[index].id,
        participants: chats[index].participants,
        lastMessage: message,
        updatedAt: message.createdAt,
      );

      final newList = [...chats]..removeAt(index);
      newList.insert(0, updatedChat);
      state = AsyncValue.data(newList);
    });
  }
}

final chatListProvider =
    StateNotifierProvider<ChatListNotifier, AsyncValue<List<ChatModel>>>((ref) {
      final notifier = ChatListNotifier(ref.read(chatServiceProvider));
      ref.listen<AuthState>(authProvider, (previous, next) {
        if (next.status == AuthStatus.authenticated &&
            previous?.status != AuthStatus.authenticated) {
          notifier.loadChats();
        } else if (next.status == AuthStatus.unauthenticated) {
          notifier.reset();
        }
      }, fireImmediately: true);
      return notifier;
    });
