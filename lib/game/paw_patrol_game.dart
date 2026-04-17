import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;

import 'package:paw_patrol_runner/constants/game_constants.dart';
import 'package:paw_patrol_runner/game/components/ground.dart';
import 'package:paw_patrol_runner/game/components/heart_indicator.dart';
import 'package:paw_patrol_runner/game/components/obstacle_component.dart';
import 'package:paw_patrol_runner/game/components/parallax_background.dart';
import 'package:paw_patrol_runner/game/components/player_component.dart';
import 'package:paw_patrol_runner/game/components/score_indicator.dart';
import 'package:paw_patrol_runner/game/managers/obstacle_manager.dart';
import 'package:paw_patrol_runner/game/managers/score_manager.dart';
import 'package:paw_patrol_runner/game/systems/difficulty_system.dart';
import 'package:paw_patrol_runner/models/message.dart';
import 'package:paw_patrol_runner/providers/game_provider.dart';

class PawPatrolGame extends FlameGame
    with HasCollisionDetection, KeyboardEvents {
  final GameProvider gameProvider;

  late ParallaxBackground _background;
  late Ground _ground;
  late ObstacleManager _obstacleManager;
  final ScoreManager _scoreManager = ScoreManager();
  final DifficultySystem _difficulty = DifficultySystem();

  final Map<String, PlayerComponent> _playerComponents = {};
  final Map<String, HeartIndicator> _heartIndicators = {};
  final Map<String, ScoreIndicator> _scoreIndicators = {};

  bool _gameRunning = false;

  PawPatrolGame({required this.gameProvider});

  @override
  Future<void> onLoad() async {
    // Background
    _background = ParallaxBackground();
    add(_background);

    // Ground
    _ground = Ground();
    add(_ground);

    // Obstacle manager
    _obstacleManager = ObstacleManager();
    add(_obstacleManager);

    // Wire up provider callbacks
    gameProvider.onPlayerInput = _handlePlayerInput;

    // Create player components for all players in the session
    _spawnPlayers();
    _gameRunning = true;
  }

  void _spawnPlayers() {
    final players = gameProvider.state.playerList
        .where((p) => p.isAlive && p.character != null)
        .toList();

    for (var i = 0; i < players.length; i++) {
      final player = players[i];
      final laneOffset = _getLaneY(i, players.length);

      final component = PlayerComponent(
        playerId: player.id,
        character: player.character!,
        laneIndex: i,
      );
      // Adjust Y position based on lane
      component.position = Vector2(80 + i * 20, laneOffset);
      _playerComponents[player.id] = component;
      add(component);

      // HUD: hearts
      final hearts = HeartIndicator(
        position: Vector2(16, 16 + i * 28.0),
        lives: player.lives,
      );
      _heartIndicators[player.id] = hearts;
      add(hearts);

      // HUD: score
      final scoreInd = ScoreIndicator(
        position: Vector2(size.x - 160, 16 + i * 28.0),
      );
      _scoreIndicators[player.id] = scoreInd;
      add(scoreInd);

      _scoreManager.resetPlayer(player.id);
    }
  }

  double _getLaneY(int index, int total) {
    final groundY = size.y * GameConstants.groundY;
    if (total == 1) return groundY - GameConstants.playerHeight;
    // Stack lanes with small vertical offset for visibility
    final spacing = 8.0;
    final baseY = groundY - GameConstants.playerHeight;
    return baseY - (total - 1 - index) * spacing;
  }

  void _handlePlayerInput(String playerId, String action) {
    _playerComponents[playerId]?.handleInput(action);
  }

  @override
  void update(double dt) {
    if (!_gameRunning) return;
    super.update(dt);

    // Difficulty progression
    _difficulty.update(dt);
    final speed = _difficulty.gameSpeed;
    _background.updateSpeed(speed);
    _obstacleManager.updateDifficulty(speed, _scoreManager.maxScore);
    _obstacleManager.updateSpawnInterval(_difficulty.elapsed);

    // Update scores for alive players
    for (final entry in _playerComponents.entries) {
      if (!entry.value.isEliminated) {
        _scoreManager.updateScore(entry.key, speed, dt);
        final score = _scoreManager.getScore(entry.key);
        _scoreIndicators[entry.key]?.score = score;
        gameProvider.updateScore(entry.key, score);
      }
    }

    // Collision detection: check obstacles against players
    _checkCollisions();

    // Update game state speed
    gameProvider.state.gameSpeed = speed;
    gameProvider.state.elapsedTime = _difficulty.elapsed;
  }

  void _checkCollisions() {
    final obstacles = children.whereType<ObstacleComponent>().toList();

    for (final player in _playerComponents.values) {
      if (player.isEliminated || player.isInvincible) continue;

      for (final obstacle in obstacles) {
        if (_isColliding(player, obstacle)) {
          player.hit();
          gameProvider.playerHit(player.playerId);

          final playerData = gameProvider.state.players[player.playerId];
          if (playerData != null) {
            _heartIndicators[player.playerId]?.lives = playerData.lives;
            if (!playerData.isAlive) {
              player.eliminate();
            }
          }
          break; // Only one hit per frame per player
        }
      }
    }
  }

  bool _isColliding(PlayerComponent player, ObstacleComponent obstacle) {
    final pRect = player.toRect();
    final oRect = obstacle.toRect();
    return pRect.overlaps(oRect);
  }

  // Keyboard support for testing (space=jump, down=duck)
  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    // Apply keyboard input to the first player (for single-player testing)
    final firstPlayer = _playerComponents.values.firstOrNull;
    if (firstPlayer == null) return KeyEventResult.ignored;

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.arrowUp) {
        firstPlayer.handleInput(InputAction.jump);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        firstPlayer.handleInput(InputAction.duckStart);
        return KeyEventResult.handled;
      }
    }
    if (event is KeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        firstPlayer.handleInput(InputAction.duckEnd);
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }
}
