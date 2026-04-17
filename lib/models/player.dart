import 'package:pup_dash/constants/characters.dart';
import 'package:pup_dash/constants/game_constants.dart';

enum PlayerState { alive, invincible, eliminated }

class PlayerData {
  final String id;
  String name;
  PupCharacter? character;
  double score;
  int lives;
  PlayerState state;
  bool isReady;
  DateTime? eliminatedAt;

  PlayerData({
    required this.id,
    this.name = '',
    this.character,
    this.score = 0,
    this.lives = GameConstants.maxLives,
    this.state = PlayerState.alive,
    this.isReady = false,
    this.eliminatedAt,
  });

  bool get isAlive => state != PlayerState.eliminated;

  void hit() {
    if (state == PlayerState.invincible) return;
    lives--;
    if (lives <= 0) {
      state = PlayerState.eliminated;
      eliminatedAt = DateTime.now();
    } else {
      state = PlayerState.invincible;
    }
  }

  void endInvincibility() {
    if (state == PlayerState.invincible) {
      state = PlayerState.alive;
    }
  }

  void reset() {
    score = 0;
    lives = GameConstants.maxLives;
    state = PlayerState.alive;
    isReady = false;
    eliminatedAt = null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'character': character?.name,
        'score': score,
        'lives': lives,
        'state': state.name,
        'isReady': isReady,
      };

  factory PlayerData.fromJson(Map<String, dynamic> json) => PlayerData(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        character: json['character'] != null
            ? PupCharacter.fromName(json['character'] as String)
            : null,
        score: (json['score'] as num?)?.toDouble() ?? 0,
        lives: json['lives'] as int? ?? GameConstants.maxLives,
        state: PlayerState.values.firstWhere(
          (s) => s.name == json['state'],
          orElse: () => PlayerState.alive,
        ),
        isReady: json['isReady'] as bool? ?? false,
      );
}
