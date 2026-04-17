import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show TextPainter, TextSpan, TextStyle, TextDirection;

import 'package:pup_dash/constants/characters.dart';
import 'package:pup_dash/constants/game_constants.dart';
import 'package:pup_dash/models/message.dart';

enum PlayerAnimState { running, jumping, ducking }

class PlayerComponent extends PositionComponent
    with CollisionCallbacks, HasGameReference {
  final String playerId;
  final PupCharacter character;
  final int laneIndex;

  PlayerAnimState _animState = PlayerAnimState.running;
  double _velocityY = 0;
  double _groundY = 0;
  bool _isOnGround = true;
  bool _isDucking = false;
  bool _isInvincible = false;
  double _invincibilityTimer = 0;
  double _blinkTimer = 0;
  bool _visible = true;
  bool _eliminated = false;
  double _eliminatedAlpha = 1.0;

  PlayerComponent({
    required this.playerId,
    required this.character,
    required this.laneIndex,
  });

  Sprite? _sprite;

  bool get isEliminated => _eliminated;
  bool get isInvincible => _isInvincible;

  @override
  Future<void> onLoad() async {
    size = Vector2(GameConstants.playerWidth, GameConstants.playerHeight);
    _groundY = game.size.y * GameConstants.groundY - size.y;
    position = Vector2(100, _groundY);

    // Try loading the character's icon image; falls back to vector art
    if (character.hasIconImage) {
      try {
        final path = character.iconAsset.replaceFirst('assets/images/', '');
        _sprite = await Sprite.load(path);
      } catch (_) {
        _sprite = null;
      }
    }

    add(RectangleHitbox());
  }

  void handleInput(String action) {
    if (_eliminated) return;

    switch (action) {
      case InputAction.jump:
        if (_isOnGround && !_isDucking) {
          _velocityY = GameConstants.jumpVelocity;
          _isOnGround = false;
          _animState = PlayerAnimState.jumping;
        }
      case InputAction.duckStart:
        if (_isOnGround) {
          _isDucking = true;
          _animState = PlayerAnimState.ducking;
          size.y = GameConstants.duckHeight;
          position.y = _groundY + (GameConstants.playerHeight - GameConstants.duckHeight);
        }
      case InputAction.duckEnd:
        if (_isDucking) {
          _isDucking = false;
          _animState = PlayerAnimState.running;
          size.y = GameConstants.playerHeight;
          position.y = _groundY;
        }
    }
  }

  void hit() {
    if (_isInvincible || _eliminated) return;
    _isInvincible = true;
    _invincibilityTimer = GameConstants.invincibilityDuration;
  }

  void eliminate() {
    _eliminated = true;
    _animState = PlayerAnimState.running;
  }

  /// Reset player state for a new round.
  void reset() {
    _eliminated = false;
    _eliminatedAlpha = 1.0;
    _isInvincible = false;
    _invincibilityTimer = 0;
    _blinkTimer = 0;
    _visible = true;
    _velocityY = 0;
    _isOnGround = true;
    _isDucking = false;
    _animState = PlayerAnimState.running;
    size.y = GameConstants.playerHeight;
    position.y = _groundY;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_eliminated) {
      _eliminatedAlpha = (_eliminatedAlpha - dt * 0.5).clamp(0.0, 1.0);
      return;
    }

    // Jump physics
    if (!_isOnGround) {
      _velocityY += GameConstants.gravity * dt;
      position.y += _velocityY * dt;

      if (position.y >= _groundY) {
        position.y = _groundY;
        _velocityY = 0;
        _isOnGround = true;
        if (!_isDucking) {
          _animState = PlayerAnimState.running;
        }
      }
    }

    // Invincibility
    if (_isInvincible) {
      _invincibilityTimer -= dt;
      _blinkTimer += dt;
      if (_blinkTimer >= GameConstants.blinkInterval) {
        _blinkTimer = 0;
        _visible = !_visible;
      }
      if (_invincibilityTimer <= 0) {
        _isInvincible = false;
        _visible = true;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_visible && _isInvincible) return;

    final alpha = _eliminated ? _eliminatedAlpha : 1.0;

    if (_sprite != null) {
      // Render the character image
      final opacityPaint = Paint()
        ..colorFilter = ColorFilter.mode(
          const Color(0xFFFFFFFF).withValues(alpha: alpha),
          BlendMode.modulate,
        );
      canvas.saveLayer(Rect.fromLTWH(0, 0, size.x, size.y), opacityPaint);
      _sprite!.render(canvas, size: size);
      canvas.restore();
    } else {
      // Fallback: colored rounded rectangle with eyes
      final paint = Paint()
        ..color = character.color.withValues(alpha: alpha);
      final bodyRect = Rect.fromLTWH(0, 0, size.x, size.y);
      canvas.drawRRect(
        RRect.fromRectAndRadius(bodyRect, const Radius.circular(8)),
        paint,
      );

      final eyePaint = Paint()..color = const Color(0xFFFFFFFF);
      final pupilPaint = Paint()..color = const Color(0xFF000000);
      final eyeY = size.y * 0.3;
      canvas.drawCircle(Offset(size.x * 0.35, eyeY), 6, eyePaint);
      canvas.drawCircle(Offset(size.x * 0.65, eyeY), 6, eyePaint);
      canvas.drawCircle(Offset(size.x * 0.38, eyeY), 3, pupilPaint);
      canvas.drawCircle(Offset(size.x * 0.68, eyeY), 3, pupilPaint);

      final legPaint = Paint()
        ..color = character.color.withValues(alpha: 0.8);
      if (_animState == PlayerAnimState.running) {
        canvas.drawRect(
            Rect.fromLTWH(size.x * 0.2, size.y - 4, 8, 4), legPaint);
        canvas.drawRect(
            Rect.fromLTWH(size.x * 0.6, size.y - 4, 8, 4), legPaint);
      } else if (_animState == PlayerAnimState.jumping) {
        canvas.drawRect(
            Rect.fromLTWH(size.x * 0.3, size.y - 2, 8, 2), legPaint);
        canvas.drawRect(
            Rect.fromLTWH(size.x * 0.5, size.y - 2, 8, 2), legPaint);
      }
    }

    // Name label above
    final textPainter = TextPainter(
      text: TextSpan(
        text: character.displayName,
        style: TextStyle(
          color: const Color(0xFFFFFFFF),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
        canvas, Offset((size.x - textPainter.width) / 2, -14));
  }
}
