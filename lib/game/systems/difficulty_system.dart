import 'package:pup_dash/constants/dev_config.dart';
import 'package:pup_dash/constants/game_constants.dart';

class DifficultySystem {
  double _elapsed = 0;
  double _gameSpeed = GameConstants.easyModeSpeed;

  double get elapsed => _elapsed;
  double get gameSpeed => _gameSpeed;
  // Dev mode stays in easy mode forever so obstacle variety/spawning stays
  // simple while testing logic.
  bool get isEasyMode =>
      DevConfig.enabled || _elapsed < GameConstants.easyModeDuration;

  void update(double dt) {
    _elapsed += dt;

    if (DevConfig.enabled) {
      _gameSpeed = DevConfig.easyGameSpeed;
      return;
    }

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
    _gameSpeed = DevConfig.enabled
        ? DevConfig.easyGameSpeed
        : GameConstants.easyModeSpeed;
  }
}
