import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:paw_patrol_runner/models/message.dart';

typedef MessageHandler = void Function(String clientId, GameMessage message);

class GameServer {
  HttpServer? _server;
  final Map<String, WebSocketChannel> _clients = {};
  final _uuid = const Uuid();

  MessageHandler? onMessage;
  void Function(String clientId)? onClientConnected;
  void Function(String clientId)? onClientDisconnected;

  String? _ip;
  int? _port;

  String? get ip => _ip;
  int? get port => _port;
  bool get isRunning => _server != null;
  int get clientCount => _clients.length;

  Future<void> start({required String ip, required int port}) async {
    _ip = ip;
    _port = port;

    final handler = webSocketHandler((WebSocketChannel channel) {
      final clientId = _uuid.v4();
      _clients[clientId] = channel;
      onClientConnected?.call(clientId);

      channel.stream.listen(
        (data) {
          if (data is String) {
            try {
              final message = GameMessage.decode(data);
              onMessage?.call(clientId, message);
            } catch (e) {
              // Ignore malformed messages
            }
          }
        },
        onDone: () {
          _clients.remove(clientId);
          onClientDisconnected?.call(clientId);
        },
        onError: (_) {
          _clients.remove(clientId);
          onClientDisconnected?.call(clientId);
        },
      );
    });

    final pipeline = const shelf.Pipeline()
        .addMiddleware(shelf.logRequests())
        .addHandler(handler);

    _server = await shelf_io.serve(pipeline, ip, port);
  }

  void sendTo(String clientId, GameMessage message) {
    final channel = _clients[clientId];
    if (channel != null) {
      try {
        channel.sink.add(message.encode());
      } catch (_) {
        _clients.remove(clientId);
      }
    }
  }

  void broadcast(GameMessage message) {
    final encoded = message.encode();
    final deadClients = <String>[];
    for (final entry in _clients.entries) {
      try {
        entry.value.sink.add(encoded);
      } catch (_) {
        deadClients.add(entry.key);
      }
    }
    for (final id in deadClients) {
      _clients.remove(id);
      onClientDisconnected?.call(id);
    }
  }

  void disconnectClient(String clientId) {
    final channel = _clients.remove(clientId);
    channel?.sink.close();
  }

  Future<void> stop() async {
    for (final channel in _clients.values) {
      try {
        await channel.sink.close();
      } catch (_) {}
    }
    _clients.clear();
    await _server?.close(force: true);
    _server = null;
    _ip = null;
    _port = null;
  }
}
