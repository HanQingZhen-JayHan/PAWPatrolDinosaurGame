import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:pup_dash/models/message.dart';

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
  String? _lanIp;

  String? get ip => _ip;
  int? get port => _port;
  bool get isRunning => _server != null;
  int get clientCount => _clients.length;

  /// Set the LAN IP for display in the join page (since we bind to 0.0.0.0).
  set lanIp(String? value) => _lanIp = value;
  String get _displayIp => _lanIp ?? _ip ?? 'localhost';
  String get httpUrl => 'http://$_displayIp:$_port';

  Future<void> start({required String ip, required int port}) async {
    _ip = ip;
    _port = port;

    final wsHandler = webSocketHandler((WebSocketChannel channel) {
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

    // Route: /ws → WebSocket, / → HTML join page
    FutureOr<shelf.Response> router(shelf.Request request) {
      if (request.url.path == 'ws') {
        return wsHandler(request);
      }
      return _serveJoinPage(request);
    }

    final pipeline = const shelf.Pipeline()
        .addMiddleware(shelf.logRequests())
        .addHandler(router);

    _server = await shelf_io.serve(pipeline, ip, port);
  }

  shelf.Response _serveJoinPage(shelf.Request request) {
    final wsUrl = 'ws://$_displayIp:$_port/ws';
    final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Pup Dash - Join Game</title>
  <style>
    * { box-sizing: border-box; }
    body { font-family: -apple-system, sans-serif; text-align: center;
           background: linear-gradient(180deg, #42A5F5 0%, #1A237E 100%);
           color: white; padding: 40px 20px; margin: 0; min-height: 100vh; }
    h1 { color: #FFD600; font-size: 32px; margin: 8px 0; }
    h2 { font-size: 18px; font-weight: normal; color: #ccc; margin: 0 0 24px; }
    .card { background: rgba(255,255,255,0.15); border-radius: 20px;
            padding: 28px 24px; margin: 20px auto; max-width: 400px;
            backdrop-filter: blur(10px); }
    code { background: rgba(0,0,0,0.3); padding: 10px 20px; border-radius: 10px;
           font-size: 20px; display: inline-block; margin: 8px 0;
           word-break: break-all; letter-spacing: 1px; }
    .step { margin: 16px 0; font-size: 16px; line-height: 1.5; }
    .step b { color: #FFD600; }
    .paw { font-size: 56px; animation: bounce 2s ease infinite; }
    @keyframes bounce {
      0%, 100% { transform: translateY(0); }
      50% { transform: translateY(-12px); }
    }
    .spinner { display: inline-block; width: 28px; height: 28px;
               border: 3px solid rgba(255,255,255,0.3);
               border-top-color: #FFD600; border-radius: 50%;
               animation: spin 0.8s linear infinite; margin: 16px 0 8px; }
    @keyframes spin { to { transform: rotate(360deg); } }
    .loading-text { color: #FFD600; font-size: 14px; }
    .ws-info { margin-top: 20px; font-size: 12px; color: rgba(255,255,255,0.4); }
    .ws-info code { font-size: 12px; padding: 4px 10px; }
  </style>
</head>
<body>
  <div class="paw">🐾</div>
  <h1>PUP DASH</h1>
  <h2>Join the game!</h2>
  <div class="card">
    <div class="spinner"></div>
    <div class="loading-text">Connecting to game...</div>
    <div class="step"><b>Step 1:</b> Open the Pup Dash app on your phone</div>
    <div class="step"><b>Step 2:</b> Tap <b>"Join Game"</b></div>
    <div class="step"><b>Step 3:</b> Enter this address:</div>
    <code>$_displayIp:$_port</code>
    <div style="margin-top: 20px; padding: 12px; background: rgba(255,68,68,0.2);
                border-radius: 10px; font-size: 14px; color: #ff9999;">
      <b>Important:</b> Your phone must be on the <b>same WiFi network</b> as the host PC!
    </div>
    <div class="ws-info">
      WebSocket: <code>$wsUrl</code>
    </div>
  </div>
</body>
</html>
''';
    return shelf.Response.ok(html,
        headers: {'content-type': 'text/html; charset=utf-8'});
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
