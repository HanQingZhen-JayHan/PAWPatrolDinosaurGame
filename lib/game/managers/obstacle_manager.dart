import 'dart:math';

import 'package:flame/components.dart';

import 'package:pup_dash/constants/game_constants.dart';
import 'package:pup_dash/game/components/obstacle_component.dart';
import 'package:pup_dash/models/obstacle.dart';

class ObstacleManager extends Component with HasGameReference {
  final Random _random = Random();
  double _timeSinceLastSpawn = 0;
  double _spawnInterval = GameConstants.initialSpawnInterval;
  double _gameSpeed = GameConstants.initialSpeed;
  double _totalScore = 0;

  void updateDifficulty(double speed, double score) {
    _gameSpeed = speed;
    _totalScore = score;
  }

  void updateSpawnInterval(double elapsed) {
    final decrements = (elapsed / GameConstants.spawnIntervalDecrementEvery).floor();
    _spawnInterval = (GameConstants.initialSpawnInterval -
            decrements * GameConstants.spawnIntervalDecrement)
        .clamp(GameConstants.minSpawnInterval, GameConstants.initialSpawnInterval);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timeSinceLastSpawn += dt;

    if (_timeSinceLastSpawn >= _spawnInterval) {
      _timeSinceLastSpawn = 0;
      _spawnObstacle();
    }
  }

  void _spawnObstacle() {
    final availableTypes = <ObstacleType>[...ObstacleType.groundTypes];

    // Add air obstacles after score threshold
    if (_totalScore >= GameConstants.airObstacleThreshold) {
      availableTypes.addAll(ObstacleType.airTypes);
    }

    final type = availableTypes[_random.nextInt(availableTypes.length)];
    final gameSize = game.size;
    final groundY = gameSize.y * GameConstants.groundY;

    double obstacleY;
    if (type.isGround) {
      obstacleY = groundY - type.height;
    } else {
      // Air obstacle: positioned above player jump height
      obstacleY = groundY - GameConstants.playerHeight - type.height - 20;
    }

    final obstacle = ObstacleComponent(
      type: type,
      speed: _gameSpeed,
      position: Vector2(gameSize.x + 50, obstacleY),
    );

    parent?.add(obstacle);

    // Combo obstacles after score threshold
    if (_totalScore >= GameConstants.comboObstacleThreshold &&
        _random.nextDouble() < 0.3) {
      final comboType = type.isGround
          ? ObstacleType.airTypes[_random.nextInt(ObstacleType.airTypes.length)]
          : ObstacleType.groundTypes[
              _random.nextInt(ObstacleType.groundTypes.length)];

      double comboY;
      if (comboType.isGround) {
        comboY = groundY - comboType.height;
      } else {
        comboY = groundY - GameConstants.playerHeight - comboType.height - 20;
      }

      parent?.add(ObstacleComponent(
        type: comboType,
        speed: _gameSpeed,
        position: Vector2(gameSize.x + 50, comboY),
      ));
    }
  }

  void reset() {
    _timeSinceLastSpawn = 0;
    _spawnInterval = GameConstants.initialSpawnInterval;
    _gameSpeed = GameConstants.initialSpeed;
    _totalScore = 0;
  }
}
