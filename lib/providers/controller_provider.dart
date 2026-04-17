import 'package:flutter/foundation.dart';

import 'package:pup_dash/constants/characters.dart';
import 'package:pup_dash/constants/game_constants.dart';
import 'package:pup_dash/models/message.dart';
import 'package:pup_dash/network/firebase_room_client.dart';
import 'package:pup_dash/providers/network_provider.dart';

/// Controller-side provider: manages Firebase client and local state.
class ControllerProvider extends ChangeNotifier {
  final FirebaseRoomClient _client = FirebaseRoomClient();
  final NetworkProvider networkProvider;

  PupCharacter? _selectedCharacter;
  bool _isReady = false;
  int? _personalRank;
  double _personalScore = 0;
  String? _winnerName;
  int _livesRemaining = GameConstants.maxLives;
  bool _gameActive = false;
  List<Map<String, dynamic>> _rankings = [];
  List<Map<String, dynamic>> _lobbyPlayers = [];
  bool _allReady = false;
  int _countdown = 0;

  String? get playerId => _client.playerId;
  PupCharacter? get selectedCharacter => _selectedCharacter;
  bool get isReady => _isReady;
  int? get personalRank => _personalRank;
  double get personalScore => _personalScore;
  String? get winnerName => _winnerName;
  int get livesRemaining => _livesRemaining;
  bool get gameActive => _gameActive;
  List<Map<String, dynamic>> get rankings => _rankings;
  List<Map<String, dynamic>> get lobbyPlayers => _lobbyPlayers;
  bool get allReady => _allReady;
  int get countdown => _countdown;
  bool get isConnected => _client.isConnected;

  ControllerProvider({required this.networkProvider});

  Future<void> connect(String roomCode) async {
    networkProvider.setStatus(ConnectionStatus.connecting);
    try {
      _client.onMessage = _handleMessage;
      _client.onConnected = () {
        networkProvider.setStatus(ConnectionStatus.connected);
        notifyListeners();
      };
      _client.onDisconnected = () {
        networkProvider.setStatus(ConnectionStatus.disconnected);
        _gameActive = false;
        notifyListeners();
      };
      await _client.connect(roomCode);
    } catch (e) {
      networkProvider.setStatus(ConnectionStatus.error,
          error: 'Failed to connect: $e');
      rethrow;
    }
  }

  void join(String playerName) {
    _client.join(playerName);
  }

  void selectCharacter(PupCharacter character) {
    _client.send(GameMessage.selectCharacter(character.name));
  }

  void markReady() {
    _isReady = true;
    _client.send(GameMessage.ready());
    notifyListeners();
  }

  void sendInput(String action) {
    _client.send(GameMessage.input(action));
  }

  void requestStart() {
    _client.send(GameMessage.requestStart());
  }

  void requestEnd() {
    _client.send(GameMessage.requestEnd());
  }

  void _handleMessage(GameMessage message) {
    switch (message.type) {
      case MessageType.joined:
        notifyListeners();

      case MessageType.characterConfirmed:
        final name = message.payload['character'] as String?;
        if (name != null) {
          _selectedCharacter = PupCharacter.fromName(name);
        }
        notifyListeners();

      case MessageType.lobbyUpdate:
        _lobbyPlayers =
            (message.payload['players'] as List?)?.cast<Map<String, dynamic>>() ??
                [];
        _allReady = message.payload['allReady'] as bool? ?? false;
        notifyListeners();

      case MessageType.gameStarting:
        _countdown = message.payload['countdown'] as int? ?? 0;
        // Clear stale results when a new countdown begins (replay)
        if (_rankings.isNotEmpty) {
          _rankings = [];
          _personalRank = null;
        }
        notifyListeners();

      case MessageType.gameStarted:
        _gameActive = true;
        _livesRemaining = GameConstants.maxLives;
        // Clear previous game results so controllers don't show stale data
        _rankings = [];
        _personalRank = null;
        _personalScore = 0;
        _winnerName = null;
        notifyListeners();

      case MessageType.hit:
        _livesRemaining = message.payload['livesRemaining'] as int? ?? 0;
        notifyListeners();

      case MessageType.eliminated:
        _personalScore =
            (message.payload['finalScore'] as num?)?.toDouble() ?? 0;
        _gameActive = false;
        notifyListeners();

      case MessageType.scoreUpdate:
        final scores = message.payload['scores'] as Map<String, dynamic>?;
        if (scores != null && playerId != null) {
          _personalScore =
              (scores[playerId] as num?)?.toDouble() ?? _personalScore;
        }
        notifyListeners();

      case MessageType.gameOver:
        _gameActive = false;
        _rankings = (message.payload['rankings'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [];
        for (final r in _rankings) {
          if (r['playerId'] == playerId) {
            _personalRank = r['rank'] as int?;
            _personalScore = (r['score'] as num?)?.toDouble() ?? 0;
          }
          if (r['isWinner'] == true) {
            _winnerName = r['playerName'] as String? ??
                r['character'] as String? ??
                'Unknown';
          }
        }
        notifyListeners();
    }
  }

  void resetForNewGame() {
    _isReady = false;
    _personalRank = null;
    _personalScore = 0;
    _winnerName = null;
    _livesRemaining = GameConstants.maxLives;
    _gameActive = false;
    _rankings = [];
    _countdown = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _client.disconnect();
    super.dispose();
  }
}
