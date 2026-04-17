import 'package:paw_patrol_runner/constants/game_constants.dart';

class DifficultySystem {
  double _elapsed = 0;
  double _gameSpeed = GameConstants.initialSpeed;

  double get elapsed => _elapsed;
  double get gameSpeed => _gameSpeed;

  void update(double dt) {
    _elapsed += dt;

    // Increase speed every N seconds
    final speedIncrements =
        (_elapsed / GameConstants.speedIncrementInterval).floor();
    _gameSpeed = (GameConstants.initialSpeed +
            speedIncrements * GameConstants.speedIncrement)
        .clamp(GameConstants.initialSpeed, GameConstants.maxSpeed);
  }

  void reset() {
    _elapsed = 0;
    _gameSpeed = GameConstants.initialSpeed;
  }
}
