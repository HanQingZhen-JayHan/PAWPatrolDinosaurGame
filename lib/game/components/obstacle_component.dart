import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'package:paw_patrol_runner/models/obstacle.dart';

class ObstacleComponent extends PositionComponent
    with CollisionCallbacks, HasGameReference {
  final ObstacleType type;
  double speed;

  ObstacleComponent({
    required this.type,
    required this.speed,
    required Vector2 position,
  }) : super(position: position, size: Vector2(type.width, type.height));

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x -= speed * dt;

    // Remove when off-screen
    if (position.x < -size.x) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint();

    switch (type) {
      case ObstacleType.trafficCone:
        paint.color = const Color(0xFFFF6600);
        // Cone shape: triangle-ish
        final path = Path()
          ..moveTo(size.x / 2, 0)
          ..lineTo(size.x, size.y)
          ..lineTo(0, size.y)
          ..close();
        canvas.drawPath(path, paint);
        // White stripe
        canvas.drawRect(
          Rect.fromLTWH(size.x * 0.25, size.y * 0.4, size.x * 0.5, 4),
          Paint()..color = const Color(0xFFFFFFFF),
        );

      case ObstacleType.barrel:
        paint.color = const Color(0xFF8B4513);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.x, size.y),
            const Radius.circular(6),
          ),
          paint,
        );
        // Metal bands
        canvas.drawRect(
          Rect.fromLTWH(0, size.y * 0.3, size.x, 3),
          Paint()..color = const Color(0xFF666666),
        );
        canvas.drawRect(
          Rect.fromLTWH(0, size.y * 0.7, size.x, 3),
          Paint()..color = const Color(0xFF666666),
        );

      case ObstacleType.rock:
        paint.color = const Color(0xFF808080);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.x, size.y),
            const Radius.circular(10),
          ),
          paint,
        );
        // Highlight
        canvas.drawCircle(
          Offset(size.x * 0.35, size.y * 0.35),
          4,
          Paint()..color = const Color(0xFFAAAAAA),
        );

      case ObstacleType.puddle:
        paint.color = const Color(0xFF4488FF);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.x, size.y),
            const Radius.circular(8),
          ),
          paint,
        );

      case ObstacleType.bird:
        paint.color = const Color(0xFF333333);
        // Body
        canvas.drawOval(
          Rect.fromLTWH(size.x * 0.2, size.y * 0.3, size.x * 0.6, size.y * 0.4),
          paint,
        );
        // Wings (V shape)
        final wingPaint = Paint()
          ..color = const Color(0xFF444444)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        final wingPath = Path()
          ..moveTo(0, size.y * 0.2)
          ..quadraticBezierTo(size.x * 0.25, 0, size.x * 0.5, size.y * 0.4)
          ..quadraticBezierTo(size.x * 0.75, 0, size.x, size.y * 0.2);
        canvas.drawPath(wingPath, wingPaint);
        // Eye
        canvas.drawCircle(
          Offset(size.x * 0.65, size.y * 0.4),
          2,
          Paint()..color = const Color(0xFFFFFFFF),
        );
    }
  }
}
