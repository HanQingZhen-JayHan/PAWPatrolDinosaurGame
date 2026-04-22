import 'dart:js_interop';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:pup_dash/constants/game_constants.dart';
import 'package:pup_dash/constants/theme.dart';
import 'package:pup_dash/game/pup_dash_game.dart';
import 'package:pup_dash/models/game_state.dart';
import 'package:pup_dash/models/player.dart';
import 'package:pup_dash/providers/game_provider.dart';
import 'package:pup_dash/widgets/character_icon.dart';

@JS('startBackgroundMusic')
external void _jsStartBackgroundMusic();

@JS('stopBackgroundMusic')
external void _jsStopBackgroundMusic();

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final PupDashGame _game;
  bool _musicPlaying = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<GameProvider>();
    _game = PupDashGame(gameProvider: provider);

    provider.onPhaseChanged = (phase) {
      // Stay on game screen — Play Again resets state without leaving room
      if (mounted) setState(() {});
      _syncMusicTo(phase);
    };

    // Starting phase might already be countdown/playing when screen mounts.
    _syncMusicTo(provider.state.phase);
  }

  void _syncMusicTo(GamePhase phase) {
    if (!kIsWeb) return;
    final shouldPlay =
        phase == GamePhase.countdown || phase == GamePhase.playing;
    if (shouldPlay && !_musicPlaying) {
      try {
        _jsStartBackgroundMusic();
        _musicPlaying = true;
      } catch (_) {}
    } else if (!shouldPlay && _musicPlaying) {
      try {
        _jsStopBackgroundMusic();
        _musicPlaying = false;
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    if (kIsWeb && _musicPlaying) {
      try {
        _jsStopBackgroundMusic();
      } catch (_) {}
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameWidget(game: _game),
          // Room QR code — top left corner for easy join/rejoin
          Consumer<GameProvider>(
            builder: (context, provider, _) {
              final roomCode = provider.roomCode;
              if (roomCode == null) return const SizedBox.shrink();
              return Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      QrImageView(
                        data: 'https://hanqingzhen-jayhan.github.io/PAWPatrolDinosaurGame/?room=$roomCode',
                        size: 160,
                      ),
                      Text(
                        roomCode,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: PupTheme.backgroundDark,
                          letterSpacing: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Lives + Score HUD (always visible during play)
          Consumer<GameProvider>(
            builder: (context, provider, _) {
              final state = provider.state;
              if (state.phase != GamePhase.playing) {
                return const SizedBox.shrink();
              }
              return _PlayerHud(players: state.playerList);
            },
          ),
          // Phase overlays (countdown, game over)
          Consumer<GameProvider>(
            builder: (context, provider, _) {
              final state = provider.state;

              if (state.phase == GamePhase.countdown) {
                return _CountdownOverlay(value: state.countdownValue);
              }

              if (state.phase == GamePhase.gameOver) {
                return _GameOverOverlay(
                  rankings: state.rankings,
                  onPlayAgain: provider.restartGame,
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}

class _CountdownOverlay extends StatelessWidget {
  final int value;
  const _CountdownOverlay({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Text(
          value > 0 ? '$value' : 'GO!',
          style: const TextStyle(
            color: PupTheme.goldStar,
            fontSize: 120,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  final List rankings;
  final VoidCallback onPlayAgain;

  const _GameOverOverlay({
    required this.rankings,
    required this.onPlayAgain,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events,
                  size: 80, color: PupTheme.goldStar),
              const SizedBox(height: 16),
              const Text(
                'GAME OVER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              // Podium: top 3
              if (rankings.isNotEmpty)
                _PodiumRow(rankings: rankings),
              const SizedBox(height: 24),
              // Full ranking list
              SizedBox(
                height: 150,
                child: ListView.builder(
                  itemCount: rankings.length,
                  itemBuilder: (context, index) {
                    final player = rankings[index];
                    final name = player.character?.displayName ??
                        player.name;
                    return ListTile(
                      dense: true,
                      leading: Text(
                        '#${index + 1}',
                        style: TextStyle(
                          color: index == 0
                              ? PupTheme.goldStar
                              : Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      title: Row(
                        children: [
                          CharacterIcon(
                              character: player.character, size: 24),
                          const SizedBox(width: 8),
                          Text(name,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 18)),
                        ],
                      ),
                      trailing: Text(
                        '${player.score.toInt()}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 16),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: onPlayAgain,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                    ),
                    child: const Text('PLAY AGAIN',
                        style: TextStyle(fontSize: 20)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PodiumRow extends StatelessWidget {
  final List rankings;
  const _PodiumRow({required this.rankings});

  @override
  Widget build(BuildContext context) {
    // Show top 3 in podium order: 2nd, 1st, 3rd
    final spots = <int>[
      if (rankings.length > 1) 1,
      0,
      if (rankings.length > 2) 2,
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: spots.map((i) {
        final player = rankings[i];
        final heights = [120.0, 80.0, 60.0];
        final colors = [PupTheme.goldStar, Colors.grey, Colors.brown];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CharacterIcon(character: player.character, size: 36),
              Text(
                player.character?.displayName ?? player.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                width: 80,
                height: heights[i],
                decoration: BoxDecoration(
                  color: colors[i],
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Center(
                  child: Text(
                    '#${i + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _PlayerHud extends StatelessWidget {
  final List<PlayerData> players;
  const _PlayerHud({required this.players});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      right: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: players.map((player) {
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: (player.character?.color ?? Colors.grey)
                  .withValues(alpha: player.isAlive ? 0.8 : 0.3),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CharacterIcon(character: player.character, size: 24),
                const SizedBox(width: 8),
                // Character name
                Text(
                  player.character?.displayName ??
                      (player.name.isEmpty ? 'Player' : player.name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                // Hearts
                ...List.generate(
                  GameConstants.maxLives,
                  (i) => Icon(
                    Icons.favorite,
                    color: i < player.lives
                        ? PupTheme.heartRed
                        : Colors.white24,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                // Score
                Text(
                  '${player.score.toInt()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!player.isAlive)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Text('OUT',
                        style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                const SizedBox(width: 8),
                // Host kick button
                InkWell(
                  onTap: () =>
                      context.read<GameProvider>().kickPlayer(player.id),
                  child: const Icon(Icons.close,
                      color: Colors.white54, size: 16),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
