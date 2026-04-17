import 'dart:ui';

import 'package:flame/components.dart';

import 'package:pup_dash/constants/game_constants.dart';

/// Scrolling ground component — draws a colored rectangle that tiles and scrolls.
class Ground extends PositionComponent with HasGameReference {
  double _scrollOffset = 0;

  @override
  Future<void> onLoad() async {
    final gameSize = game.size;
    size = Vector2(gameSize.x, gameSize.y * (1 - GameConstants.groundY));
    position = Vector2(0, gameSize.y * GameConstants.groundY);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _scrollOffset += _currentSpeed * dt;
    if (_scrollOffset > 64) _scrollOffset -= 64;
  }

  double get _currentSpeed => 300; // Will be overridden by game speed

  @override
  void render(Canvas canvas) {
    // Ground base
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = const Color(0xFF4CAF50),
    );

    // Road stripe
    final roadY = 4.0;
    canvas.drawRect(
      Rect.fromLTWH(0, roadY, size.x, 8),
      Paint()..color = const Color(0xFF795548),
    );

    // Scrolling dashes
    final dashPaint = Paint()..color = const Color(0xFFFFFFFF);
    for (double x = -_scrollOffset; x < size.x; x += 64) {
      canvas.drawRect(
        Rect.fromLTWH(x, roadY + 3, 32, 2),
        dashPaint,
      );
    }
  }
}
