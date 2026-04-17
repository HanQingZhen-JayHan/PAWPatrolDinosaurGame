import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import 'package:pup_dash/constants/theme.dart';

/// Particle-based celebration effect for the winner.
class WinnerCelebration extends PositionComponent with HasGameReference {
  final List<_Particle> _particles = [];
  final Random _random = Random();
  double _elapsed = 0;

  @override
  Future<void> onLoad() async {
    size = game.size;
    // Generate confetti particles
    for (var i = 0; i < 60; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble() * size.x,
        y: -_random.nextDouble() * size.y * 0.5,
        vx: (_random.nextDouble() - 0.5) * 100,
        vy: _random.nextDouble() * 200 + 50,
        color: [
          PupTheme.goldStar,
          PupTheme.primaryBlue,
          PupTheme.primaryRed,
          const Color(0xFF00FF88),
          const Color(0xFFFF69B4),
        ][_random.nextInt(5)],
        size: _random.nextDouble() * 8 + 4,
        rotation: _random.nextDouble() * 3.14,
        rotationSpeed: (_random.nextDouble() - 0.5) * 5,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    for (final p in _particles) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.rotation += p.rotationSpeed * dt;
      // Wrap around
      if (p.y > size.y) {
        p.y = -10;
        p.x = _random.nextDouble() * size.x;
      }
    }
    // Auto-remove after 5 seconds
    if (_elapsed > 5) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    for (final p in _particles) {
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
        Paint()..color = p.color,
      );
      canvas.restore();
    }
  }
}

class _Particle {
  double x, y, vx, vy;
  Color color;
  double size;
  double rotation;
  double rotationSpeed;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
  });
}
