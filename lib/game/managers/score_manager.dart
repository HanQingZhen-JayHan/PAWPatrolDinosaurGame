import 'package:paw_patrol_runner/constants/game_constants.dart';

class ScoreManager {
  final Map<String, double> _scores = {};

  double getScore(String playerId) => _scores[playerId] ?? 0;

  void updateScore(String playerId, double gameSpeed, double dt) {
    _scores[playerId] =
        (_scores[playerId] ?? 0) + gameSpeed * dt * GameConstants.scoreMultiplier;
  }

  void resetAll() {
    _scores.clear();
  }

  void resetPlayer(String playerId) {
    _scores[playerId] = 0;
  }

  Map<String, double> get allScores => Map.unmodifiable(_scores);

  /// Returns the highest score among all tracked players.
  double get maxScore {
    if (_scores.isEmpty) return 0;
    return _scores.values.reduce((a, b) => a > b ? a : b);
  }
}
