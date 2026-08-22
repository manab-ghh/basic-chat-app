import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'environment.dart';

class SocketClient {
  static SocketClient? _instance;
  late io.Socket socket;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  SocketClient._internal();

  static Future<SocketClient> getInstance() async {
    if (_instance == null) {
      _instance = SocketClient._internal();
      await _instance!._initSocket();
    }
    return _instance!;
  }

  Future<void> _initSocket() async {
    final token = await _storage.read(key: 'token');

    socket = io.io(Environment.socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {'token': token},
    });

    socket.onConnect((_) {
      debugPrint('Socket connected');
    });

    socket.onDisconnect((_) {
      debugPrint('Socket disconnected');
    });

    socket.onConnectError((data) {
      debugPrint('Socket connection error: $data');
    });
  }

  void connect() {
    if (!socket.connected) {
      socket.connect();
    }
  }

  void disconnect() {
    if (socket.connected) {
      socket.disconnect();
    }
  }

  void emit(String event, dynamic data) {
    if (socket.connected) {
      socket.emit(event, data);
    }
  }

  void on(String event, Function(dynamic) callback) {
    socket.on(event, callback);
  }

  void off(String event) {
    socket.off(event);
  }
}
