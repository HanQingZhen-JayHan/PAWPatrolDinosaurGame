import 'package:pup_dash/constants/game_constants.dart';

class DifficultySystem {
  double _elapsed = 0;
  double _gameSpeed = GameConstants.easyModeSpeed;

  double get elapsed => _elapsed;
  double get gameSpeed => _gameSpeed;
  bool get isEasyMode => _elapsed < GameConstants.easyModeDuration;

  void update(double dt) {
    _elapsed += dt;

    if (isEasyMode) {
      _gameSpeed = GameConstants.easyModeSpeed;
      return;
    }

    // Normal progression begins after easy mode ends
    final normalElapsed = _elapsed - GameConstants.easyModeDuration;
    final speedIncrements =
        (normalElapsed / GameConstants.speedIncrementInterval).floor();
    _gameSpeed = (GameConstants.initialSpeed +
            speedIncrements * GameConstants.speedIncrement)
        .clamp(GameConstants.initialSpeed, GameConstants.maxSpeed);
  }

  void reset() {
    _elapsed = 0;
    _gameSpeed = GameConstants.easyModeSpeed;
  }
}
