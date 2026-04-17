class ScoreManager {
  final Map<String, double> _scores = {};

  double getScore(String playerId) => _scores[playerId] ?? 0;

  /// Add points to a player's score (e.g. +1 per obstacle crossed).
  void incrementScore(String playerId, int amount) {
    _scores[playerId] = (_scores[playerId] ?? 0) + amount;
  }

  void resetAll() {
    _scores.clear();
  }

  void resetPlayer(String playerId) {
    _scores[playerId] = 0;
  }

  Map<String, double> get allScores => Map.unmodifiable(_scores);

  double get maxScore {
    if (_scores.isEmpty) return 0;
    return _scores.values.reduce((a, b) => a > b ? a : b);
  }
}
