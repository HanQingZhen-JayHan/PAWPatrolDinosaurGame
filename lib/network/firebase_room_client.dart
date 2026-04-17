import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';

import 'package:pup_dash/models/message.dart';

/// Controller-side Firebase room client.
/// Replaces the WebSocket GameClient.
class FirebaseRoomClient {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final _uuid = const Uuid();

  DatabaseReference? _roomRef;
  String? _roomCode;
  String? _playerId;

  StreamSubscription? _broadcastSub;
  StreamSubscription? _personalMsgSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _playerDataSub;

  void Function(GameMessage message)? onMessage;
  void Function()? onConnected;
  void Function()? onDisconnected;

  bool _connected = false;
  bool get isConnected => _connected;
  String? get playerId => _playerId;
  String? get roomCode => _roomCode;

  /// Join a room by code.
  Future<void> connect(String roomCode) async {
    _roomCode = roomCode.toUpperCase().trim();
    _roomRef = _db.ref('rooms/$_roomCode');

    // Verify room exists
    final snapshot = await _roomRef!.child('host').get();
    if (!snapshot.exists) {
      throw Exception('Room "$_roomCode" not found');
    }

    _playerId = _uuid.v4();
    _connected = true;
    onConnected?.call();

    // Listen for broadcast messages from host
    _broadcastSub = _roomRef!.child('broadcast').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return;
      final type = data['type'] as String?;
      if (type == null) return;
      final payload = _castPayload(data['payload']);
      onMessage?.call(GameMessage(type: type, payload: payload));
    });

    // Listen for personal messages from host
    _personalMsgSub =
        _roomRef!.child('messages/$_playerId').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return;
      final type = data['type'] as String?;
      if (type == null) return;
      final payload = _castPayload(data['payload']);
      onMessage?.call(GameMessage(type: type, payload: payload));
    });

    // Listen for game state changes
    _stateSub = _roomRef!.child('state').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return;
      final phase = data['phase'] as String?;
      if (phase == 'countdown') {
        final countdown = data['countdownValue'] as int? ?? 0;
        onMessage?.call(GameMessage.gameStarting(countdown));
      } else if (phase == 'playing') {
        onMessage?.call(GameMessage.gameStarted());
      }
    });

    // Listen for own player data changes (score, lives, etc.)
    _playerDataSub =
        _roomRef!.child('players/$_playerId').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        // Player removed from room
        _connected = false;
        onDisconnected?.call();
        return;
      }
    });

    // Set up disconnect cleanup
    _roomRef!.child('players/$_playerId').onDisconnect().remove();
    _roomRef!.child('inputs/$_playerId').onDisconnect().remove();
  }

  /// Join the room with a player name.
  Future<void> join(String playerName) async {
    if (_roomRef == null || _playerId == null) return;
    await _roomRef!.child('players/$_playerId').set({
      'name': playerName,
      'character': null,
      'ready': false,
      'lives': 3,
      'score': 0,
      'alive': true,
    });
  }

  /// Send an input/action to the host via Firebase.
  Future<void> send(GameMessage message) async {
    if (_roomRef == null || _playerId == null) return;
    await _roomRef!.child('inputs/$_playerId').set({
      'type': message.type,
      ...message.payload,
      'timestamp': ServerValue.timestamp,
    });
  }

  Future<void> disconnect() async {
    _connected = false;
    await _broadcastSub?.cancel();
    await _personalMsgSub?.cancel();
    await _stateSub?.cancel();
    await _playerDataSub?.cancel();

    // Clean up player data
    if (_roomRef != null && _playerId != null) {
      await _roomRef!.child('players/$_playerId').remove();
      await _roomRef!.child('inputs/$_playerId').remove();
      await _roomRef!.child('messages/$_playerId').remove();
    }

    _roomRef = null;
    _playerId = null;
    _roomCode = null;
  }

  Map<String, dynamic> _castPayload(dynamic raw) {
    if (raw is Map) {
      return raw.map((k, v) {
        if (v is Map) {
          return MapEntry(k.toString(), _castPayload(v));
        }
        if (v is List) {
          return MapEntry(k.toString(), _castList(v));
        }
        return MapEntry(k.toString(), v);
      });
    }
    return {};
  }

  List<dynamic> _castList(List<dynamic> raw) {
    return raw.map((v) {
      if (v is Map) return _castPayload(v);
      if (v is List) return _castList(v);
      return v;
    }).toList();
  }
}
