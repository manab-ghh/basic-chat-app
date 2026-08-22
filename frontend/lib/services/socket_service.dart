import 'package:flutter/foundation.dart';
import 'package:frontend/core/api/api_client.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Thin wrapper around socket_io_client. Owns the single socket connection
/// for the whole app lifecycle (connected once after login, disconnected on logout).
/// Screens/providers subscribe to specific events rather than touching the
/// raw socket directly, keeping Socket.IO details out of the UI layer.
class SocketService {
  io.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  void connect(String token) {
    // Reuse the existing client so event listeners stay attached.
    // Recreating the socket while a handshake is in flight would drop them.
    if (_socket != null) {
      if (!_socket!.connected) {
        _socket!.auth = {'token': token};
        _socket!.connect();
      }
      return;
    }

    final socketUrl = ApiClient.resolveSocketUrl();

    _socket = io.io(
      socketUrl,
      io.OptionBuilder()
          .setTransports(kIsWeb ? ['polling', 'websocket'] : ['websocket'])
          .enableForceNew()
          .disableAutoConnect()
          .setAuth({'token': token})
          .setReconnectionAttempts(10)
          .setReconnectionDelay(2000)
          .build(),
    );

    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  // ─── Emit helpers ────────────────────────────────────────────
  void joinRoom(String chatId) =>
      _socket?.emit('join_room', {'chatId': chatId});
  void leaveRoom(String chatId) =>
      _socket?.emit('leave_room', {'chatId': chatId});

  void sendMessage(Map<String, dynamic> payload, void Function(dynamic) ack) {
    _socket?.emitWithAck('send_message', payload, ack: ack);
  }

  void emitTyping(String chatId, String receiver) =>
      _socket?.emit('typing', {'chatId': chatId, 'receiver': receiver});

  void emitStopTyping(String chatId, String receiver) =>
      _socket?.emit('stop_typing', {'chatId': chatId, 'receiver': receiver});

  void markRead(String chatId) =>
      _socket?.emit('mark_read', {'chatId': chatId});

  void checkOnlineStatus(String targetUserId) =>
      _socket?.emit('check_online_status', {'targetUserId': targetUserId});

  // ─── Listen helpers ──────────────────────────────────────────
  void on(String event, void Function(dynamic) handler) =>
      _socket?.on(event, handler);
  void off(String event, [void Function(dynamic)? handler]) =>
      _socket?.off(event, handler);

  void onConnect(void Function() handler) =>
      _socket?.onConnect((_) => handler());
  void onDisconnect(void Function() handler) =>
      _socket?.onDisconnect((_) => handler());
  void onConnectError(void Function(dynamic) handler) =>
      _socket?.onConnectError(handler);
}
