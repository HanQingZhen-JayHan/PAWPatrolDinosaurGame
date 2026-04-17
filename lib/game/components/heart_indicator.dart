import 'dart:ui';

import 'package:flame/components.dart';

import 'package:pup_dash/constants/game_constants.dart';
import 'package:pup_dash/constants/theme.dart';

class HeartIndicator extends PositionComponent {
  int lives;
  final int maxLives;

  HeartIndicator({
    required Vector2 position,
    this.lives = GameConstants.maxLives,
    this.maxLives = GameConstants.maxLives,
  }) : super(position: position, size: Vector2(maxLives * 24.0, 20));

  @override
  void render(Canvas canvas) {
    for (var i = 0; i < maxLives; i++) {
      final x = i * 24.0;
      final paint = Paint()
        ..color = i < lives
            ? PupTheme.heartRed
            : const Color(0x44FFFFFF);

      // Simple heart shape using path
      final path = Path();
      final cx = x + 10;
      const cy = 10.0;
      path.moveTo(cx, cy + 4);
      path.cubicTo(cx - 10, cy - 6, cx - 10, cy + 8, cx, cy + 14);
      path.cubicTo(cx + 10, cy + 8, cx + 10, cy - 6, cx, cy + 4);
      canvas.drawPath(path, paint);
    }
  }
}
