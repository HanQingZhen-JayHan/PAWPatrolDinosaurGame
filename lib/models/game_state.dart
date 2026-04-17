import 'package:pup_dash/models/player.dart';

enum GamePhase { lobby, countdown, playing, gameOver }

class GameStateModel {
  GamePhase phase;
  final Map<String, PlayerData> players;
  double gameSpeed;
  double elapsedTime;
  int countdownValue;

  GameStateModel({
    this.phase = GamePhase.lobby,
    Map<String, PlayerData>? players,
    this.gameSpeed = 300,
    this.elapsedTime = 0,
    this.countdownValue = 3,
  }) : players = players ?? {};

  List<PlayerData> get playerList => players.values.toList();
  List<PlayerData> get alivePlayers =>
      playerList.where((p) => p.isAlive).toList();
  bool get allReady =>
      players.isNotEmpty && playerList.every((p) => p.isReady);
  int get aliveCount => alivePlayers.length;

  List<PlayerData> get rankings {
    final sorted = List<PlayerData>.from(playerList);
    sorted.sort((a, b) {
      // Alive players rank higher
      if (a.isAlive && !b.isAlive) return -1;
      if (!a.isAlive && b.isAlive) return 1;
      // Among eliminated: later elimination = higher rank
      if (!a.isAlive && !b.isAlive) {
        if (a.eliminatedAt != null && b.eliminatedAt != null) {
          return b.eliminatedAt!.compareTo(a.eliminatedAt!);
        }
      }
      // Then by score
      return b.score.compareTo(a.score);
    });
    return sorted;
  }

  void addPlayer(PlayerData player) {
    players[player.id] = player;
  }

  void removePlayer(String playerId) {
    players.remove(playerId);
  }

  void resetForNewGame() {
    phase = GamePhase.lobby;
    gameSpeed = 300;
    elapsedTime = 0;
    countdownValue = 3;
    for (final player in playerList) {
      player.reset();
    }
  }

  Map<String, dynamic> toJson() => {
        'phase': phase.name,
        'players': {
          for (final e in players.entries) e.key: e.value.toJson(),
        },
        'gameSpeed': gameSpeed,
        'elapsedTime': elapsedTime,
        'countdownValue': countdownValue,
      };
}
