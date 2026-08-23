import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:frontend/core/api/api_client.dart';
import 'package:frontend/models/message.dart';
import '../services/socket_service.dart';
import 'auth_provider.dart';
import 'chat_provider.dart';

final socketServiceProvider = Provider<SocketService>((ref) => SocketService());

final onlineUsersProvider =
    StateNotifierProvider<OnlineUsersNotifier, Set<String>>((ref) {
      return OnlineUsersNotifier();
    });

class OnlineUsersNotifier extends StateNotifier<Set<String>> {
  OnlineUsersNotifier() : super({});
  void setOnline(String userId) => state = {...state, userId};
  void setOffline(String userId) => state = {...state}..remove(userId);
  bool isOnline(String userId) => state.contains(userId);
}

/// Bootstraps the socket connection whenever the user is authenticated,
/// and tears it down on logout. Registers app-wide listeners (presence,
/// global new-message-for-chat-list) that should run regardless of which
/// screen is currently visible.
class SocketController {
  final SocketService _socketService;
  final Ref _ref;
  bool _globalListenersRegistered = false;

  SocketController(this._socketService, this._ref) {
    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        _connectAndListen();
      } else if (next.status == AuthStatus.unauthenticated) {
        _socketService.disconnect();
        _globalListenersRegistered = false;
      }
    }, fireImmediately: true);
  }

  Future<void> _connectAndListen() async {
    final storageService = _ref.read(storageServiceProvider);
    final token = await storageService.getToken();
    if (token == null) return;

    _socketService.connect(token);

    if (_globalListenersRegistered) return;
    _globalListenersRegistered = true;

    _socketService.on('user_online', (data) {
      final userId = ApiClient.asMap(data)['userId']?.toString();
      if (userId == null || userId.isEmpty) return;
      _ref.read(onlineUsersProvider.notifier).setOnline(userId);
    });

    _socketService.on('user_offline', (data) {
      final userId = ApiClient.asMap(data)['userId']?.toString();
      if (userId == null || userId.isEmpty) return;
      _ref.read(onlineUsersProvider.notifier).setOffline(userId);
    });

    // Keeps the Home screen's chat list live-updated even if the user
    // isn't currently inside that specific chat screen.
    _socketService.on('receive_message', (data) {
      final payload = ApiClient.unwrapSocketPayload(data);
      if (payload.isEmpty) return;
      final message = MessageModel.fromJson(payload);
      _ref
          .read(chatListProvider.notifier)
          .updateChatWithMessage(message.chatId, message);
    });
  }
}

final socketControllerProvider = Provider<SocketController>((ref) {
  return SocketController(ref.read(socketServiceProvider), ref);
});
