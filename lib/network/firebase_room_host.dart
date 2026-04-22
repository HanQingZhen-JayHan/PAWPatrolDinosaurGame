import 'dart:async';
import 'dart:math';

import 'package:firebase_database/firebase_database.dart';

import 'package:pup_dash/constants/dev_config.dart';
import 'package:pup_dash/models/message.dart';

/// Host-side Firebase Realtime Database room manager.
/// Replaces the WebSocket GameServer.
class FirebaseRoomHost {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  DatabaseReference? _roomRef;
  String? _roomCode;

  final Map<String, StreamSubscription> _playerInputSubs = {};
  StreamSubscription? _playersSub;

  void Function(String playerId, GameMessage message)? onMessage;
  void Function(String playerId)? onPlayerJoined;
  void Function(String playerId)? onPlayerLeft;

  String? get roomCode => _roomCode;
  bool get isRunning => _roomRef != null;

  /// Create a new room with a short join code.
  /// In dev mode, always uses [DevConfig.fixedRoomCode] so the QR stays valid
  /// across host restarts. Any existing room at that code is cleared first.
  Future<String> createRoom() async {
    _roomCode = DevConfig.enabled ? DevConfig.fixedRoomCode : _generateRoomCode();
    _roomRef = _db.ref('rooms/$_roomCode');

    if (DevConfig.enabled) {
      // Clear any stale state from a previous dev session at the same code
      await _roomRef!.remove();
    }

    // Initialize room structure
    await _roomRef!.set({
      'host': true,
      'createdAt': ServerValue.timestamp,
      'state': {
        'phase': 'lobby',
        'gameSpeed': 300,
        'elapsedTime': 0,
        'countdownValue': 3,
      },
      'players': {},
    });

    // Listen for player joins/leaves
    _playersSub = _roomRef!.child('players').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return;

      // Check for new players and set up input listeners
      for (final entry in data.entries) {
        final playerId = entry.key as String;
        if (!_playerInputSubs.containsKey(playerId)) {
          _onNewPlayer(playerId, entry.value as Map<dynamic, dynamic>);
        }
      }

      // Check for removed players
      final currentIds = data.keys.cast<String>().toSet();
      final tracked = _playerInputSubs.keys.toSet();
      for (final gone in tracked.difference(currentIds)) {
        _playerInputSubs[gone]?.cancel();
        _playerInputSubs.remove(gone);
        onPlayerLeft?.call(gone);
      }
    });

    return _roomCode!;
  }

  void _onNewPlayer(String playerId, Map<dynamic, dynamic> data) {
    onPlayerJoined?.call(playerId);

    // Notify with join message
    final name = data['name'] as String? ?? '';
    onMessage?.call(
      playerId,
      GameMessage.join(name),
    );

    // Listen for this player's inputs
    final sub = _roomRef!
        .child('inputs/$playerId')
        .onValue
        .listen((event) {
      final inputData = event.snapshot.value as Map<dynamic, dynamic>?;
      if (inputData == null) return;
      final action = inputData['action'] as String?;
      final type = inputData['type'] as String?;
      if (type == null) return;

      if (type == MessageType.input && action != null) {
        onMessage?.call(playerId, GameMessage.input(action));
      } else if (type == MessageType.selectCharacter) {
        final character = inputData['character'] as String? ?? '';
        onMessage?.call(playerId, GameMessage.selectCharacter(character));
      } else if (type == MessageType.ready) {
        onMessage?.call(playerId, GameMessage.ready());
      } else if (type == MessageType.requestStart) {
        onMessage?.call(playerId, GameMessage.requestStart());
      } else if (type == MessageType.requestEnd) {
        onMessage?.call(playerId, GameMessage.requestEnd());
      } else if (type == MessageType.leave) {
        onMessage?.call(playerId, GameMessage.leave());
      }
    });
    _playerInputSubs[playerId] = sub;
  }

  /// Update the game state in Firebase (host writes, controllers read).
  Future<void> updateState(Map<String, dynamic> state) async {
    await _roomRef?.child('state').update(state);
  }

  /// Update a specific player's data (score, lives, etc.).
  Future<void> updatePlayer(String playerId, Map<String, dynamic> data) async {
    await _roomRef?.child('players/$playerId').update(data);
  }

  /// Send a message to a specific player via their personal message node.
  Future<void> sendToPlayer(String playerId, GameMessage message) async {
    await _roomRef?.child('messages/$playerId').set({
      'type': message.type,
      'payload': message.payload,
      'timestamp': ServerValue.timestamp,
    });
  }

  /// Broadcast a message to all players via a shared broadcast node.
  Future<void> broadcast(GameMessage message) async {
    await _roomRef?.child('broadcast').set({
      'type': message.type,
      'payload': message.payload,
      'timestamp': ServerValue.timestamp,
    });
  }

  /// Update scores for all players.
  Future<void> updateScores(Map<String, double> scores) async {
    final updates = <String, dynamic>{};
    for (final entry in scores.entries) {
      updates['players/${entry.key}/score'] = entry.value;
    }
    await _roomRef?.update(updates);
  }

  /// Remove a player from the room.
  Future<void> removePlayer(String playerId) async {
    _playerInputSubs[playerId]?.cancel();
    _playerInputSubs.remove(playerId);
    await _roomRef?.child('players/$playerId').remove();
    await _roomRef?.child('inputs/$playerId').remove();
    await _roomRef?.child('messages/$playerId').remove();
  }

  /// Destroy the room.
  Future<void> destroyRoom() async {
    for (final sub in _playerInputSubs.values) {
      await sub.cancel();
    }
    _playerInputSubs.clear();
    await _playersSub?.cancel();
    await _roomRef?.remove();
    _roomRef = null;
    _roomCode = null;
  }

  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no ambiguous chars
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(4, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }
}
