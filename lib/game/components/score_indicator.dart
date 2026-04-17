import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show TextPainter, TextSpan, TextStyle, TextDirection;

class ScoreIndicator extends PositionComponent {
  double score;

  ScoreIndicator({
    required Vector2 position,
    this.score = 0,
  }) : super(position: position, size: Vector2(120, 24));

  @override
  void render(Canvas canvas) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Score: ${score.toInt()}',
        style: TextStyle(
          color: const Color(0xFFFFFFFF),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset.zero);
  }
}
