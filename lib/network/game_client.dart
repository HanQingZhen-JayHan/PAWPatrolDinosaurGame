import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:pup_dash/models/message.dart';

typedef ClientMessageHandler = void Function(GameMessage message);

class GameClient {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  ClientMessageHandler? onMessage;
  void Function()? onConnected;
  void Function()? onDisconnected;

  bool _connected = false;
  bool get isConnected => _connected;

  Future<void> connect(String wsUrl) async {
    try {
      final uri = Uri.parse(wsUrl);
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
      _connected = true;
      onConnected?.call();

      _subscription = _channel!.stream.listen(
        (data) {
          if (data is String) {
            try {
              final message = GameMessage.decode(data);
              onMessage?.call(message);
            } catch (_) {}
          }
        },
        onDone: () {
          _connected = false;
          onDisconnected?.call();
        },
        onError: (_) {
          _connected = false;
          onDisconnected?.call();
        },
      );
    } catch (e) {
      _connected = false;
      rethrow;
    }
  }

  void send(GameMessage message) {
    if (_connected && _channel != null) {
      _channel!.sink.add(message.encode());
    }
  }

  Future<void> disconnect() async {
    _connected = false;
    await _subscription?.cancel();
    await _channel?.sink.close();
    _channel = null;
  }
}
