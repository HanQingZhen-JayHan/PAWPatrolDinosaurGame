import 'dart:convert';

class GameMessage {
  final String type;
  final Map<String, dynamic> payload;
  final String? senderId;

  const GameMessage({
    required this.type,
    this.payload = const {},
    this.senderId,
  });

  String encode() => jsonEncode({
        'type': type,
        'payload': payload,
        if (senderId != null) 'senderId': senderId,
      });

  factory GameMessage.decode(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return GameMessage(
      type: map['type'] as String,
      payload: map['payload'] as Map<String, dynamic>? ?? {},
      senderId: map['senderId'] as String?,
    );
  }

  // Controller → Host messages
  factory GameMessage.join(String playerName) => GameMessage(
        type: MessageType.join,
        payload: {'playerName': playerName},
      );

  factory GameMessage.selectCharacter(String character) => GameMessage(
        type: MessageType.selectCharacter,
        payload: {'character': character},
      );

  factory GameMessage.ready() => const GameMessage(type: MessageType.ready);

  factory GameMessage.input(String action) => GameMessage(
        type: MessageType.input,
        payload: {'action': action},
      );

  factory GameMessage.requestStart() =>
      const GameMessage(type: MessageType.requestStart);

  factory GameMessage.requestEnd() =>
      const GameMessage(type: MessageType.requestEnd);

  factory GameMessage.leave() => const GameMessage(type: MessageType.leave);

  // Host → Controller messages
  factory GameMessage.joined(String playerId) => GameMessage(
        type: MessageType.joined,
        payload: {'playerId': playerId},
      );

  factory GameMessage.characterConfirmed(String character) => GameMessage(
        type: MessageType.characterConfirmed,
        payload: {'character': character},
      );

  factory GameMessage.gameStarting(int countdown) => GameMessage(
        type: MessageType.gameStarting,
        payload: {'countdown': countdown},
      );

  factory GameMessage.gameStarted() =>
      const GameMessage(type: MessageType.gameStarted);

  factory GameMessage.hit(int livesRemaining) => GameMessage(
        type: MessageType.hit,
        payload: {'livesRemaining': livesRemaining},
      );

  factory GameMessage.eliminated(double finalScore) => GameMessage(
        type: MessageType.eliminated,
        payload: {'finalScore': finalScore},
      );

  factory GameMessage.gameOver(
          List<Map<String, dynamic>> rankings) =>
      GameMessage(
        type: MessageType.gameOver,
        payload: {'rankings': rankings},
      );

  factory GameMessage.lobbyUpdate(
          List<Map<String, dynamic>> players, bool allReady) =>
      GameMessage(
        type: MessageType.lobbyUpdate,
        payload: {'players': players, 'allReady': allReady},
      );

  factory GameMessage.scoreUpdate(Map<String, double> scores) =>
      GameMessage(
        type: MessageType.scoreUpdate,
        payload: {'scores': scores},
      );

  @override
  String toString() => 'GameMessage($type, $payload)';
}

class MessageType {
  MessageType._();

  // Controller → Host
  static const String join = 'join';
  static const String selectCharacter = 'select_character';
  static const String ready = 'ready';
  static const String input = 'input';
  static const String requestStart = 'request_start';
  static const String requestEnd = 'request_end';
  static const String leave = 'leave';

  // Host → Controller
  static const String joined = 'joined';
  static const String characterConfirmed = 'character_confirmed';
  static const String gameStarting = 'game_starting';
  static const String gameStarted = 'game_started';
  static const String hit = 'hit';
  static const String eliminated = 'eliminated';
  static const String gameOver = 'game_over';

  // Host → All (broadcast)
  static const String lobbyUpdate = 'lobby_update';
  static const String scoreUpdate = 'score_update';
}

class InputAction {
  InputAction._();

  static const String jump = 'jump';
  static const String duckStart = 'duck_start';
  static const String duckEnd = 'duck_end';
}
