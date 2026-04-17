import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show TextPainter, TextSpan, TextStyle, TextDirection, FontWeight;

import 'package:pup_dash/constants/theme.dart';
import 'package:pup_dash/models/player.dart';

/// Flame-rendered game over podium overlay.
class GameOverOverlayComponent extends PositionComponent
    with HasGameReference {
  final List<PlayerData> rankings;

  GameOverOverlayComponent({required this.rankings});

  @override
  Future<void> onLoad() async {
    size = game.size;
    position = Vector2.zero();
  }

  @override
  void render(Canvas canvas) {
    // Dimmed background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = const Color(0xDD000000),
    );

    // Title
    _drawText(canvas, 'GAME OVER', size.x / 2, 40,
        fontSize: 48, color: PupTheme.goldStar);

    // Podium
    if (rankings.isEmpty) return;

    final podiumY = size.y * 0.35;
    final podiumHeights = [120.0, 80.0, 60.0];
    final podiumColors = [PupTheme.goldStar, const Color(0xFFC0C0C0), const Color(0xFFCD7F32)];
    final podiumOrder = [1, 0, 2]; // 2nd, 1st, 3rd positions left to right

    for (var i = 0; i < podiumOrder.length && podiumOrder[i] < rankings.length; i++) {
      final rank = podiumOrder[i];
      final player = rankings[rank];
      final x = size.x / 2 + (i - 1) * 120.0;
      final h = podiumHeights[rank];

      // Podium block
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 40, podiumY + 120 - h, 80, h),
          const Radius.circular(8),
        ),
        Paint()..color = podiumColors[rank],
      );

      // Rank number
      _drawText(canvas, '#${rank + 1}', x, podiumY + 120 - h + 10,
          fontSize: 24, color: const Color(0xFFFFFFFF));

      // Character name
      _drawText(canvas, player.character?.displayName ?? player.name,
          x, podiumY - 20,
          fontSize: 14, color: const Color(0xFFFFFFFF));

      // Character emoji
      _drawText(canvas, player.character?.emoji ?? '🐕',
          x, podiumY - 50,
          fontSize: 32, color: const Color(0xFFFFFFFF));
    }

    // Winner announcement
    if (rankings.isNotEmpty) {
      final winner = rankings.first;
      _drawText(
        canvas,
        'Winner: ${winner.character?.displayName ?? winner.name}!',
        size.x / 2,
        size.y * 0.75,
        fontSize: 28,
        color: const Color(0xFF00FF88),
      );
    }
  }

  void _drawText(Canvas canvas, String text, double x, double y, {
    double fontSize = 16,
    Color color = const Color(0xFFFFFFFF),
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    painter.layout();
    painter.paint(canvas, Offset(x - painter.width / 2, y));
  }
}
