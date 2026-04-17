import 'dart:ui';

import 'package:flame/components.dart';

import 'package:pup_dash/constants/game_constants.dart';

/// Simple parallax background with colored layers (no sprite assets needed).
class ParallaxBackground extends PositionComponent with HasGameReference {
  final List<_ParallaxLayer> _layers = [];

  @override
  Future<void> onLoad() async {
    final gameSize = game.size;
    final groundTop = gameSize.y * GameConstants.groundY;

    // Sky gradient is just a filled rect
    _layers.addAll([
      _ParallaxLayer(
        color: const Color(0xFF87CEEB), // sky
        y: 0,
        height: groundTop * 0.4,
        speedFactor: 0.1,
      ),
      _ParallaxLayer(
        color: const Color(0xFF6B8E6B), // distant mountains
        y: groundTop * 0.3,
        height: groundTop * 0.25,
        speedFactor: 0.2,
      ),
      _ParallaxLayer(
        color: const Color(0xFF8DB8A7), // buildings
        y: groundTop * 0.5,
        height: groundTop * 0.3,
        speedFactor: 0.4,
      ),
      _ParallaxLayer(
        color: const Color(0xFF5D8A5D), // near ground
        y: groundTop * 0.75,
        height: groundTop * 0.25,
        speedFactor: 0.7,
      ),
    ]);
  }

  void updateSpeed(double speed) {
    for (final layer in _layers) {
      layer.speed = speed * layer.speedFactor;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (final layer in _layers) {
      layer.offset += layer.speed * dt;
      if (layer.offset > 200) layer.offset -= 200;
    }
  }

  @override
  void render(Canvas canvas) {
    final gameSize = game.size;

    // Sky fill
    canvas.drawRect(
      Rect.fromLTWH(0, 0, gameSize.x, gameSize.y * GameConstants.groundY),
      Paint()..color = const Color(0xFF87CEEB),
    );

    for (final layer in _layers) {
      final paint = Paint()..color = layer.color;
      // Draw simple rolling hills/rectangles
      for (double x = -layer.offset; x < gameSize.x + 200; x += 200) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, layer.y, 200, layer.height),
            const Radius.circular(20),
          ),
          paint,
        );
      }
    }
  }
}

class _ParallaxLayer {
  final Color color;
  final double y;
  final double height;
  final double speedFactor;
  double speed;
  double offset;

  _ParallaxLayer({
    required this.color,
    required this.y,
    required this.height,
    required this.speedFactor,
  }) : speed = 0,
       offset = 0;
}
