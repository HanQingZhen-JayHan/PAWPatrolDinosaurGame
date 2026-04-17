import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:pup_dash/constants/characters.dart';
import 'package:pup_dash/constants/game_constants.dart';
import 'package:pup_dash/models/game_state.dart';
import 'package:pup_dash/models/message.dart';
import 'package:pup_dash/models/player.dart';
import 'package:pup_dash/network/game_server.dart';
import 'package:pup_dash/network/network_utils.dart';

/// Host-side provider: manages server, game state, and Flame bridge.
class GameProvider extends ChangeNotifier {
  final GameServer _server = GameServer();
  final GameStateModel _state = GameStateModel();
  final _uuid = const Uuid();

  // Maps WebSocket client IDs to player IDs
  final Map<String, String> _clientToPlayer = {};
  final Map<String, String> _playerToClient = {};

  Timer? _countdownTimer;
  Timer? _scoreTimer;

  /// Callback for the Flame game to receive input actions.
  void Function(String playerId, String action)? onPlayerInput;

  /// Callback when game phase changes.
  void Function(GamePhase phase)? onPhaseChanged;

  GameStateModel get state => _state;
  String? get serverIp => _server.ip;
  int? get serverPort => _server.port;
  String get wsUrl =>
      NetworkUtils.buildWsUrl(_lanIp ?? 'localhost', _server.port ?? 8080);
  String get httpUrl => 'http://${_lanIp ?? 'localhost'}:${_server.port ?? 8080}';
  bool get isRunning => _server.isRunning;

  String? _lanIp;
  String? get lanIp => _lanIp;

  Future<void> startServer() async {
    _lanIp = await NetworkUtils.getLocalIpAddress() ?? 'localhost';
    final port = await NetworkUtils.findAvailablePort();

    _server.onMessage = _handleMessage;
    _server.onClientConnected = _handleClientConnected;
    _server.onClientDisconnected = _handleClientDisconnected;

    // Bind to 0.0.0.0 so phones on the same WiFi can connect
    _server.lanIp = _lanIp;
    await _server.start(ip: '0.0.0.0', port: port);
    notifyListeners();
  }

  void _handleClientConnected(String clientId) {
    // Client connected, wait for join message
  }

  void _handleClientDisconnected(String clientId) {
    final playerId = _clientToPlayer.remove(clientId);
    if (playerId != null) {
      _playerToClient.remove(playerId);
      _state.removePlayer(playerId);
      _broadcastLobbyUpdate();
      notifyListeners();

      // Check if game should end due to disconnection
      if (_state.phase == GamePhase.playing) {
        _checkGameEnd();
      }
    }
  }

  void _handleMessage(String clientId, GameMessage message) {
    switch (message.type) {
      case MessageType.join:
        _handleJoin(clientId, message.payload['playerName'] as String? ?? '');
      case MessageType.selectCharacter:
        _handleSelectCharacter(
            clientId, message.payload['character'] as String? ?? '');
      case MessageType.ready:
        _handleReady(clientId);
      case MessageType.input:
        _handleInput(clientId, message.payload['action'] as String? ?? '');
      case MessageType.requestStart:
        _handleRequestStart();
      case MessageType.requestEnd:
        _handleRequestEnd();
      case MessageType.leave:
        _handleClientDisconnected(clientId);
    }
  }

  void _handleJoin(String clientId, String playerName) {
    final playerId = _uuid.v4();
    _clientToPlayer[clientId] = playerId;
    _playerToClient[playerId] = clientId;

    final player = PlayerData(id: playerId, name: playerName);
    _state.addPlayer(player);

    _server.sendTo(clientId, GameMessage.joined(playerId));
    _broadcastLobbyUpdate();
    notifyListeners();
  }

  void _handleSelectCharacter(String clientId, String characterName) {
    final playerId = _clientToPlayer[clientId];
    if (playerId == null) return;

    final character = PupCharacter.fromName(characterName);
    if (character == null) return;

    // Check if character is already taken
    final taken = _state.playerList.any(
        (p) => p.id != playerId && p.character == character);
    if (taken) return;

    _state.players[playerId]?.character = character;
    _server.sendTo(clientId, GameMessage.characterConfirmed(characterName));
    _broadcastLobbyUpdate();
    notifyListeners();
  }

  void _handleReady(String clientId) {
    final playerId = _clientToPlayer[clientId];
    if (playerId == null) return;

    _state.players[playerId]?.isReady = true;
    _broadcastLobbyUpdate();
    notifyListeners();

    // Auto-start when all ready
    if (_state.allReady && _state.phase == GamePhase.lobby) {
      _startCountdown();
    }
  }

  void _handleInput(String clientId, String action) {
    if (_state.phase != GamePhase.playing) return;
    final playerId = _clientToPlayer[clientId];
    if (playerId == null) return;

    final player = _state.players[playerId];
    if (player == null || !player.isAlive) return;

    onPlayerInput?.call(playerId, action);
  }

  void _handleRequestStart() {
    if (_state.phase != GamePhase.lobby) return;
    final hasReadyPlayer = _state.playerList.any((p) => p.isReady);
    if (!hasReadyPlayer) return;
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
    _server.broadcast(GameMessage.gameStarting(_state.countdownValue));
    notifyListeners();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _state.countdownValue--;
      if (_state.countdownValue <= 0) {
        timer.cancel();
        _startGame();
      } else {
        _server.broadcast(GameMessage.gameStarting(_state.countdownValue));
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
    _server.broadcast(GameMessage.gameStarted());
    notifyListeners();

    // Periodic score broadcasts
    _scoreTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final scores = <String, double>{};
      for (final p in _state.playerList) {
        scores[p.id] = p.score;
      }
      _server.broadcast(GameMessage.scoreUpdate(scores));
    });
  }

  /// Called by the Flame game when a player is hit by an obstacle.
  void playerHit(String playerId) {
    final player = _state.players[playerId];
    if (player == null) return;

    player.hit();
    final clientId = _playerToClient[playerId];
    if (clientId != null) {
      if (player.isAlive) {
        _server.sendTo(clientId, GameMessage.hit(player.lives));
      } else {
        _server.sendTo(clientId, GameMessage.eliminated(player.score));
      }
    }
    notifyListeners();
    _checkGameEnd();
  }

  /// Called by the Flame game each frame to update scores.
  void updateScore(String playerId, double score) {
    _state.players[playerId]?.score = score;
  }

  void _checkGameEnd() {
    if (_state.phase != GamePhase.playing) return;
    if (_state.aliveCount <= 1) {
      _endGame();
    }
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

    _server.broadcast(GameMessage.gameOver(rankingData));
    onPhaseChanged?.call(GamePhase.gameOver);
    notifyListeners();
  }

  void returnToLobby() {
    _state.resetForNewGame();
    _broadcastLobbyUpdate();
    onPhaseChanged?.call(GamePhase.lobby);
    notifyListeners();
  }

  void _broadcastLobbyUpdate() {
    final players = _state.playerList
        .map((p) => p.toJson())
        .toList();
    _server.broadcast(
        GameMessage.lobbyUpdate(players, _state.allReady));
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _scoreTimer?.cancel();
    _server.stop();
    super.dispose();
  }
}
