import 'dart:ui';

import 'package:flame/components.dart';

import 'package:pup_dash/game/components/obstacle_component.dart';
import 'package:pup_dash/game/components/player_component.dart';

/// Renders a green "jump now" zone in front of each alive player.
/// The zone brightens (green → yellow → red) as an obstacle approaches.
class JumpZoneIndicator extends PositionComponent with HasGameReference {
  /// Distance ahead of the player where the jump zone starts.
  static const double _zoneStartOffset = 40.0;

  /// Width of the jump zone (ideal jump trigger range).
  static const double _zoneWidth = 160.0;

  /// Distance at which warning starts showing.
  static const double _maxWarningDistance = 400.0;

  @override
  int get priority => -1; // render below players & obstacles

  @override
  Future<void> onLoad() async {
    size = game.size;
    position = Vector2.zero();
  }

  @override
  void render(Canvas canvas) {
    final players = parent?.children
            .whereType<PlayerComponent>()
            .where((p) => !p.isEliminated)
            .toList() ??
        [];
    if (players.isEmpty) return;

    final obstacles =
        parent?.children.whereType<ObstacleComponent>().toList() ?? [];

    for (final player in players) {
      final playerRight = player.position.x + player.size.x;
      final zoneLeft = playerRight + _zoneStartOffset;
      final zoneRight = zoneLeft + _zoneWidth;

      // Danger level: 0 = no obstacle near, 1 = obstacle inside jump zone
      double danger = 0;
      for (final obstacle in obstacles) {
        if (obstacle.scoredBy.contains(player.playerId)) continue;
        final obstacleLeft = obstacle.position.x;
        final distance = obstacleLeft - playerRight;
        if (distance < 0) continue; // already past
        if (distance > _maxWarningDistance) continue;
        // In zone = highest danger
        if (obstacleLeft <= zoneRight && obstacleLeft >= zoneLeft) {
          danger = 1.0;
          break;
        }
        // Approaching zone
        final proximity =
            1 - ((obstacleLeft - zoneRight) / _maxWarningDistance)
                .clamp(0.0, 1.0);
        if (proximity > danger) danger = proximity;
      }

      // Color transitions: green → yellow → red
      final r = (0x00 + (0xFF * danger)).clamp(0, 255).toInt();
      final g =
          (0xDD - (0x88 * danger.clamp(0.5, 1.0) - 0x44)).clamp(0, 255).toInt();
      final zoneColor = Color.fromARGB(
        (90 + 90 * danger).toInt(),
        r,
        g,
        0,
      );

      // Ground line Y — draw zone on the ground
      final groundY = player.position.y + player.size.y;
      final zoneHeight = 18.0;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(zoneLeft, groundY - zoneHeight, _zoneWidth, zoneHeight),
          const Radius.circular(4),
        ),
        Paint()..color = zoneColor,
      );

      // Pulsing upward arrow at center when danger is high
      if (danger > 0.5) {
        final arrowCenterX = zoneLeft + _zoneWidth / 2;
        final arrowY = groundY - zoneHeight - 20;
        final arrowSize = 12.0 + 8 * (danger - 0.5) * 2;
        final arrowPaint = Paint()
          ..color = Color.fromARGB(
            (200 * danger).toInt(),
            0xFF,
            (0xDD * (1 - (danger - 0.5) * 2).clamp(0.0, 1.0)).toInt(),
            0,
          );
        final arrowPath = Path()
          ..moveTo(arrowCenterX, arrowY - arrowSize)
          ..lineTo(arrowCenterX - arrowSize, arrowY)
          ..lineTo(arrowCenterX - arrowSize / 2, arrowY)
          ..lineTo(arrowCenterX - arrowSize / 2, arrowY + arrowSize / 2)
          ..lineTo(arrowCenterX + arrowSize / 2, arrowY + arrowSize / 2)
          ..lineTo(arrowCenterX + arrowSize / 2, arrowY)
          ..lineTo(arrowCenterX + arrowSize, arrowY)
          ..close();
        canvas.drawPath(arrowPath, arrowPaint);
      }
    }
  }
}
