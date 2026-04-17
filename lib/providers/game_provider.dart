import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:pup_dash/constants/characters.dart';
import 'package:pup_dash/constants/game_constants.dart';
import 'package:pup_dash/models/game_state.dart';
import 'package:pup_dash/models/message.dart';
import 'package:pup_dash/models/player.dart';
import 'package:pup_dash/network/firebase_room_host.dart';

/// Host-side provider: manages Firebase room, game state, and Flame bridge.
class GameProvider extends ChangeNotifier {
  final FirebaseRoomHost _room = FirebaseRoomHost();
  final GameStateModel _state = GameStateModel();

  Timer? _countdownTimer;
  Timer? _scoreTimer;

  void Function(String playerId, String action)? onPlayerInput;
  void Function(GamePhase phase)? onPhaseChanged;
  void Function()? onGameRestart;

  GameStateModel get state => _state;
  String? get roomCode => _room.roomCode;
  bool get isRunning => _room.isRunning;

  Future<void> startServer() async {
    _room.onMessage = _handleMessage;
    _room.onPlayerJoined = (_) {};
    _room.onPlayerLeft = _handlePlayerLeft;

    await _room.createRoom();
    notifyListeners();
  }

  void _handlePlayerLeft(String playerId) {
    _state.removePlayer(playerId);
    _broadcastLobbyUpdate();
    notifyListeners();
    if (_state.phase == GamePhase.playing) {
      _checkGameEnd();
    }
  }

  void _handleMessage(String playerId, GameMessage message) {
    switch (message.type) {
      case MessageType.join:
        _handleJoin(playerId, message.payload['playerName'] as String? ?? '');
      case MessageType.selectCharacter:
        _handleSelectCharacter(
            playerId, message.payload['character'] as String? ?? '');
      case MessageType.ready:
        _handleReady(playerId);
      case MessageType.input:
        _handleInput(playerId, message.payload['action'] as String? ?? '');
      case MessageType.requestStart:
        _handleRequestStart();
      case MessageType.requestEnd:
        _handleRequestEnd();
      case MessageType.leave:
        _handlePlayerLeft(playerId);
    }
  }

  void _handleJoin(String playerId, String playerName) {
    final player = PlayerData(id: playerId, name: playerName);
    _state.addPlayer(player);
    _room.sendToPlayer(playerId, GameMessage.joined(playerId));
    _broadcastLobbyUpdate();
    notifyListeners();
  }

  void _handleSelectCharacter(String playerId, String characterName) {
    final character = PupCharacter.fromName(characterName);
    if (character == null) return;
    final taken = _state.playerList
        .any((p) => p.id != playerId && p.character == character);
    if (taken) return;
    _state.players[playerId]?.character = character;
    _room.sendToPlayer(playerId, GameMessage.characterConfirmed(characterName));
    _room.updatePlayer(playerId, {'character': characterName});
    _broadcastLobbyUpdate();
    notifyListeners();
  }

  void _handleReady(String playerId) {
    _state.players[playerId]?.isReady = true;
    _room.updatePlayer(playerId, {'ready': true});
    _broadcastLobbyUpdate();
    notifyListeners();
    if (_state.allReady && _state.phase == GamePhase.lobby) {
      _startCountdown();
    }
  }

  void _handleInput(String playerId, String action) {
    if (_state.phase != GamePhase.playing) return;
    final player = _state.players[playerId];
    if (player == null || !player.isAlive) return;
    onPlayerInput?.call(playerId, action);
  }

  void _handleRequestStart() {
    if (_state.phase != GamePhase.lobby) return;
    if (!_state.playerList.any((p) => p.isReady)) return;
    _startCountdown();
  }

  void _handleRequestEnd() {
    if (_state.phase != GamePhase.playing) return;
    _endGame();
  }

  void _startCountdown() {
    _state.phase = GamePhase.countdown;
    _state.countdownValue = GameConstants.countdownSeconds;
    onPhaseChanged?.call(GamePhase.countdown);
    _room.updateState({'phase': 'countdown', 'countdownValue': _state.countdownValue});
    _room.broadcast(GameMessage.gameStarting(_state.countdownValue));
    notifyListeners();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _state.countdownValue--;
      if (_state.countdownValue <= 0) {
        timer.cancel();
        _startGame();
      } else {
        _room.updateState({'countdownValue': _state.countdownValue});
        _room.broadcast(GameMessage.gameStarting(_state.countdownValue));
        notifyListeners();
      }
    });
  }

  void _startGame() {
    _state.phase = GamePhase.playing;
    _state.gameSpeed = GameConstants.initialSpeed;
    _state.elapsedTime = 0;
    for (final player in _state.playerList) {
      if (player.isReady) {
        player.state = PlayerState.alive;
        player.score = 0;
        player.lives = GameConstants.maxLives;
      }
    }
    onPhaseChanged?.call(GamePhase.playing);
    _room.updateState({'phase': 'playing'});
    _room.broadcast(GameMessage.gameStarted());
    notifyListeners();

    _scoreTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final scores = <String, double>{};
      for (final p in _state.playerList) {
        scores[p.id] = p.score;
      }
      _room.updateScores(scores);
      _room.broadcast(GameMessage.scoreUpdate(scores));
    });
  }

  void playerHit(String playerId) {
    final player = _state.players[playerId];
    if (player == null) return;
    player.hit();
    if (player.isAlive) {
      _room.sendToPlayer(playerId, GameMessage.hit(player.lives));
      _room.updatePlayer(playerId, {'lives': player.lives});
    } else {
      _room.sendToPlayer(playerId, GameMessage.eliminated(player.score));
      _room.updatePlayer(playerId, {'alive': false, 'lives': 0});
    }
    notifyListeners();
    _checkGameEnd();
  }

  void updateScore(String playerId, double score) {
    _state.players[playerId]?.score = score;
  }

  void _checkGameEnd() {
    if (_state.phase != GamePhase.playing) return;
    if (_state.aliveCount <= 1) _endGame();
  }

  void _endGame() {
    _state.phase = GamePhase.gameOver;
    _scoreTimer?.cancel();
    final rankings = _state.rankings;
    final rankingData = <Map<String, dynamic>>[];
    for (var i = 0; i < rankings.length; i++) {
      rankingData.add({
        'rank': i + 1,
        'playerId': rankings[i].id,
        'character': rankings[i].character?.name,
        'playerName': rankings[i].name,
        'score': rankings[i].score,
        'isWinner': i == 0,
      });
    }
    _room.updateState({'phase': 'gameOver'});
    _room.broadcast(GameMessage.gameOver(rankingData));
    onPhaseChanged?.call(GamePhase.gameOver);
    notifyListeners();
  }

  /// Host-initiated kick: remove a player from the room.
  Future<void> kickPlayer(String playerId) async {
    _state.removePlayer(playerId);
    await _room.removePlayer(playerId);
    _broadcastLobbyUpdate();
    notifyListeners();
    if (_state.phase == GamePhase.playing) _checkGameEnd();
  }

  void returnToLobby() {
    _state.resetForNewGame();
    _room.updateState({'phase': 'lobby'});
    _broadcastLobbyUpdate();
    onPhaseChanged?.call(GamePhase.lobby);
    notifyListeners();
  }

  /// Restart the game immediately: reset scores/lives but keep players ready.
  /// Controllers stay connected and regain control after the countdown.
  void restartGame() {
    _countdownTimer?.cancel();
    _scoreTimer?.cancel();

    // Reset game state but keep players ready & characters intact
    for (final player in _state.playerList) {
      player.score = 0;
      player.lives = GameConstants.maxLives;
      player.state = PlayerState.alive;
      player.eliminatedAt = null;
      // isReady stays true — players don't need to re-ready
    }
    _state.gameSpeed = GameConstants.initialSpeed;
    _state.elapsedTime = 0;

    // Broadcast updated player states
    for (final player in _state.playerList) {
      _room.updatePlayer(player.id, {
        'score': 0,
        'lives': GameConstants.maxLives,
        'alive': true,
      });
    }
    _broadcastLobbyUpdate();

    // Let the Flame game reset its visual state
    onGameRestart?.call();

    // Start countdown for the new round
    _startCountdown();
  }

  void _broadcastLobbyUpdate() {
    final players = _state.playerList.map((p) => p.toJson()).toList();
    _room.broadcast(GameMessage.lobbyUpdate(players, _state.allReady));
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _scoreTimer?.cancel();
    _room.destroyRoom();
    super.dispose();
  }
}
